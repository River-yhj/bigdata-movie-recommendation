-- Q1 MovieLens: Genre rating distribution using actual user ratings

-- 1. Load MovieLens ratings
ratings = LOAD '/user/maria_dev/ml-latest/ratings_sample.csv'
    USING PigStorage(',')
    AS (userId:int, movieId:int, rating:float, timestamp:long);

-- 2. Load MovieLens links (movieId -> tmdbId)
links = LOAD '/user/maria_dev/ml-latest/links.csv'
    USING PigStorage(',')
    AS (movieId:int, imdbId:chararray, tmdbId:int);

-- 3. Load TMDB processed data (genres, release_year)
tmdb = LOAD '/user/maria_dev/movies/processed/*.csv'
    USING PigStorage(',')
    AS (
        id:int,
        title:chararray,
        release_year:int,
        genres:chararray,
        vote_average:float,
        vote_count:int,
        popularity:float,
        original_language:chararray
    );

-- 4. Filter header rows and invalid data
ratings_clean = FILTER ratings BY userId != 0 AND rating > 0.0;
links_clean = FILTER links BY tmdbId != 0;
tmdb_clean = FILTER tmdb BY
    genres IS NOT NULL AND
    genres != '' AND
    genres != 'Unknown';

-- 5. Join ratings with links on movieId
ratings_links = JOIN ratings_clean BY movieId, links_clean BY movieId;

-- 6. Extract userId, rating, tmdbId
ratings_tmdb_id = FOREACH ratings_links GENERATE
    ratings_clean::userId AS userId,
    ratings_clean::rating AS rating,
    links_clean::tmdbId AS tmdbId;

-- 7. Join with TMDB data on tmdbId
joined = JOIN ratings_tmdb_id BY tmdbId, tmdb_clean BY id;

-- 8. Extract rating and genres
with_genres = FOREACH joined GENERATE
    ratings_tmdb_id::rating AS rating,
    tmdb_clean::genres AS genres;

-- 9. Filter invalid genres
with_genres_clean = FILTER with_genres BY
    genres IS NOT NULL AND
    genres != '' AND
    genres != 'Unknown';

-- 10. Flatten multiple genres
genres_split = FOREACH with_genres_clean GENERATE
    FLATTEN(TOKENIZE(genres, '|')) AS genre,
    rating;

-- 11. Group by genre
grouped = GROUP genres_split BY genre;

-- 12. Calculate stats per genre
result = FOREACH grouped GENERATE
    group AS genre,
    COUNT(genres_split) AS rating_count,
    ROUND_TO(AVG(genres_split.rating), 3) AS avg_rating,
    ROUND_TO(MAX(genres_split.rating), 3) AS max_rating,
    ROUND_TO(MIN(genres_split.rating), 3) AS min_rating;

-- 13. Sort by avg_rating descending
result_sorted = ORDER result BY avg_rating DESC;

-- 14. Save result
STORE result_sorted INTO '/user/maria_dev/movies/output/q1_movielens'
    USING PigStorage(',');


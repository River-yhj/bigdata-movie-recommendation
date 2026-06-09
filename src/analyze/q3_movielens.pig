-- Q3 MovieLens: Genre trend by period using actual user ratings

-- 1. Load MovieLens ratings
ratings = LOAD '$RATINGS_PATH'
    USING PigStorage(',')
    AS (userId:int, movieId:int, rating:float, timestamp:long);

-- 2. Load MovieLens links
links = LOAD '$LINKS_PATH'
    USING PigStorage(',')
    AS (movieId:int, imdbId:chararray, tmdbId:int);

-- 3. Load TMDB processed data
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

-- 4. Filter invalid data
ratings_clean = FILTER ratings BY userId != 0 AND rating > 0.0;
links_clean = FILTER links BY tmdbId != 0;
tmdb_clean = FILTER tmdb BY
    genres IS NOT NULL AND
    genres != '' AND
    genres != 'Unknown' AND
    release_year IS NOT NULL;

-- 5. Join ratings with links
ratings_links = JOIN ratings_clean BY movieId, links_clean BY movieId;

-- 6. Extract userId, rating, tmdbId
ratings_tmdb_id = FOREACH ratings_links GENERATE
    ratings_clean::rating AS rating,
    links_clean::tmdbId AS tmdbId;

-- 7. Join with TMDB data
joined = JOIN ratings_tmdb_id BY tmdbId, tmdb_clean BY id;

-- 8. Extract genres and release_year
with_genres = FOREACH joined GENERATE
    tmdb_clean::genres AS genres,
    tmdb_clean::release_year AS release_year;

-- 9. Flatten genres and classify period
genres_split = FOREACH with_genres GENERATE
    FLATTEN(TOKENIZE(genres, '|')) AS genre,
    (release_year < 2000 ? 'Early(1980-1999)' :
        (release_year < 2015 ? 'Mid(2000-2014)' : 'Recent(2015-2024)')) AS period;

-- 10. Group by period and genre
grouped = GROUP genres_split BY (period, genre);

-- 11. Count ratings per period and genre
result = FOREACH grouped GENERATE
    FLATTEN(group) AS (period, genre),
    COUNT(genres_split) AS rating_count;

-- 12. Sort by period and rating count
result_sorted = ORDER result BY period ASC, rating_count DESC;

-- 13. Save result
STORE result_sorted INTO '/user/maria_dev/movies/output/q3_movielens'
    USING PigStorage(',');


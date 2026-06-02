-- Q1 v2: Genre rating distribution + vote count analysis

-- 1. Load data
movies = LOAD '/user/maria_dev/movies/processed/*.csv'
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

-- 2. Filter invalid data
movies_clean = FILTER movies BY
    vote_average IS NOT NULL AND
    vote_average > 0.0 AND
    vote_count >= 10 AND
    genres IS NOT NULL AND
    genres != '' AND
    genres != 'Unknown';

-- 3. Split multiple genres
genres_split = FOREACH movies_clean GENERATE
    FLATTEN(TOKENIZE(genres, '|')) AS genre,
    vote_average,
    vote_count;

-- 4. Group by genre
grouped = GROUP genres_split BY genre;

-- 5. Calculate stats per genre
result = FOREACH grouped GENERATE
    group AS genre,
    COUNT(genres_split) AS movie_count,
    ROUND_TO(AVG(genres_split.vote_average), 3) AS avg_rating,
    ROUND_TO(MAX(genres_split.vote_average), 3) AS max_rating,
    ROUND_TO(MIN(genres_split.vote_average), 3) AS min_rating,
    (long)SUM(genres_split.vote_count) AS total_votes,
    ROUND_TO(AVG(genres_split.vote_count), 0) AS avg_votes_per_movie;

-- 6. Sort by avg_rating descending
result_sorted = ORDER result BY avg_rating DESC;

-- 7. Save result
STORE result_sorted INTO '/user/maria_dev/movies/output/q1_genre_rating_v2'
    USING PigStorage(',');

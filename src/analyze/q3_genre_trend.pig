-- Q3: Genre trend by decade analysis

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
    release_year IS NOT NULL AND
    genres IS NOT NULL AND
    genres != '' AND
    genres != 'Unknown' AND
    vote_count >= 10;

-- 3. Split multiple genres and add year group
genres_split = FOREACH movies_clean GENERATE
    FLATTEN(TOKENIZE(genres, '|')) AS genre,
    release_year,
    (release_year < 2018 ? 'Early(2015-2017)' : 'Recent(2018-2024)') AS period;

-- 4. Group by period and genre
grouped = GROUP genres_split BY (period, genre);

-- 5. Count movies per period and genre
result = FOREACH grouped GENERATE
    FLATTEN(group) AS (period, genre),
    COUNT(genres_split) AS movie_count;

-- 6. Sort by period and movie count
result_sorted = ORDER result BY period ASC, movie_count DESC;

-- 7. Save result
STORE result_sorted INTO '/user/maria_dev/movies/output/q3_genre_trend'
    USING PigStorage(',');

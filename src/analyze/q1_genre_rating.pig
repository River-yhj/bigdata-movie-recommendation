-- Q1: 장르별 평점 분포 분석

-- 1. 데이터 로드
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

-- 2. 결측값 및 이상값 제거
movies_clean = FILTER movies BY
    vote_average IS NOT NULL AND
    vote_average > 0.0 AND
    vote_count >= 10 AND
    genres IS NOT NULL AND
    genres != '' AND
    genres != 'Unknown';

-- 3. 장르가 여러 개인 경우 분리 (Comedy|Drama -> Comedy, Drama)
genres_split = FOREACH movies_clean GENERATE
    FLATTEN(TOKENIZE(genres, '|')) AS genre,
    vote_average;

-- 4. 장르별 그룹화
grouped = GROUP genres_split BY genre;

-- 5. 장르별 평균 평점, 최고/최저 평점, 영화 수 계산
result = FOREACH grouped GENERATE
    group AS genre,
    COUNT(genres_split) AS movie_count,
    ROUND_TO(AVG(genres_split.vote_average), 3) AS avg_rating,
    ROUND_TO(MAX(genres_split.vote_average), 3) AS max_rating,
    ROUND_TO(MIN(genres_split.vote_average), 3) AS min_rating;

-- 6. 평균 평점 기준 내림차순 정렬
result_sorted = ORDER result BY avg_rating DESC;

-- 7. 결과 저장
STORE result_sorted INTO '/user/maria_dev/movies/output/q1_genre_rating'
    USING PigStorage(',');

-- Q2: 예산/수익과 평점의 상관관계 분석

-- 1. 데이터 로드
movies = LOAD '/user/maria_dev/movies/joined/*.csv'
    USING PigStorage(',')
    AS (
        id:int,
        title:chararray,
        release_year:int,
        genres:chararray,
        vote_average:float,
        vote_count:int,
        popularity:float,
        original_language:chararray,
        budget:long,
        revenue:long
    );

-- 2. 결측값 및 이상값 제거 (budget/revenue 0인 데이터 제외)
movies_clean = FILTER movies BY
    vote_average IS NOT NULL AND
    vote_average > 0.0 AND
    vote_count >= 10 AND
    budget > 0 AND
    revenue > 0;

-- 3. 예산 구간별 분류
budget_group = FOREACH movies_clean GENERATE
    vote_average,
    budget,
    revenue,
    (long)(revenue - budget) AS profit,
    (budget < 10000000L ? 'Low' :
        (budget < 50000000L ? 'Mid' :
            (budget < 150000000L ? 'High' : 'Blockbuster'))) AS budget_tier;

-- 4. 예산 구간별 그룹화
grouped = GROUP budget_group BY budget_tier;

-- 5. 예산 구간별 평균 평점, 평균 수익, 영화 수 계산
result = FOREACH grouped GENERATE
    group AS budget_tier,
    COUNT(budget_group) AS movie_count,
    ROUND_TO(AVG(budget_group.vote_average), 3) AS avg_rating,
    ROUND_TO(AVG(budget_group.budget), 0) AS avg_budget,
    ROUND_TO(AVG(budget_group.revenue), 0) AS avg_revenue,
    ROUND_TO(AVG(budget_group.profit), 0) AS avg_profit;

-- 6. 평균 평점 기준 내림차순 정렬
result_sorted = ORDER result BY avg_rating DESC;

-- 7. 결과 저장
STORE result_sorted INTO '/user/maria_dev/movies/output/q2_budget_rating'
    USING PigStorage(',');

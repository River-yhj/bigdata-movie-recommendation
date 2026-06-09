#!/bin/bash
# =============================================
# Movie Analysis Pipeline - Sample Quick Run
# 샘플 데이터로 전체 파이프라인 재현
# =============================================
# 사전 요건:
#   - HDP Sandbox 실행 중 (HDFS, Pig 접근 가능)
#   - data/sample/ 에 샘플 CSV 존재
#   - data/sample/ml-latest-small/ 에 MovieLens 샘플 존재
#   - Python 3.x, pyspark 설치
#   - TMDB_API_KEY 환경변수 설정 (수집 단계 생략 시 불필요)
# =============================================

set -e
echo "================================================"
echo " Movie Analysis Pipeline - Sample Quick Run"
echo "================================================"

# ── Step 1: HDFS 디렉토리 생성 및 샘플 데이터 업로드 ──
echo ""
echo "[Step 1] Uploading sample data to HDFS..."

hdfs dfs -mkdir -p /user/maria_dev/movies/processed
hdfs dfs -mkdir -p /user/maria_dev/movies/joined
hdfs dfs -mkdir -p /user/maria_dev/ml-latest-small

# TMDB 샘플 데이터 업로드 (processed, joined 겸용)
for f in data/sample/movies_*.csv; do
    hdfs dfs -put -f "$f" /user/maria_dev/movies/processed/
    hdfs dfs -put -f "$f" /user/maria_dev/movies/joined/
done

# MovieLens 샘플 업로드
hdfs dfs -put -f data/sample/ml-latest-small/ratings.csv /user/maria_dev/ml-latest-small/
hdfs dfs -put -f data/sample/ml-latest-small/links.csv   /user/maria_dev/ml-latest-small/
hdfs dfs -put -f data/sample/ml-latest-small/movies.csv  /user/maria_dev/ml-latest-small/

echo "[Step 1] Done!"

# ── Step 2: Pig 분석 (Q1 TMDB / Q2 / Q3 TMDB) ────────────────────────────────
echo ""
echo "[Step 2] Running Pig analysis..."

# 기존 output 삭제 (재실행 대비)
hdfs dfs -rm -r -f /user/maria_dev/movies/output/q1_genre_rating_v2
hdfs dfs -rm -r -f /user/maria_dev/movies/output/q2_budget_rating
hdfs dfs -rm -r -f /user/maria_dev/movies/output/q3_genre_trend

echo "  [Q1] Genre rating distribution (TMDB)..."
pig -Dtez.am.resource.memory.mb=2048 \
    -Dtez.task.resource.memory.mb=2048 \
    -f src/analyze/q1_genre_rating_v2.pig
echo "  [Q1] Done!"

echo "  [Q2] Budget vs rating correlation..."
pig -Dtez.am.resource.memory.mb=2048 \
    -Dtez.task.resource.memory.mb=2048 \
    -f src/analyze/q2_budget_rating.pig
echo "  [Q2] Done!"

echo "  [Q3] Genre trend by period (TMDB)..."
pig -Dtez.am.resource.memory.mb=2048 \
    -Dtez.task.resource.memory.mb=2048 \
    -f src/analyze/q3_genre_trend.pig
echo "  [Q3] Done!"

echo "[Step 2] Done!"

# ── Step 3: MovieLens Pig 분석 (Q1 / Q3) ─────────────────────────────────────
echo ""
echo "[Step 3] Running MovieLens Pig analysis..."

# Pig 스크립트의 경로를 ml-latest-small로 임시 수정하여 실행
hdfs dfs -rm -r -f /user/maria_dev/movies/output/q1_movielens
hdfs dfs -rm -r -f /user/maria_dev/movies/output/q3_movielens

# ratings_sample 경로로 실행 (ml-latest-small/ratings.csv 사용)
pig -Dtez.am.resource.memory.mb=2048 \
    -Dtez.task.resource.memory.mb=2048 \
    -param RATINGS_PATH=/user/maria_dev/ml-latest-small/ratings.csv \
    -param LINKS_PATH=/user/maria_dev/ml-latest-small/links.csv \
    -f src/analyze/q1_movielens.pig
echo "  [Q1 MovieLens] Done!"

pig -Dtez.am.resource.memory.mb=2048 \
    -Dtez.task.resource.memory.mb=2048 \
    -param RATINGS_PATH=/user/maria_dev/ml-latest-small/ratings.csv \
    -param LINKS_PATH=/user/maria_dev/ml-latest-small/links.csv \
    -f src/analyze/q3_movielens.pig
echo "  [Q3 MovieLens] Done!"

echo "[Step 3] Done!"

# ── Step 4: 결과 확인 ──────────────────────────────────────────────────────────
echo ""
echo "[Step 4] Checking results..."
echo ""
echo "--- Q1 TMDB Result ---"
hdfs dfs -cat /user/maria_dev/movies/output/q1_genre_rating_v2/part-v004-o000-r-00000 2>/dev/null || \
hdfs dfs -cat /user/maria_dev/movies/output/q1_genre_rating_v2/part-v008-o000-r-00000 2>/dev/null

echo ""
echo "--- Q2 Result ---"
hdfs dfs -cat /user/maria_dev/movies/output/q2_budget_rating/part-v004-o000-r-00000 2>/dev/null || \
hdfs dfs -cat /user/maria_dev/movies/output/q2_budget_rating/part-v008-o000-r-00000 2>/dev/null

echo ""
echo "--- Q3 Result ---"
hdfs dfs -cat /user/maria_dev/movies/output/q3_genre_trend/part-v004-o000-r-00000 2>/dev/null || \
hdfs dfs -cat /user/maria_dev/movies/output/q3_genre_trend/part-v008-o000-r-00000 2>/dev/null

echo ""
echo "================================================"
echo " Sample pipeline completed successfully!"
echo " Zeppelin에서 결과 확인: localhost:9995"
echo "================================================"


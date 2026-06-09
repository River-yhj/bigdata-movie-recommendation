#!/bin/bash

# =============================================
# Movie Analysis Pipeline - Full Automation
# =============================================

source .env
set -e  # Stop on error

echo "================================================"
echo "Starting Movie Analysis Pipeline..."
echo "================================================"

# Step 1 - Data collection
echo ""
echo "[Step 1] Fetching TMDB data..."
python3.6 src/ingest/fetch_tmdb.py
echo "[Step 1] Done!"

# Step 2 - Genre conversion
echo ""
echo "[Step 2] Converting genre IDs to names..."
python3.6 src/ingest/convert_genres.py
echo "[Step 2] Done!"

# Step 3 - Budget fetch
echo ""
echo "[Step 3] Fetching budget/revenue data..."
python3.6 src/ingest/fetch_budget.py
echo "[Step 3] Done!"

# Step 4 - Join budget data
echo ""
echo "[Step 4] Joining budget data..."
python3.6 src/ingest/join_budget.py
echo "[Step 4] Done!"
# Step 5 - Upload to HDFS
echo ""
echo "[Step 5] Uploading to HDFS..."
hdfs dfs -mkdir -p /user/maria_dev/movies/processed
hdfs dfs -mkdir -p /user/maria_dev/movies/joined

for f in data/processed/*.csv; do
    hdfs dfs -put -f "$f" /user/maria_dev/movies/processed/
done

for f in data/joined/*.csv; do
    hdfs dfs -put -f "$f" /user/maria_dev/movies/joined/
done
echo "[Step 5] Done!"

# Step 6 - Pig analysis
echo ""
echo "[Step 6] Running Pig analysis..."

echo "  Running Q1..."
pig -f src/analyze/q1_genre_rating.pig
echo "  Q1 Done!"

echo "  Running Q2..."
pig -f src/analyze/q2_budget_rating.pig
echo "  Q2 Done!"

echo "  Running Q3..."
pig -f src/analyze/q3_genre_trend.pig
echo "  Q3 Done!"

echo ""
echo "================================================"
echo "Pipeline completed successfully!"
echo "================================================"

import os
import glob
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, explode, split, avg, count, max, min, round, when, desc

# ── Spark Session ─────────────────────────────────────────────────────────────
spark = SparkSession.builder \
    .appName("MovieLens Analysis") \
    .config("spark.driver.memory", "8g") \
    .config("spark.sql.shuffle.partitions", "8") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")

# ── 경로 설정 ─────────────────────────────────────────────────────────────────
ML_DIR   = r"C:\Users\river\Projects\bigdata\ml-latest"
TMDB_DIR = r"C:\Users\river\Projects\bigdata\bigdata-movie-recommendation\data\processed"
OUT_DIR  = r"C:\Users\river\Projects\bigdata\bigdata-movie-recommendation\data\spark_output"

os.makedirs(OUT_DIR, exist_ok=True)

# ── 데이터 로드 ───────────────────────────────────────────────────────────────
print("Loading data...")

ratings = spark.read.option("header", "true").option("inferSchema", "true") \
    .csv(os.path.join(ML_DIR, "ratings.csv"))

links = spark.read.option("header", "true").option("inferSchema", "true") \
    .csv(os.path.join(ML_DIR, "links.csv"))

tmdb_files = glob.glob(os.path.join(TMDB_DIR, "movies_*.csv"))
print(f"Found {len(tmdb_files)} TMDB files")

tmdb = spark.read.option("header", "true").option("inferSchema", "true") \
    .csv(tmdb_files) \
    .toDF("id", "title", "release_year", "genres",
          "vote_average", "vote_count", "popularity", "original_language")

# ── JOIN ──────────────────────────────────────────────────────────────────────
print("Joining datasets...")

joined = ratings \
    .join(links, "movieId") \
    .join(tmdb, links["tmdbId"] == tmdb["id"]) \
    .select("rating", "genres", "release_year") \
    .filter(col("genres").isNotNull() & (col("genres") != "") & (col("genres") != "Unknown"))

joined.cache()
total = joined.count()
print(f"Total records after join: {total:,}")

# ── Q1: 장르별 실제 사용자 평점 ───────────────────────────────────────────────
print("Running Q1...")

q1 = joined \
    .withColumn("genre", explode(split(col("genres"), r"\|"))) \
    .filter((col("genre") != "Unknown") & (col("genre") != "")) \
    .groupBy("genre") \
    .agg(
        count("rating").alias("rating_count"),
        round(avg("rating"), 3).alias("avg_rating"),
        round(max("rating"), 3).alias("max_rating"),
        round(min("rating"), 3).alias("min_rating")
    ) \
    .orderBy(desc("avg_rating"))

q1.show()

# pandas로 저장
q1.toPandas().to_csv(os.path.join(OUT_DIR, "q1_movielens.csv"), index=False)
print("Q1 saved!")

# ── Q3: 시대별 장르 트렌드 ────────────────────────────────────────────────────
print("Running Q3...")

q3 = joined \
    .withColumn("genre", explode(split(col("genres"), r"\|"))) \
    .filter((col("genre") != "Unknown") & (col("genre") != "")) \
    .withColumn("period",
        when(col("release_year") < 2000, "Early(1980-1999)")
        .when(col("release_year") < 2015, "Mid(2000-2014)")
        .otherwise("Recent(2015-2024)")
    ) \
    .groupBy("period", "genre") \
    .agg(count("rating").alias("rating_count")) \
    .orderBy(col("period"), desc("rating_count"))

q3.show(60)

# pandas로 저장
q3.toPandas().to_csv(os.path.join(OUT_DIR, "q3_movielens.csv"), index=False)
print("Q3 saved!")

spark.stop()
print("Done!")

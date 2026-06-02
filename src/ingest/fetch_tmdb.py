import requests
import csv
import os
import time
import subprocess

API_KEY = os.environ.get("TMDB_API_KEY", "your_api_key_here")
BASE_URL = "https://api.themoviedb.org/3"
OUTPUT_DIR = "/home/maria_dev/bigdata-movie-recommendation/data/raw"
HDFS_DIR = "/user/maria_dev/movies"
START_YEAR = 2015
END_YEAR = 2024

def fetch_movies_by_year(year, max_pages=20):
    movies = []
    for page in range(1, max_pages + 1):
        url = f"{BASE_URL}/discover/movie"
        params = {
            "api_key": API_KEY,
            "language": "en-US",
            "sort_by": "popularity.desc",
            "primary_release_year": year,
            "page": page,
            "vote_count.gte": 10
        }
        response = requests.get(url, params=params)
        if response.status_code != 200:
            print(f"  [{year}] Page {page} error: {response.status_code}")
            break
        data = response.json()
        results = data.get("results", [])
        if not results:
            break
        for movie in results:
            movies.append({
                "id": movie.get("id"),
                "title": movie.get("title", "").replace(",", " "),
                "release_year": year,
                "genres": "|".join([str(g) for g in movie.get("genre_ids", [])]),
                "vote_average": movie.get("vote_average"),
                "vote_count": movie.get("vote_count"),
                "popularity": movie.get("popularity"),
                "original_language": movie.get("original_language")
            })
        print(f"  [{year}] Page {page}/{data.get('total_pages')} done ({len(results)} movies)")
        time.sleep(0.3)
    return movies

def save_to_csv(movies, year):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    filepath = f"{OUTPUT_DIR}/movies_{year}.csv"
    fieldnames = ["id", "title", "release_year", "genres", "vote_average", "vote_count", "popularity", "original_language"]
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(movies)
    print(f"  [{year}] Saved: {filepath} ({len(movies)} movies)")
    return filepath

def upload_to_hdfs(filepath, year):
    hdfs_path = f"{HDFS_DIR}/year={year}"
    subprocess.run(["hdfs", "dfs", "-mkdir", "-p", hdfs_path], check=True)
    subprocess.run(["hdfs", "dfs", "-put", "-f", filepath, hdfs_path], check=True)
    print(f"  [{year}] Uploaded to HDFS: {hdfs_path}")

def main():
    print("Starting TMDB data collection...")
    subprocess.run(["hdfs", "dfs", "-mkdir", "-p", HDFS_DIR])

    total_movies = 0
    for year in range(START_YEAR, END_YEAR + 1):
        print(f"\nFetching {year}...")
        movies = fetch_movies_by_year(year)
        if movies:
            filepath = save_to_csv(movies, year)
            upload_to_hdfs(filepath, year)
            total_movies += len(movies)

    print(f"\nDone! Total {total_movies} movies collected.")

if __name__ == "__main__":
    main()

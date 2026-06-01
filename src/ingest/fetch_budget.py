import requests
import csv
import os
import time
import glob

API_KEY = os.environ.get("TMDB_API_KEY", "your_api_key_here")
BASE_URL = "https://api.themoviedb.org/3"
PROCESSED_DIR = "/home/maria_dev/bigdata-movie-recommendation/data/processed"
OUTPUT_DIR = "/home/maria_dev/bigdata-movie-recommendation/data/budget"

def fetch_movie_detail(movie_id):
    url = f"{BASE_URL}/movie/{movie_id}"
    params = {"api_key": API_KEY}
    response = requests.get(url, params=params)
    if response.status_code != 200:
        return None
    data = response.json()
    return {
        "id": movie_id,
        "budget": data.get("budget", 0),
        "revenue": data.get("revenue", 0)
    }

def get_all_ids():
    ids = []
    files = sorted(glob.glob(f"{PROCESSED_DIR}/movies_*.csv"))
    for filepath in files:
        with open(filepath, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                ids.append(row["id"])
    return ids

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_path = f"{OUTPUT_DIR}/budget.csv"

    movie_ids = get_all_ids()
    print(f"Total movies: {len(movie_ids)}")

    fieldnames = ["id", "budget", "revenue"]
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

        for i, movie_id in enumerate(movie_ids):
            detail = fetch_movie_detail(movie_id)
            if detail:
                writer.writerow(detail)
            if (i + 1) % 100 == 0:
                print(f"Progress: {i+1}/{len(movie_ids)}")
            time.sleep(0.25)

    print(f"Done! Saved to {output_path}")

if __name__ == "__main__":
    main()


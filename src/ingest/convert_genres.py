import csv
import os

GENRE_MAP = {
    "28": "Action",
    "12": "Adventure",
    "16": "Animation",
    "35": "Comedy",
    "80": "Crime",
    "99": "Documentary",
    "18": "Drama",
    "14": "Fantasy",
    "36": "History",
    "27": "Horror",
    "10402": "Music",
    "9648": "Mystery",
    "10749": "Romance",
    "878": "Science Fiction",
    "10770": "TV Movie",
    "53": "Thriller",
    "10752": "War",
    "37": "Western",
    "10751": "Family"
}

RAW_DIR = "/home/maria_dev/bigdata-movie-recommendation/data/raw"
OUT_DIR = "/home/maria_dev/bigdata-movie-recommendation/data/processed"

def convert_genres(genre_ids_str):
    if not genre_ids_str:
        return "Unknown"
    ids = genre_ids_str.split("|")
    names = [GENRE_MAP.get(gid.strip(), "Unknown") for gid in ids]
    return "|".join(names)

def process_file(filepath, out_filepath):
    rows = []
    with open(filepath, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            row["genres"] = convert_genres(row["genres"])
            rows.append(row)

    os.makedirs(OUT_DIR, exist_ok=True)
    fieldnames = ["id", "title", "release_year", "genres", "vote_average", "vote_count", "popularity", "original_language"]
    with open(out_filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"Converted: {out_filepath} ({len(rows)} movies)")

def main():
    files = [f for f in os.listdir(RAW_DIR) if f.endswith(".csv")]
    files.sort()
    print(f"Found {len(files)} files to convert...")
    for filename in files:
        raw_path = os.path.join(RAW_DIR, filename)
        out_path = os.path.join(OUT_DIR, filename)
        process_file(raw_path, out_path)
    print(f"\nDone! Converted files saved to {OUT_DIR}")

if __name__ == "__main__":
    main()

import csv
import os
import glob

PROCESSED_DIR = "/home/maria_dev/bigdata-movie-recommendation/data/processed"
BUDGET_FILE = "/home/maria_dev/bigdata-movie-recommendation/data/budget/budget.csv"
OUTPUT_DIR = "/home/maria_dev/bigdata-movie-recommendation/data/joined"

def load_budget():
    budget_map = {}
    with open(BUDGET_FILE, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            budget_map[row["id"]] = {
                "budget": row["budget"],
                "revenue": row["revenue"]
            }
    print(f"Loaded {len(budget_map)} budget records")
    return budget_map

def join_files(budget_map):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    files = sorted(glob.glob(f"{PROCESSED_DIR}/movies_*.csv"))
    fieldnames = ["id", "title", "release_year", "genres", "vote_average", "vote_count", "popularity", "original_language", "budget", "revenue"]

    for filepath in files:
        filename = os.path.basename(filepath)
        output_path = f"{OUTPUT_DIR}/{filename}"
        rows = []

        with open(filepath, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                budget_info = budget_map.get(row["id"], {"budget": "0", "revenue": "0"})
                row["budget"] = budget_info["budget"]
                row["revenue"] = budget_info["revenue"]
                rows.append(row)

        with open(output_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)

        print(f"Joined: {output_path} ({len(rows)} movies)")

def main():
    print("Starting join...")
    budget_map = load_budget()
    join_files(budget_map)
    print(f"\nDone! Joined files saved to {OUTPUT_DIR}")

if __name__ == "__main__":
    main()

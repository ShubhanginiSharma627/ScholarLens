import pandas as pd
import json
import os
INPUT_FILE = "data/ScienceQA_with_context2.csv"
OUTPUT_FILE = "data/cleaned_exam.json"
def clean_data():
    print("Starting data cleaning...")
    if not os.path.exists(INPUT_FILE):
        print(f"Error: File {INPUT_FILE} not found!")
        return
    df = pd.read_csv(INPUT_FILE)
    def format_choices(row):
        choices = {}
        for opt in ['A', 'B', 'C', 'D', 'E']:
            if opt in row and pd.notna(row[opt]):
                choices[opt] = row[opt]
        return choices
    df['choices'] = df.apply(format_choices, axis=1)
    wanted_cols = ['id', 'prompt', 'lecture', 'solution', 'subject', 'topic', 'choices', 'answer', 'image']
    existing_cols = [c for c in wanted_cols if c in df.columns]
    df_clean = df[existing_cols]
    df_clean = df_clean.dropna(subset=['prompt', 'lecture'])
    df_clean.to_json(OUTPUT_FILE, orient="records", indent=4)
    print(f"Success! Saved {len(df_clean)} questions to {OUTPUT_FILE}")
if __name__ == "__main__":
    clean_data()
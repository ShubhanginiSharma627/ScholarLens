import pandas as pd
import json
import random

DATA_FILE = "data/cleaned_exam.json"

try:
    df = pd.read_json(DATA_FILE)
    print(f"Quiz Engine Loaded: {len(df)} questions available.")
except Exception as e:
    print(f"Error loading quiz data: {e}")
    df = pd.DataFrame() 

def generate_quiz(topic: str, difficulty: str = "Medium", num_questions: int = 5):
    """
    Returns 5 random questions for a specific topic.
    """
    if df.empty:
        return []

    topic_df = df[df['topic'].str.contains(topic, case=False, na=False)]
    
    if topic_df.empty:
        print(f"⚠️ No questions found for '{topic}'. Returning random mix.")
        topic_df = df
        
    sample_size = min(num_questions, len(topic_df))
    quiz_df = topic_df.sample(n=sample_size)
    
    return quiz_df.to_dict(orient="records")

def analyze_performance(results: list):
    """
    Input: A list of booleans or result dicts.
    Example Input: 
    [
        {"topic": "Biology", "is_correct": True}, 
        {"topic": "Biology", "is_correct": False},
        {"topic": "Physics", "is_correct": False}
    ]
    """
    if not results:
        return "No data to analyze."

    score_map = {}
    
    for res in results:
        topic = res.get('topic', 'General')
        correct = 1 if res.get('is_correct') else 0
        
        if topic not in score_map:
            score_map[topic] = []
        score_map[topic].append(correct)

    feedback_lines = []
    
    for topic, scores in score_map.items():
        avg = sum(scores) / len(scores)
        if avg < 0.5: 
            feedback_lines.append(f"Weakness detected in {topic}. Review the lecture notes.")
        elif avg == 1.0:
            feedback_lines.append(f"Perfect score in {topic}! Moving to advanced mode.")
        else:
            feedback_lines.append(f"Good progress in {topic}. Keep practicing.")

    return " ".join(feedback_lines)
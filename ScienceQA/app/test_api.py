import requests
import json
import time


BASE_URL = "http://127.0.0.1:8000"

GREEN = "\033[92m"
RED = "\033[91m"
RESET = "\033[0m"
BOLD = "\033[1m"

def print_pass(message):
    print(f"{GREEN} PASS:{RESET} {message}")

def print_fail(message, error=""):
    print(f"{RED} FAIL:{RESET} {message}")
    if error:
        print(f"   Error: {error}")

def test_root():
    """Test if the server is running at all"""
    print(f"\n{BOLD}--- Test 1: Health Check ---{RESET}")
    try:
        response = requests.get(f"{BASE_URL}/")
        if response.status_code == 200:
            print_pass("Server is online and healthy.")
            return True
        else:
            print_fail(f"Server returned status {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print_fail("Could not connect. Is the server running?", "Run 'uvicorn app.main:app --reload' in a separate terminal.")
        return False

def test_rag_search():
    """Test the Context Retrieval (The 'Brain')"""
    print(f"\n{BOLD}--- Test 2: RAG Search Engine ---{RESET}")
    endpoint = f"{BASE_URL}/retrieve"
    payload = {"question_text": "What is the function of the mitochondria?"}
    
    try:
        start = time.time()
        response = requests.post(endpoint, json=payload)
        duration = time.time() - start
        
        if response.status_code == 200:
            data = response.json()
            if data.get("answer_context"):
                print_pass(f"Got answer in {duration:.2f}s")
                print(f"   Topic Found: {data.get('source_topic')}")
                print(f"   Context Snippet: {data.get('answer_context')[:100]}...")
            else:
                print_fail("Response missing 'answer_context'. DB might be empty.")
        else:
            print_fail(f"Status {response.status_code}", response.text)
            
    except Exception as e:
        print_fail("Request failed", str(e))

def test_quiz_generator():
    """Test the Mock Exam Generator"""
    print(f"\n{BOLD}--- Test 3: Quiz Generator ---{RESET}")
    endpoint = f"{BASE_URL}/quiz/generate"
    payload = {"topic": "science", "difficulty": "Medium"}
    
    try:
        response = requests.post(endpoint, json=payload)
        if response.status_code == 200:
            data = response.json()
            quiz = data.get("quiz", [])
            if len(quiz) > 0:
                print_pass(f"Generated {len(quiz)} questions for 'science'.")
                print(f"   Sample Question: {quiz[0].get('prompt')}")
            else:
                print_fail("Returned empty quiz list.")
        else:
            print_fail(f"Status {response.status_code}", response.text)
    except Exception as e:
        print_fail("Request failed", str(e))

def test_analytics():
    """Test the Feedback Logic"""
    print(f"\n{BOLD}--- Test 4: Analytics Engine ---{RESET}")
    endpoint = f"{BASE_URL}/quiz/analyze"
    
    payload = {
        "results": [
            {"question_id": "1", "topic": "Biology", "is_correct": False},
            {"question_id": "2", "topic": "Biology", "is_correct": False},
            {"question_id": "3", "topic": "Physics", "is_correct": True},
            {"question_id": "4", "topic": "Physics", "is_correct": True}
        ]
    }
    
    try:
        response = requests.post(endpoint, json=payload)
        if response.status_code == 200:
            data = response.json()
            feedback = data.get("feedback", "")
            if "Weakness" in feedback:
                print_pass("Analytics correctly identified weakness.")
                print(f"   Feedback: {feedback}")
            else:
                print_fail("Feedback logic seems off.", f"Got: {feedback}")
        else:
            print_fail(f"Status {response.status_code}", response.text)
    except Exception as e:
        print_fail("Request failed", str(e))

if __name__ == "__main__":
    print(f"{BOLD} Starting System Diagnostics...{RESET}")
    
    if test_root():
        test_rag_search()
        test_quiz_generator()
        test_analytics()
        
    print(f"\n{BOLD} Tests Completed.{RESET}")
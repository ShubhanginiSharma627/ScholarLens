from fastapi import FastAPI, HTTPException
from app.models import QueryRequest, ContextResponse, QuizRequest, AnalysisRequest
from app.rag_engine import search_knowledge
from app.quiz_engine import generate_quiz, analyze_performance
app = FastAPI()
@app.get("/")
def home():
    return {"status": "Online", "message": "AI Tutor Backend is running"}
@app.post("/retrieve", response_model=ContextResponse)
def retrieve_context(request: QueryRequest):
    print(f"Received query: {request.question_text}")
    try:
        context, topic = search_knowledge(request.question_text)
        return ContextResponse(
            answer_context=context,
            source_topic=topic,
            confidence_score=0.95
        )
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
@app.post("/quiz/generate")
def get_quiz(request: QuizRequest):
    questions = generate_quiz(request.topic, request.difficulty)
    return {"quiz": questions}
@app.post("/quiz/analyze")
def submit_results(request: AnalysisRequest):
    results_data = [item.dict() for item in request.results]
    feedback = analyze_performance(results_data)
    return {"feedback": feedback}

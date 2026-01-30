from pydantic import BaseModel
from typing import List, Optional
class QueryRequest(BaseModel):
    question_text: str
    subject: Optional[str] = None 
class ContextResponse(BaseModel):
    answer_context: str 
    source_topic: str
    confidence_score: float 
class QuizRequest(BaseModel):
    topic: str
    difficulty: Optional[str] = "Medium"
class ResultItem(BaseModel):
    question_id: str
    topic: str
    is_correct: bool
class AnalysisRequest(BaseModel):
    results: List[ResultItem]
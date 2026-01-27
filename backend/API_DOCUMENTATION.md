# ScholarLens Backend API Documentation

## Overview
Enhanced backend with Vertex AI (Gemini & Gemma), authentication, and AI-powered learning features.

---

## Authentication Endpoints

### Register User
```
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password",
  "name": "John Doe"
}

Response (201):
{
  "success": true,
  "data": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "John Doe",
    "token": "jwt_token",
    "profile": { ... },
    "stats": { ... }
  }
}
```

### Login
```
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password"
}

Response (200):
{
  "success": true,
  "data": {
    "id": "user_id",
    "email": "user@example.com",
    "token": "jwt_token",
    ...
  }
}
```

### Get Profile
```
GET /api/auth/profile
Authorization: Bearer <jwt_token>

Response (200):
{
  "success": true,
  "data": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "John Doe",
    "profile": {
      "bio": "",
      "avatar": "",
      "learningStyle": "visual",
      "preferredLanguage": "en"
    },
    "stats": { ... }
  }
}
```

### Update Profile
```
PUT /api/auth/profile
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "profile": {
    "bio": "Student of Computer Science",
    "avatar": "avatar_url"
  }
}

Response (200):
{
  "success": true,
  "data": { ...updated_user }
}
```

---

## AI Learning Endpoints

### Generate Flashcards
```
POST /api/ai/flashcards/generate
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "topic": "Photosynthesis",
  "count": 10
}

Response (201):
{
  "success": true,
  "data": [
    {
      "question": "What is the primary function of chlorophyll?",
      "answer": "To absorb light energy for photosynthesis",
      "difficulty": "easy",
      "createdAt": "2026-01-27T...",
      "nextReview": "2026-01-27T...",
      "repetitions": 0,
      "interval": 1,
      "easeFactor": 2.5
    },
    ...
  ]
}
```

### Create Quiz
```
POST /api/ai/quiz/create
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "topic": "Algebra",
  "count": 5,
  "difficulty": "medium"
}

Response (201):
{
  "success": true,
  "data": {
    "quizId": "quiz_id",
    "questions": [
      {
        "question": "Solve: 2x + 5 = 15",
        "options": ["x = 5", "x = 10", "x = 3", "x = 7"],
        "correctAnswer": "A",
        "explanation": "2x = 10, so x = 5"
      },
      ...
    ]
  }
}
```

### Explain Concept
```
POST /api/ai/concept/explain
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "concept": "Mitochondria"
}

Response (200):
{
  "success": true,
  "data": {
    "concept": "Mitochondria",
    "explanation": "Mitochondria are cellular organelles that generate ATP through aerobic respiration, often called the 'powerhouse of the cell'..."
  }
}
```

### Generate Study Plan
```
POST /api/ai/study-plan/generate
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "subject": "Biology",
  "examDate": "2026-06-15",
  "currentKnowledge": 6
}

Response (201):
{
  "success": true,
  "data": {
    "planId": "plan_id",
    "plan": "Day 1: Cellular Biology...\nDay 2: Genetics...\n..."
  }
}
```

---

## Vision API Endpoints

### Scan Photo
```
POST /api/vision/scan
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data

FormData:
  - image: <file>
  - prompt: "Analyze this diagram" (optional)
  - userId: "user_id" (optional)

Response (200):
{
  "analysis": "This is a detailed analysis of the image..."
}
```

---

## Syllabus Endpoints

### Upload Syllabus
```
POST /api/syllabus/
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data

FormData:
  - file: <pdf_file>
  - title: "Biology Syllabus"
  - examDate: "2026-06-15" (optional)

Response (200):
{
  "success": true,
  "data": {
    "id": "syllabus_id",
    "title": "Biology Syllabus",
    "text": "...",
    "examDate": "2026-06-15",
    "createdAt": "2026-01-27T..."
  }
}
```

### Scan Syllabus
```
POST /api/syllabus/scan
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data

FormData:
  - file: <pdf_file>
  - prompt: "Generate a study plan from this syllabus"

Response (200):
{
  "analysis": "Based on this syllabus...",
  "fileUri": "gs://bucket/filename"
}
```

---

## Stats Endpoints

### Get User Statistics
```
GET /api/stats?userId=user_id
Authorization: Bearer <jwt_token>

Response (200):
{
  "totalInteractions": 45,
  "topics": {
    "Biology": 15,
    "Chemistry": 12,
    ...
  },
  "quizScores": [85, 92, 78, ...],
  "weakestTopics": [
    { "topic": "Organic Chemistry", "count": 8 },
    ...
  ],
  "streak": 5
}
```

---

## Model Selection & AI Capabilities

### Available Models
```
GEMINI_FLASH: Fast, low-cost (quick explanations, image analysis)
GEMINI_PRO: Medium speed, medium cost (detailed analysis, long context)
GEMMA_2B: Very fast, very low cost (quick Q&A, lightweight tasks)
GEMMA_7B: Fast, low cost (flashcard generation, concept explanation)
GEMMA_27B: Medium speed, medium cost (quiz creation, study plan generation)
```

### Model Selection Logic
```javascript
selectOptimalModel(taskType, complexity):
  - simple: GEMMA_2B / GEMINI_FLASH
  - medium: GEMMA_7B / GEMINI_FLASH
  - complex: GEMMA_27B / GEMINI_PRO
```

---

## Authentication

All protected endpoints require a JWT token in the `Authorization` header:
```
Authorization: Bearer <jwt_token>
```

The token is valid for 24 hours.

---

## Error Responses

All errors return a standardized format:
```json
{
  "error": "Error message describing the issue"
}
```

### Status Codes
- 400: Bad Request (missing/invalid parameters)
- 401: Unauthorized (no token or invalid token)
- 404: Not Found
- 429: Too Many Requests (rate limited)
- 500: Internal Server Error

---

## Rate Limiting

- Global: 100 requests per minute
- Per user: Depends on subscription tier (configurable)

---

## Environment Variables Required

```
GOOGLE_CLOUD_PROJECT=your-project-id
GCS_BUCKET=your-bucket-name
JWT_SECRET=your-secret-key
```

---

## File Size Limits

- Images: Up to 10MB
- PDFs: Up to 10MB (for detailed analysis with Gemini 1.5 Pro)

---

## Future Enhancements

1. **Flashcard Sets**: Create and manage flashcard collections
2. **Quiz History**: Track quiz attempts and scores over time
3. **Achievements**: Badge system for milestones
4. **Chat History**: Persistent conversation storage
5. **Content Search**: Full-text search across syllabi and lessons
6. **Offline Sync**: Synchronize data for offline mode
7. **WebSocket**: Real-time updates and live tutoring
8. **BigQuery Integration**: Advanced learning analytics
9. **Custom Models**: Fine-tuned models per subject
10. **Batch Processing**: Bulk content generation

---

## Version
**Backend v1.0.0**
- Vertex AI Integration
- Gemma Model Support
- JWT Authentication
- AI-Powered Learning Features
- Rate Limiting & Error Handling

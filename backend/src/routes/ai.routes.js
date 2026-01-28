const express = require('express');
const router = express.Router();
const { 
  explainTopic,
  createStudyPlan,
  createRevisionPlan,
  chatWithTutor,
  analyzeSyllabusDocument,
  analyzeEducationalImage,
  createQuizQuestions,
  getAIStatus
} = require('../controllers/ai.controller');
const { authenticateToken, createRateLimit } = require('../middleware/auth.middleware');

// Rate limiting for AI endpoints
const aiRateLimit = createRateLimit(60 * 1000, 30); // 30 requests per minute
const heavyAIRateLimit = createRateLimit(60 * 1000, 10); // 10 requests per minute for heavy operations

// Apply rate limiting to all AI routes
router.use(aiRateLimit);

// Public routes (no authentication required)
router.get('/status', getAIStatus);

// Protected routes (authentication required)
router.use(authenticateToken);

// Topic explanation
router.post('/explain', explainTopic);

// Study planning
router.post('/study-plan', heavyAIRateLimit, createStudyPlan);
router.post('/revision-plan', createRevisionPlan);

// Tutoring
router.post('/chat', chatWithTutor);

// Document analysis
router.post('/analyze-syllabus', heavyAIRateLimit, analyzeSyllabusDocument);

// Image analysis
router.post('/analyze-image', heavyAIRateLimit, analyzeEducationalImage);

// Quiz generation
router.post('/generate-quiz', createQuizQuestions);

module.exports = router;
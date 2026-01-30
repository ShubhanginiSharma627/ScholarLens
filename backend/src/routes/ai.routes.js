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
const aiRateLimit = createRateLimit(60 * 1000, 30); // 30 requests per minute
const heavyAIRateLimit = createRateLimit(60 * 1000, 10); // 10 requests per minute for heavy operations
router.use(aiRateLimit);
router.get('/status', getAIStatus);
router.use(authenticateToken);
router.post('/explain', explainTopic);
router.post('/study-plan', heavyAIRateLimit, createStudyPlan);
router.post('/revision-plan', createRevisionPlan);
router.post('/chat', chatWithTutor);
router.post('/analyze-syllabus', heavyAIRateLimit, analyzeSyllabusDocument);
router.post('/analyze-image', heavyAIRateLimit, analyzeEducationalImage);
router.post('/generate-quiz', createQuizQuestions);
module.exports = router;
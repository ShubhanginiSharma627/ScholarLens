const express = require('express');
const router = express.Router();
const { 
  explainTopicWithCache,
  createQuizQuestionsWithCache,
  chatWithTutorWithCache,
  generateFlashcardsWithCache,
  getEnhancedAIStatus,
  analyzeQuizPerformance
} = require('../controllers/enhanced-ai.controller');
const { authenticateToken, createRateLimit } = require('../middleware/auth.middleware');
const enhancedAIRateLimit = createRateLimit(60 * 1000, 25); // 25 requests per minute
const heavyEnhancedAIRateLimit = createRateLimit(60 * 1000, 8); // 8 requests per minute for heavy operations
router.use(enhancedAIRateLimit);
router.get('/status', getEnhancedAIStatus);
router.use(authenticateToken);
router.post('/explain', explainTopicWithCache);
router.post('/generate-quiz', createQuizQuestionsWithCache);
router.post('/chat', chatWithTutorWithCache);
router.post('/generate-flashcards', heavyEnhancedAIRateLimit, generateFlashcardsWithCache);
router.post('/analyze-performance', analyzeQuizPerformance);
module.exports = router;
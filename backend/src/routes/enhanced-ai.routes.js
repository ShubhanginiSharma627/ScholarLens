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

// Rate limiting for enhanced AI endpoints
const enhancedAIRateLimit = createRateLimit(60 * 1000, 25); // 25 requests per minute
const heavyEnhancedAIRateLimit = createRateLimit(60 * 1000, 8); // 8 requests per minute for heavy operations

// Apply rate limiting to all enhanced AI routes
router.use(enhancedAIRateLimit);

// Public routes (no authentication required)
router.get('/status', getEnhancedAIStatus);

// Protected routes (authentication required)
router.use(authenticateToken);

// Enhanced topic explanation with cache
router.post('/explain', explainTopicWithCache);

// Enhanced quiz generation with cache
router.post('/generate-quiz', createQuizQuestionsWithCache);

// Enhanced tutor chat with cache
router.post('/chat', chatWithTutorWithCache);

// Enhanced flashcard generation with cache
router.post('/generate-flashcards', heavyEnhancedAIRateLimit, generateFlashcardsWithCache);

// Quiz performance analysis
router.post('/analyze-performance', analyzeQuizPerformance);

module.exports = router;
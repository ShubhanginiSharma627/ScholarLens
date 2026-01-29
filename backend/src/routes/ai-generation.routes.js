const express = require('express');
const router = express.Router();
const {
  generateFromContent,
  getGenerationSession,
  getUserSessions,
  updateGeneratedFlashcard,
  deleteGeneratedFlashcard,
  regenerateFlashcard,
  approveAndSaveFlashcards,
  getUserPreferences,
  updateUserPreferences,
  getUserStats,
  getHealthStatus
} = require('../controllers/ai-generation.controller');
const { authenticateToken, createRateLimit } = require('../middleware/auth.middleware');

// Rate limiting for AI generation (more restrictive due to AI costs)
const aiGenerationRateLimit = createRateLimit(15 * 60 * 1000, 10); // 10 requests per 15 minutes
const generalRateLimit = createRateLimit(15 * 60 * 1000, 30); // 30 requests per 15 minutes

// All AI generation routes require authentication
router.use(authenticateToken);

// Health check (no rate limit)
router.get('/health', getHealthStatus);

// Content generation (most restrictive rate limit)
router.post('/generate', aiGenerationRateLimit, generateFromContent);

// Session management
router.get('/sessions', generalRateLimit, getUserSessions);
router.get('/sessions/:sessionId', generalRateLimit, getGenerationSession);

// Flashcard management within sessions
router.put('/flashcards/:flashcardId', generalRateLimit, updateGeneratedFlashcard);
router.delete('/flashcards/:flashcardId', generalRateLimit, deleteGeneratedFlashcard);
router.post('/flashcards/:flashcardId/regenerate', aiGenerationRateLimit, regenerateFlashcard);

// Approval and saving
router.post('/approve', generalRateLimit, approveAndSaveFlashcards);

// User preferences
router.get('/preferences', generalRateLimit, getUserPreferences);
router.put('/preferences', generalRateLimit, updateUserPreferences);

// Analytics and statistics
router.get('/stats', generalRateLimit, getUserStats);

module.exports = router;
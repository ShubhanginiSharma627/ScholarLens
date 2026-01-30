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
const aiGenerationRateLimit = createRateLimit(15 * 60 * 1000, 10); // 10 requests per 15 minutes
const generalRateLimit = createRateLimit(15 * 60 * 1000, 30); // 30 requests per 15 minutes
router.use(authenticateToken);
router.get('/health', getHealthStatus);
router.post('/generate', aiGenerationRateLimit, generateFromContent);
router.get('/sessions', generalRateLimit, getUserSessions);
router.get('/sessions/:sessionId', generalRateLimit, getGenerationSession);
router.put('/flashcards/:flashcardId', generalRateLimit, updateGeneratedFlashcard);
router.delete('/flashcards/:flashcardId', generalRateLimit, deleteGeneratedFlashcard);
router.post('/flashcards/:flashcardId/regenerate', aiGenerationRateLimit, regenerateFlashcard);
router.post('/approve', generalRateLimit, approveAndSaveFlashcards);
router.get('/preferences', generalRateLimit, getUserPreferences);
router.put('/preferences', generalRateLimit, updateUserPreferences);
router.get('/stats', generalRateLimit, getUserStats);
module.exports = router;
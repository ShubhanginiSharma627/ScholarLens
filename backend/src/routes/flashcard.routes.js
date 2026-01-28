const express = require('express');
const router = express.Router();
const { 
  createFlashcard, 
  getFlashcards, 
  updateFlashcard, 
  deleteFlashcard,
  generateFlashcardsFromTopic,
  createFlashcardSet,
  getFlashcardSets,
  studyFlashcards
} = require('../controllers/flashcard.controller');
const { authenticateToken, createRateLimit } = require('../middleware/auth.middleware');

// Rate limiting
const flashcardRateLimit = createRateLimit(15 * 60 * 1000, 50); // 50 requests per 15 minutes

// All flashcard routes require authentication
router.use(authenticateToken);
router.use(flashcardRateLimit);

// Flashcard CRUD
router.post('/', createFlashcard);
router.get('/', getFlashcards);
router.put('/:id', updateFlashcard);
router.delete('/:id', deleteFlashcard);

// AI-powered flashcard generation
router.post('/generate', generateFlashcardsFromTopic);

// Flashcard sets
router.post('/sets', createFlashcardSet);
router.get('/sets', getFlashcardSets);

// Study sessions
router.post('/study', studyFlashcards);

module.exports = router;
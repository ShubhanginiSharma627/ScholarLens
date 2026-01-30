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
const flashcardRateLimit = createRateLimit(15 * 60 * 1000, 50); // 50 requests per 15 minutes
router.use(authenticateToken);
router.use(flashcardRateLimit);
router.post('/', createFlashcard);
router.get('/', getFlashcards);
router.put('/:id', updateFlashcard);
router.delete('/:id', deleteFlashcard);
router.post('/generate', generateFlashcardsFromTopic);
router.post('/sets', createFlashcardSet);
router.get('/sets', getFlashcardSets);
router.post('/study', studyFlashcards);
module.exports = router;
const express = require('express');
const router = express.Router();
const gemmaController = require('../controllers/gemma.controller');
const { authenticate } = require('../middleware/auth.middleware');

// Protected routes (require authentication)
router.post('/flashcards/generate', authenticate, gemmaController.generateFlashcards);
router.post('/quiz/create', authenticate, gemmaController.createQuiz);
router.post('/concept/explain', authenticate, gemmaController.explainConcept);
router.post('/study-plan/generate', authenticate, gemmaController.generateStudyPlan);

module.exports = router;
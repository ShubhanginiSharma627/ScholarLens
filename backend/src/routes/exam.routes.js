const express = require('express');
const router = express.Router();
const { todaysFocus, chatExplain, getExams } = require('../controllers/exam.controller');

// POST /today-focus
router.post('/today-focus', todaysFocus);
// POST /chat-explain
router.post('/chat-explain', chatExplain);
// Endpoint for exam-related requests
router.get('/', getExams);

module.exports = router;

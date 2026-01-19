const express = require('express');
const router = express.Router();
const { todaysFocus, chatExplain } = require('../controllers/exam.controller');

// POST /today-focus
router.post('/today-focus', todaysFocus);
// POST /chat-explain
router.post('/chat-explain', chatExplain);

module.exports = router;

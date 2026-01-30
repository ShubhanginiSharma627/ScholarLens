const express = require('express');
const router = express.Router();
const { todaysFocus, chatExplain, getExams } = require('../controllers/exam.controller');
router.post('/today-focus', todaysFocus);
router.post('/chat-explain', chatExplain);
router.get('/', getExams);
module.exports = router;

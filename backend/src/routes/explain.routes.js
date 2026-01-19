const express = require('express');
const router = express.Router();
const { explainTopic } = require('../controllers/explain.controller');

// POST /explain-topic
router.post('/', explainTopic);

module.exports = router;

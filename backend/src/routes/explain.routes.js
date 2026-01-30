const express = require('express');
const router = express.Router();
const { explainTopic } = require('../controllers/explain.controller');
router.post('/', explainTopic);
module.exports = router;

const express = require('express');
const router = express.Router();
const statsController = require('../controllers/stats.controller');

// Endpoint for user stats
router.get('/', statsController.getStats);

module.exports = router;
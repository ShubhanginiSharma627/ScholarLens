const express = require('express');
const router = express.Router();
const { generatePlan } = require('../controllers/plan.controller');

// POST /generate-plan
router.post('/', generatePlan);

module.exports = router;

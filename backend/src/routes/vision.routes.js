const express = require('express');
const router = express.Router();
const multer = require('multer');
const upload = multer({ dest: 'tmp/' });
const visionController = require('../controllers/vision.controller');

// Endpoint for photo scanning (supports multipart or Base64)
router.post('/scan', upload.single('image'), visionController.scanPhoto);

module.exports = router;
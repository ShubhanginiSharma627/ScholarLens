const express = require('express');
const multer = require('multer');
const router = express.Router();
const {
  uploadFile,
  getDownloadUrl,
  deleteFile,
  listFiles,
  getStorageStatus
} = require('../controllers/storage.controller');
const { authenticateToken, createRateLimit } = require('../middleware/auth.middleware');
const upload = multer({
  dest: 'tmp/',
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024, // 10MB default
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = process.env.ALLOWED_FILE_TYPES?.split(',') || [
      'pdf', 'jpg', 'jpeg', 'png', 'gif', 'txt', 'doc', 'docx'
    ];
    const fileExtension = file.originalname.split('.').pop()?.toLowerCase();
    if (allowedTypes.includes(fileExtension)) {
      cb(null, true);
    } else {
      cb(new Error(`File type .${fileExtension} not allowed. Allowed types: ${allowedTypes.join(', ')}`));
    }
  }
});
const storageRateLimit = createRateLimit(60 * 1000, 20); // 20 requests per minute
const uploadRateLimit = createRateLimit(60 * 1000, 5); // 5 uploads per minute
router.use(storageRateLimit);
router.get('/status', getStorageStatus);
router.use(authenticateToken);
router.post('/upload', uploadRateLimit, upload.single('file'), uploadFile);
router.get('/download/:fileName', getDownloadUrl);
router.delete('/files/:fileName', deleteFile);
router.get('/files', listFiles);
module.exports = router;
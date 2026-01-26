const express = require('express');
const router = express.Router();
const multer = require('multer');
const upload = multer({ dest: 'tmp/' });
const { uploadSyllabus, getSyllabus, listSyllabi, scanSyllabus } = require('../controllers/syllabus.controller');

// POST /upload-syllabus (multipart with file OR application/json with text)
router.post('/', upload.single('file'), uploadSyllabus);
router.post('/scan', upload.single('file'), scanSyllabus);
router.get('/:id', getSyllabus);
router.get('/', listSyllabi);

module.exports = router;

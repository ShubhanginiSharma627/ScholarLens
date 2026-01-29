const pdf = require('pdf-parse');
const fs = require('fs-extra');
const path = require('path');
const syllabusService = require('../services/syllabus.service');
const gcsStorage = require('../services/gcs-storage.service');
const { analyzeDocument } = require('../services/vertexai.service');
const { socraticTutorPrompt } = require('../utils/promptUtils');
const firestore = require('@google-cloud/firestore');

const db = new firestore.Firestore();

async function extractTextFromPdf(filePath) {
  const data = await fs.readFile(filePath);
  const parsed = await pdf(data);
  return parsed.text;
}

async function uploadSyllabus(req, res, next) {
  try {
    const { title, examDate, text } = req.body || {};

    let syllabusText = text;

    if (req.file) {
      const ext = path.extname(req.file.originalname).toLowerCase();
      if (ext === '.pdf') {
        syllabusText = await extractTextFromPdf(req.file.path);
      } else {
        // read raw file
        syllabusText = (await fs.readFile(req.file.path)).toString('utf8');
      }
      // cleanup
      await fs.remove(req.file.path);
    }

    if (!syllabusText || !syllabusText.trim()) {
      return res.status(400).json({ success: false, error: { message: 'No syllabus text provided' } });
    }

    const saved = await syllabusService.saveSyllabus({ title: title || 'uploaded syllabus', text: syllabusText, examDate });

    // Log interaction
    await db.collection('interactions').add({
      type: 'syllabus_upload',
      userId: req.body.userId || 'anonymous',
      title: saved.title,
      timestamp: new Date(),
    });

    return res.json({ success: true, data: saved });
  } catch (err) {
    next(err);
  }
}

async function getSyllabus(req, res, next) {
  try {
    const id = req.params.id;
    const data = await syllabusService.getSyllabus(id);
    if (!data) return res.status(404).json({ success: false, error: { message: 'Syllabus not found' } });
    return res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function listSyllabi(req, res, next) {
  try {
    const items = await syllabusService.listSyllabi();
    return res.json({ success: true, data: items });
  } catch (err) {
    next(err);
  }
}

exports.scanSyllabus = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file provided' });
    }

    // Check if GCS Storage is configured
    if (!gcsStorage.isConfigured()) {
      return res.status(500).json({ error: 'Google Cloud Storage not configured' });
    }

    const file = req.file;
    const fileName = gcsStorage.generateUniqueFilename(file.originalname, 'syllabus-');

    // Upload to Google Cloud Storage
    const downloadUrl = await gcsStorage.uploadFile(file.path, fileName, {
      contentType: file.mimetype,
      makePublic: false, // Keep private for security
      originalName: file.originalname,
      uploadedBy: req.body.userId || 'anonymous',
    });

    // Cleanup local file
    await fs.remove(file.path);

    const userPrompt = req.body.prompt || 'Analyze this syllabus and provide a study plan.';
    const fullPrompt = socraticTutorPrompt(userPrompt, 'Syllabus analysis');

    // For document analysis, we need the GCS Storage path
    const gcsStoragePath = `gs://${process.env.GCS_BUCKET}/${fileName}`;
    const analysis = await analyzeDocument(gcsStoragePath, fullPrompt, 'gemini-1.5-pro');

    // Log interaction
    await db.collection('interactions').add({
      type: 'syllabus',
      userId: req.body.userId || 'anonymous',
      prompt: userPrompt,
      fileUri: gcsStoragePath,
      downloadUrl: downloadUrl,
      timestamp: new Date(),
    });

    res.status(200).json({ 
      analysis, 
      fileUri: gcsStoragePath,
      downloadUrl: downloadUrl 
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error processing syllabus' });
  }
};

module.exports = { uploadSyllabus, getSyllabus, listSyllabi, scanSyllabus: exports.scanSyllabus };

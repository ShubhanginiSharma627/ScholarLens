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
        syllabusText = (await fs.readFile(req.file.path)).toString('utf8');
      }
      await fs.remove(req.file.path);
    }
    if (!syllabusText || !syllabusText.trim()) {
      return res.status(400).json({ success: false, error: { message: 'No syllabus text provided' } });
    }
    const saved = await syllabusService.saveSyllabus({ title: title || 'uploaded syllabus', text: syllabusText, examDate });
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

    if (!gcsStorage.isConfigured()) {
      return res.status(500).json({ error: 'Google Cloud Storage not configured' });
    }

    const file = req.file;
    const fileName = gcsStorage.generateUniqueFilename(file.originalname, 'syllabus-');

    const downloadUrl = await gcsStorage.uploadFile(file.path, fileName, {
      contentType: file.mimetype,
      makePublic: false, // Keep private for security
      originalName: file.originalname,
      uploadedBy: req.body.userId || 'anonymous',
    });

    await fs.remove(file.path);

    const userPrompt = req.body.prompt || 'Analyze this syllabus and provide a study plan.';
    const fullPrompt = socraticTutorPrompt(userPrompt, 'Syllabus analysis');
    const gcsStoragePath = `gs://${process.env.GCS_BUCKET}/${fileName}`;

    try {
      const analysis = await analyzeDocument(gcsStoragePath, fullPrompt, 'gemini-1.5-pro');

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
    } catch (analysisError) {
      // Check if this is the service agents provisioning error
      if (analysisError.message && analysisError.message.includes('Service agents are being provisioned')) {
        console.log('Service agents still being provisioned, returning helpful message');
        
        // Still log the interaction for tracking
        await db.collection('interactions').add({
          type: 'syllabus_upload_pending',
          userId: req.body.userId || 'anonymous',
          prompt: userPrompt,
          fileUri: gcsStoragePath,
          downloadUrl: downloadUrl,
          status: 'pending_service_agents',
          timestamp: new Date(),
        });

        return res.status(202).json({
          message: 'File uploaded successfully! Google Cloud services are still being set up for your project. Please try analyzing the file again in 2-3 minutes.',
          status: 'uploaded_pending_analysis',
          fileUri: gcsStoragePath,
          downloadUrl: downloadUrl,
          retryAfter: 180, // 3 minutes in seconds
          helpText: 'This is a one-time setup process for new Google Cloud projects. The file is safely stored and ready for analysis once the services are ready.'
        });
      }
      
      // For other analysis errors, throw them normally
      throw analysisError;
    }
  } catch (error) {
    console.error(error);
    
    // Provide more specific error messages
    if (error.message && error.message.includes('Service agents are being provisioned')) {
      return res.status(503).json({ 
        error: 'Google Cloud services are still being set up. Please try again in 2-3 minutes.',
        retryAfter: 180,
        code: 'SERVICE_AGENTS_PROVISIONING'
      });
    }
    
    if (error.message && error.message.includes('bucket does not exist')) {
      return res.status(500).json({ 
        error: 'Storage configuration error. Please contact support.',
        code: 'STORAGE_NOT_CONFIGURED'
      });
    }
    
    res.status(500).json({ 
      error: 'Error processing syllabus. Please try again later.',
      code: 'PROCESSING_ERROR'
    });
  }
};
module.exports = { uploadSyllabus, getSyllabus, listSyllabi, scanSyllabus: exports.scanSyllabus };

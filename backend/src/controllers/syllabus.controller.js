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
    const originalFileName = file.originalname;
    
    try {
      const existingFiles = await gcsStorage.listFiles('syllabus');
      const duplicateFile = existingFiles.find(existingFile => {
        const existingOriginalName = existingFile.metadata?.originalName || existingFile.name;
        return existingOriginalName === originalFileName && 
               Math.abs(existingFile.size - file.size) < 1000;
      });

      if (duplicateFile) {
        await fs.remove(file.path);
        
        const existingAnalysis = duplicateFile.metadata?.analysis || 'This document has been previously analyzed.';
        
        return res.status(200).json({
          success: true,
          data: {
            analysis: existingAnalysis,
            fileUri: `gs://${process.env.GCS_BUCKET}/${duplicateFile.name}`,
            downloadUrl: await gcsStorage.getDownloadUrl(duplicateFile.name),
            isDuplicate: true,
            message: 'File already exists. Returning previous analysis.'
          }
        });
      }
    } catch (listError) {
      console.log('Could not check for duplicates:', listError.message);
    }

    const fileName = gcsStorage.generateUniqueFilename(file.originalname, 'syllabus-');

    const downloadUrl = await gcsStorage.uploadFile(file.path, fileName, {
      contentType: file.mimetype,
      makePublic: false,
      originalName: file.originalname,
      uploadedBy: req.body.userId || 'anonymous',
      fileSize: file.size,
    });

    await fs.remove(file.path);

    const userPrompt = req.body.prompt || 'Analyze this syllabus and provide a study plan.';
    const fullPrompt = socraticTutorPrompt(userPrompt, 'Syllabus analysis');
    const gcsStoragePath = `gs://${process.env.GCS_BUCKET}/${fileName}`;

    try {
      const analysis = await analyzeDocument(gcsStoragePath, fullPrompt, 'gemini-1.5-pro');

      try {
        const analysisMetadata = _extractAnalysisMetadata(analysis);
        await gcsStorage.updateFileMetadata(fileName, {
          analysis: analysis,
          ...analysisMetadata,
          analyzedAt: new Date().toISOString(),
        });
      } catch (metadataError) {
        console.log('Could not update file metadata:', metadataError.message);
      }

      await db.collection('interactions').add({
        type: 'syllabus',
        userId: req.body.userId || 'anonymous',
        prompt: userPrompt,
        fileUri: gcsStoragePath,
        downloadUrl: downloadUrl,
        timestamp: new Date(),
      });

      res.status(200).json({ 
        success: true,
        data: {
          analysis, 
          fileUri: gcsStoragePath,
          downloadUrl: downloadUrl,
          isDuplicate: false
        }
      });
    } catch (analysisError) {
      if (analysisError.message && analysisError.message.includes('Service agents are being provisioned')) {
        console.log('Service agents still being provisioned, returning helpful message');
        
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
          success: true,
          data: {
            message: 'File uploaded successfully! Google Cloud services are still being set up for your project. Please try analyzing the file again in 2-3 minutes.',
            status: 'uploaded_pending_analysis',
            fileUri: gcsStoragePath,
            downloadUrl: downloadUrl,
            retryAfter: 180,
            helpText: 'This is a one-time setup process for new Google Cloud projects. The file is safely stored and ready for analysis once the services are ready.'
          }
        });
      }
      
      throw analysisError;
    }
  } catch (error) {
    console.error(error);
    
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

function _extractAnalysisMetadata(analysis) {
  try {
    const metadata = {
      chapters: [],
      keyTopics: [],
      subject: 'Unknown',
      totalPages: 0
    };

    const lines = analysis.split('\n');
    
    for (const line of lines) {
      const lowerLine = line.toLowerCase().trim();
      
      if (lowerLine.includes('chapter') || lowerLine.includes('unit')) {
        if (line.length < 100) {
          metadata.chapters.push(line.trim());
        }
      }
      
      if (lowerLine.includes('topic') || lowerLine.includes('concept')) {
        if (line.length < 80) {
          metadata.keyTopics.push(line.trim());
        }
      }
      
      if (lowerLine.includes('subject') || lowerLine.includes('course')) {
        const subjectMatch = line.match(/(?:subject|course):\s*([^,.\n]+)/i);
        if (subjectMatch) {
          metadata.subject = subjectMatch[1].trim();
        }
      }
      
      if (lowerLine.includes('page')) {
        const pageMatch = line.match(/(\d+)\s*pages?/i);
        if (pageMatch) {
          metadata.totalPages = parseInt(pageMatch[1]);
        }
      }
    }
    
    metadata.chapters = metadata.chapters.slice(0, 10);
    metadata.keyTopics = metadata.keyTopics.slice(0, 15);
    
    return metadata;
  } catch (error) {
    console.log('Error extracting analysis metadata:', error.message);
    return {
      chapters: [],
      keyTopics: [],
      subject: 'Unknown',
      totalPages: 0
    };
  }
}
module.exports = { uploadSyllabus, getSyllabus, listSyllabi, scanSyllabus: exports.scanSyllabus };

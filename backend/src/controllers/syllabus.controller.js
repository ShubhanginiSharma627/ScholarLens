const pdf = require('pdf-parse');
const fs = require('fs-extra');
const path = require('path');
const syllabusService = require('../services/syllabus.service');
const gcsStorage = require('../services/gcs-storage.service');
const { analyzeDocument } = require('../services/vertexai.service');
const { syllabusAnalysisPrompt } = require('../utils/promptUtils');
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
        const existingMetadata = {
          chapters: duplicateFile.metadata?.chapters ? JSON.parse(duplicateFile.metadata.chapters) : [],
          keyTopics: duplicateFile.metadata?.keyTopics ? JSON.parse(duplicateFile.metadata.keyTopics) : [],
          subject: duplicateFile.metadata?.subject || 'Unknown',
          totalPages: parseInt(duplicateFile.metadata?.totalPages || '0')
        };
        
        return res.status(200).json({
          success: true,
          data: {
            analysis: existingAnalysis,
            fileUri: `gs://${process.env.GCS_BUCKET}/${duplicateFile.name}`,
            downloadUrl: await gcsStorage.getDownloadUrl(duplicateFile.name),
            isDuplicate: true,
            message: 'File already exists. Returning previous analysis.',
            metadata: existingMetadata
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

    const userPrompt = req.body.prompt || 'Analyze this document and provide a structured overview.';
    const analysisPrompt = syllabusAnalysisPrompt(userPrompt);
    const gcsStoragePath = `gs://${process.env.GCS_BUCKET}/${fileName}`;

    try {
      const analysis = await analyzeDocument(gcsStoragePath, analysisPrompt, 'gemini-1.5-pro');

      try {
        const analysisMetadata = _extractAnalysisMetadata(analysis);
        await gcsStorage.updateFileMetadata(fileName, {
          analysis: analysis,
          chapters: JSON.stringify(analysisMetadata.chapters),
          keyTopics: JSON.stringify(analysisMetadata.keyTopics),
          subject: analysisMetadata.subject,
          totalPages: analysisMetadata.totalPages.toString(),
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

    if (!analysis || typeof analysis !== 'string') {
      return _generateMinimalFallback();
    }

    // First, try to parse as JSON (expected format from syllabus_analysis.prompts.txt)
    try {
      const jsonResponse = JSON.parse(analysis);
      
      // Extract from structured JSON response
      if (jsonResponse.course_overview) {
        metadata.subject = jsonResponse.course_overview.subject_area || 
                          jsonResponse.course_overview.title || 
                          'Unknown';
      }
      
      if (jsonResponse.content_structure && jsonResponse.content_structure.units) {
        for (const unit of jsonResponse.content_structure.units) {
          if (unit.title) {
            metadata.chapters.push(unit.title);
          }
          if (unit.topics) {
            for (const topic of unit.topics) {
              if (topic.name) {
                metadata.keyTopics.push(topic.name);
              }
            }
          }
          if (unit.key_concepts) {
            metadata.keyTopics.push(...unit.key_concepts);
          }
        }
      }
      
      if (jsonResponse.learning_objectives) {
        if (jsonResponse.learning_objectives.knowledge_areas) {
          for (const area of jsonResponse.learning_objectives.knowledge_areas) {
            if (area.area) {
              metadata.keyTopics.push(area.area);
            }
          }
        }
        if (jsonResponse.learning_objectives.primary_goals) {
          metadata.keyTopics.push(...jsonResponse.learning_objectives.primary_goals);
        }
      }
      
      // Remove duplicates and limit size
      metadata.chapters = [...new Set(metadata.chapters)].slice(0, 8);
      metadata.keyTopics = [...new Set(metadata.keyTopics)].slice(0, 10);
      
      return metadata;
    } catch (jsonError) {
      // If JSON parsing fails, fall back to text parsing
      console.log('JSON parsing failed, falling back to text analysis:', jsonError.message);
    }

    // Fallback: Parse as plain text (in case AI doesn't return JSON)
    const lines = analysis.split('\n');
    let currentSection = '';
    
    for (const line of lines) {
      const lowerLine = line.toLowerCase().trim();
      const cleanLine = line.trim();
      
      if (cleanLine.length === 0) continue;
      
      // Detect sections from our structured prompt or natural language
      if (lowerLine.includes('subject:') || lowerLine.includes('1. subject') || lowerLine.includes('course:')) {
        currentSection = 'subject';
        const match = cleanLine.match(/(?:subject|course|1\.\s*subject):\s*(.+)/i);
        if (match) {
          metadata.subject = match[1].trim();
        }
        continue;
      }
      
      if (lowerLine.includes('chapters') || lowerLine.includes('sections') || lowerLine.includes('units') || 
          lowerLine.includes('2. chapters') || lowerLine.includes('content structure')) {
        currentSection = 'chapters';
        continue;
      }
      
      if (lowerLine.includes('key topics') || lowerLine.includes('topics') || lowerLine.includes('3. key topics') ||
          lowerLine.includes('learning objectives')) {
        currentSection = 'topics';
        continue;
      }
      
      if (lowerLine.includes('pages') || lowerLine.includes('4. pages')) {
        currentSection = 'pages';
        const pageMatch = cleanLine.match(/(\d+)\s*pages?/i);
        if (pageMatch) {
          metadata.totalPages = parseInt(pageMatch[1]);
        }
        continue;
      }
      
      // Process content based on current section
      if (currentSection === 'chapters' && cleanLine.length > 3 && cleanLine.length < 120) {
        let chapter = cleanLine.replace(/^[-*•]\s*/, '');
        chapter = chapter.replace(/^\d+\.\s*/, '');
        chapter = chapter.replace(/^(chapter|unit|section|lesson|module|part)\s*/i, '');
        if (chapter.length > 3) {
          metadata.chapters.push(chapter.charAt(0).toUpperCase() + chapter.slice(1));
        }
      }
      
      if (currentSection === 'topics' && cleanLine.length > 3 && cleanLine.length < 100) {
        let topic = cleanLine.replace(/^[-*•]\s*/, '');
        topic = topic.replace(/^\d+\.\s*/, '');
        if (topic.length > 3) {
          metadata.keyTopics.push(topic.charAt(0).toUpperCase() + topic.slice(1));
        }
      }
      
      // General fallback patterns if no sections detected
      if (!currentSection) {
        if (lowerLine.includes('subject:') || lowerLine.includes('course:') || lowerLine.includes('topic:')) {
          const match = cleanLine.match(/(?:subject|course|topic):\s*([^,.\n]+)/i);
          if (match) {
            metadata.subject = match[1].trim();
          }
        }
        
        if (lowerLine.match(/^(chapter|unit|section|lesson|module|part)\s*\d+/i) || 
            lowerLine.match(/^\d+\.\s/) ||
            lowerLine.match(/^[ivx]+\.\s/i)) {
          if (cleanLine.length < 120 && cleanLine.length > 5) {
            let chapterTitle = cleanLine.replace(/^(chapter|unit|section|lesson|module|part)\s*/i, '');
            chapterTitle = chapterTitle.replace(/^\d+\.?\s*/, '');
            chapterTitle = chapterTitle.replace(/^[ivx]+\.?\s*/i, '');
            if (chapterTitle.length > 3) {
              metadata.chapters.push(chapterTitle.charAt(0).toUpperCase() + chapterTitle.slice(1));
            }
          }
        }
        
        const pageMatch = lowerLine.match(/(\d+)\s*pages?/i);
        if (pageMatch) {
          metadata.totalPages = Math.max(metadata.totalPages, parseInt(pageMatch[1]));
        }
      }
    }
    
    // Remove duplicates and limit size
    metadata.chapters = [...new Set(metadata.chapters)].slice(0, 8);
    metadata.keyTopics = [...new Set(metadata.keyTopics)].slice(0, 10);
    
    // Only use minimal fallback if we have absolutely nothing
    if (metadata.chapters.length === 0 && metadata.keyTopics.length === 0) {
      const fallback = _generateMinimalFallback();
      metadata.chapters = fallback.chapters;
      metadata.keyTopics = fallback.keyTopics;
    }
    
    return metadata;
  } catch (error) {
    console.log('Error extracting analysis metadata:', error.message);
    return _generateMinimalFallback();
  }
}

function _generateMinimalFallback() {
  return {
    chapters: ['Document Overview'],
    keyTopics: ['Key Concepts'],
    subject: 'General',
    totalPages: 0
  };
}
module.exports = { uploadSyllabus, getSyllabus, listSyllabi, scanSyllabus: exports.scanSyllabus };

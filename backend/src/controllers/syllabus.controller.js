const pdf = require('pdf-parse');
const fs = require('fs-extra');
const path = require('path');
const syllabusService = require('../services/syllabus.service');

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

module.exports = { uploadSyllabus, getSyllabus, listSyllabi };

const syllabusService = require('../services/syllabus.service');
const { generateText } = require('../services/vertexai.service');
const { socraticTutorPrompt } = require('../utils/promptUtils');
const firestore = require('@google-cloud/firestore');

const db = new firestore.Firestore();

// POST /today-focus
async function todaysFocus(req, res, next) {
  try {
    const { syllabusId, date } = req.body || {};
    if (!syllabusId) return res.status(400).json({ success: false, error: { message: '`syllabusId` is required' } });
    const syllabus = await syllabusService.getSyllabus(syllabusId);
    if (!syllabus) return res.status(404).json({ success: false, error: { message: 'Syllabus not found' } });

    const prompt = `Based on the syllabus: ${syllabus.text}, exam date: ${syllabus.examDate}, and date: ${date}, what should the student focus on today?`;
    const fullPrompt = socraticTutorPrompt(prompt, 'Daily focus');
    const focus = await generateText(fullPrompt);

    // Log interaction
    await db.collection('interactions').add({
      type: 'focus',
      userId: req.body.userId || 'anonymous',
      syllabusId,
      timestamp: new Date(),
    });

    return res.json({ success: true, data: focus });
  } catch (err) {
    next(err);
  }
}

// POST /chat-explain
async function chatExplain(req, res, next) {
  try {
    const { syllabusId, topic, audience = 'student', variation = 'different' } = req.body || {};
    if (!topic) return res.status(400).json({ success: false, error: { message: '`topic` is required' } });

    let contextText = '';
    if (syllabusId) {
      const s = await syllabusService.getSyllabus(syllabusId);
      if (s) contextText = s.text;
    }

    const prompt = `Explain ${topic} for a ${audience}. Context: ${contextText}. Variation: ${variation}`;
    const fullPrompt = socraticTutorPrompt(prompt, 'Topic explanation with context');
    const explanation = await generateText(fullPrompt);

    // Log interaction
    await db.collection('interactions').add({
      type: 'explain',
      userId: req.body.userId || 'anonymous',
      topic,
      syllabusId,
      timestamp: new Date(),
    });

    return res.json({ success: true, data: explanation });
  } catch (err) {
    next(err);
  }
}

// GET /exams

exports.getExams = async (req, res) => {
  try {
    // Logic to retrieve exams
    // Placeholder: assume we have exams in Firestore
    const examsRef = db.collection('exams');
    const snapshot = await examsRef.get();
    const exams = [];
    snapshot.forEach(doc => exams.push(doc.data()));

    // Log interaction
    await db.collection('interactions').add({
      type: 'exam_view',
      userId: req.query.userId || 'anonymous',
      timestamp: new Date(),
    });

    res.status(200).json({ exams });
  } catch (error) {
    res.status(500).json({ error: 'Error retrieving exams' });
  }
};

module.exports = { todaysFocus, chatExplain, getExams: exports.getExams };

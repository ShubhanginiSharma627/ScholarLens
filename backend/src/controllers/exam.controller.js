const syllabusService = require('../services/syllabus.service');
const openaiService = require('../services/openai.service');

// POST /today-focus
async function todaysFocus(req, res, next) {
  try {
    const { syllabusId, date } = req.body || {};
    if (!syllabusId) return res.status(400).json({ success: false, error: { message: '`syllabusId` is required' } });
    const syllabus = await syllabusService.getSyllabus(syllabusId);
    if (!syllabus) return res.status(404).json({ success: false, error: { message: 'Syllabus not found' } });

    const focus = await openaiService.getTodaysFocus({ syllabusText: syllabus.text, examDate: syllabus.examDate, date });
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

    const explanation = await openaiService.explainTopicWithContext({ topic, audience, contextText, variation });
    return res.json({ success: true, data: explanation });
  } catch (err) {
    next(err);
  }
}

module.exports = { todaysFocus, chatExplain };

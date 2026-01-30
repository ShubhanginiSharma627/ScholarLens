const {
  generateFlashcards,
  createQuizQuestions,
  explainConcept,
  generateStudyPlan
} = require('../services/gemma.service');
exports.generateFlashcards = async (req, res) => {
  try {
    const { topic, count = 10 } = req.body;
    const userId = req.user.userId;
    if (!topic) {
      return res.status(400).json({ error: 'Topic is required' });
    }
    const flashcards = await generateFlashcards(topic, count, userId);
    res.status(201).json({ success: true, data: flashcards });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
exports.createQuiz = async (req, res) => {
  try {
    const { topic, count = 5, difficulty = 'medium' } = req.body;
    const userId = req.user.userId;
    if (!topic) {
      return res.status(400).json({ error: 'Topic is required' });
    }
    const quiz = await createQuizQuestions(topic, count, difficulty, userId);
    res.status(201).json({ success: true, data: quiz });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
exports.explainConcept = async (req, res) => {
  try {
    const { concept } = req.body;
    const userId = req.user.userId;
    if (!concept) {
      return res.status(400).json({ error: 'Concept is required' });
    }
    const explanation = await explainConcept(concept, userId);
    res.status(200).json({ success: true, data: { concept, explanation } });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
exports.generateStudyPlan = async (req, res) => {
  try {
    const { subject, examDate, currentKnowledge } = req.body;
    const userId = req.user.userId;
    if (!subject || !examDate) {
      return res.status(400).json({ error: 'Subject and exam date are required' });
    }
    const plan = await generateStudyPlan(subject, examDate, currentKnowledge || 5, userId);
    res.status(201).json({ success: true, data: plan });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
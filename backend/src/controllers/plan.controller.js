const { generateText } = require('../services/vertexai.service');
const { socraticTutorPrompt } = require('../utils/promptUtils');
const firestore = require('@google-cloud/firestore');

const db = new firestore.Firestore();

async function generatePlan(req, res, next) {
  try {
    const { topic, audience = 'general', length = 'short', constraints = '' } = req.body || {};

    if (!topic || typeof topic !== 'string') {
      return res.status(400).json({ success: false, error: { message: '`topic` is required and must be a string' } });
    }

    const fullPrompt = socraticTutorPrompt(`Create a ${length} study plan for ${topic} for a ${audience}. Constraints: ${constraints}`, 'Study plan generation');

    const plan = await generateText(fullPrompt);

    // Log interaction
    await db.collection('interactions').add({
      type: 'plan',
      userId: req.body.userId || 'anonymous',
      topic,
      timestamp: new Date(),
    });

    return res.json({ success: true, data: plan });
  } catch (err) {
    next(err);
  }
}

exports.createStudyPlan = async (req, res) => {
  try {
    const { topic } = req.body;
    if (!topic) {
      return res.status(400).json({ error: 'Topic required' });
    }

    const fullPrompt = socraticTutorPrompt(`Create a study plan for ${topic}`, 'Study plan creation');

    const plan = await generateText(fullPrompt);

    // Log interaction
    await db.collection('interactions').add({
      type: 'plan',
      userId: req.body.userId || 'anonymous',
      topic,
      timestamp: new Date(),
    });

    res.status(200).json({ plan });
  } catch (error) {
    res.status(500).json({ error: 'Error creating study plan' });
  }
};

module.exports = { generatePlan };

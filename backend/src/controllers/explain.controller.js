const { generateText } = require('../services/vertexai.service');
const { socraticTutorPrompt } = require('../utils/promptUtils');
const firestore = require('@google-cloud/firestore');

const db = new firestore.Firestore();

exports.explainTopic = async (req, res) => {
  try {
    const { topic, audience = 'student', type = 'concise' } = req.body || {};

    if (!topic || typeof topic !== 'string') {
      return res.status(400).json({ success: false, error: { message: '`topic` is required and must be a string' } });
    }

    const fullPrompt = socraticTutorPrompt(`Explain ${topic} for a ${audience} in a ${type} way.`, 'Topic explanation');

    const explanation = await generateText(fullPrompt);

    // Log interaction
    await db.collection('interactions').add({
      type: 'explain',
      userId: req.body.userId || 'anonymous',
      topic,
      timestamp: new Date(),
    });

    res.status(200).json({ success: true, data: explanation });
  } catch (error) {
    res.status(500).json({ error: 'Error explaining topic' });
  }
};

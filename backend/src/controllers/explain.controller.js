const openaiService = require('../services/openai.service');

async function explainTopic(req, res, next) {
  try {
    const { topic, audience = 'student', type = 'concise' } = req.body || {};

    if (!topic || typeof topic !== 'string') {
      return res.status(400).json({ success: false, error: { message: '`topic` is required and must be a string' } });
    }

    const promptMeta = { topic, audience, type };

    const response = await openaiService.explainTopic(promptMeta);

    return res.json({ success: true, data: response });
  } catch (err) {
    next(err);
  }
}

module.exports = { explainTopic };

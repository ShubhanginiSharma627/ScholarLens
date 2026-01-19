const openaiService = require('../services/openai.service');

async function generatePlan(req, res, next) {
  try {
    const { topic, audience = 'general', length = 'short', constraints = '' } = req.body || {};

    if (!topic || typeof topic !== 'string') {
      return res.status(400).json({ success: false, error: { message: '`topic` is required and must be a string' } });
    }

    const promptMeta = {
      topic,
      audience,
      length,
      constraints,
    };

    const response = await openaiService.generatePlan(promptMeta);

    return res.json({ success: true, data: response });
  } catch (err) {
    next(err);
  }
}

module.exports = { generatePlan };

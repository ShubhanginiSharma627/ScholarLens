const { analyzeImage } = require('../services/vertexai.service');
const { socraticTutorPrompt } = require('../utils/promptUtils');
const firestore = require('@google-cloud/firestore');

const db = new firestore.Firestore();

exports.scanPhoto = async (req, res) => {
  try {
    let imageData;
    let mimeType = 'image/jpeg';

    if (req.file) {
      // Multipart upload
      const fs = require('fs');
      imageData = fs.readFileSync(req.file.path).toString('base64');
      mimeType = req.file.mimetype;
      fs.unlinkSync(req.file.path); // Cleanup
    } else if (req.body.image) {
      // Base64
      imageData = req.body.image;
      if (req.body.mimeType) mimeType = req.body.mimeType;
    } else {
      return res.status(400).json({ error: 'No image provided' });
    }

    const userPrompt = req.body.prompt || 'Analyze this image and explain any diagrams, math, or text.';
    const fullPrompt = socraticTutorPrompt(userPrompt, 'Image analysis');

    const analysis = await analyzeImage(imageData, fullPrompt, 'gemini-1.5-flash');

    // Log interaction
    await db.collection('interactions').add({
      type: 'vision',
      userId: req.body.userId || 'anonymous',
      prompt: userPrompt,
      timestamp: new Date(),
    });

    res.status(200).json({ analysis });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error processing image' });
  }
};
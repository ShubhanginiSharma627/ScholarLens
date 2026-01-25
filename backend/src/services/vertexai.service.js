const { VertexAI } = require('@google-cloud/vertexai');

let vertexAI;
try {
  vertexAI = new VertexAI({ project: process.env.GOOGLE_CLOUD_PROJECT || 'default-project', location: 'us-central1' });
} catch (error) {
  console.warn('VertexAI initialization failed:', error.message);
  vertexAI = null;
}

async function generateText(prompt, model = 'gemini-1.5-flash') {
  if (!vertexAI) throw new Error('VertexAI not initialized. Check GOOGLE_CLOUD_PROJECT.');
  const generativeModel = vertexAI.getGenerativeModel({ model });

  const result = await generativeModel.generateContent(prompt);
  const response = await result.response;
  return response.text();
}

async function analyzeImage(imageData, prompt, model = 'gemini-1.5-flash') {
  if (!vertexAI) throw new Error('VertexAI not initialized. Check GOOGLE_CLOUD_PROJECT.');
  const generativeModel = vertexAI.getGenerativeModel({ model });

  const image = {
    inlineData: {
      mimeType: 'image/jpeg', // Adjust based on image type
      data: imageData,
    },
  };

  const result = await generativeModel.generateContent([prompt, image]);
  const response = await result.response;
  return response.text();
}

async function analyzeDocument(fileUri, prompt, model = 'gemini-1.5-pro') {
  if (!vertexAI) throw new Error('VertexAI not initialized. Check GOOGLE_CLOUD_PROJECT.');
  const generativeModel = vertexAI.getGenerativeModel({ model });

  const filePart = {
    fileData: {
      mimeType: 'application/pdf',
      fileUri,
    },
  };

  const result = await generativeModel.generateContent([prompt, filePart]);
  const response = await result.response;
  return response.text();
}

module.exports = { generateText, analyzeImage, analyzeDocument };
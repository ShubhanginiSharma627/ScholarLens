const { VertexAI } = require('@google-cloud/vertexai');

// Available AI models with their characteristics
const MODELS = {
  GEMINI_FLASH: {
    name: 'gemini-1.5-flash',
    speed: 'fast',
    cost: 'low',
    bestFor: ['quick_explanation', 'image_analysis', 'basic_chat']
  },
  GEMINI_PRO: {
    name: 'gemini-1.5-pro',
    speed: 'medium',
    cost: 'medium',
    bestFor: ['detailed_analysis', 'long_context', 'document_processing']
  },
  GEMMA_2B: {
    name: 'gemma-2b-it',
    speed: 'very_fast',
    cost: 'very_low',
    bestFor: ['quick_explanation', 'simple_qa', 'lightweight_tasks']
  },
  GEMMA_7B: {
    name: 'gemma-7b-it',
    speed: 'fast',
    cost: 'low',
    bestFor: ['flashcard_generation', 'concept_explanation', 'quiz_questions']
  },
  GEMMA_27B: {
    name: 'gemma-27b-it',
    speed: 'medium',
    cost: 'medium',
    bestFor: ['quiz_creation', 'study_plan_generation', 'complex_analysis']
  }
};

let vertexAI;
try {
  vertexAI = new VertexAI({ project: process.env.GOOGLE_CLOUD_PROJECT || 'default-project', location: 'us-central1' });
} catch (error) {
  console.warn('VertexAI initialization failed:', error.message);
  vertexAI = null;
}

// Intelligent model selection based on task type and complexity
function selectOptimalModel(taskType, complexity = 'medium') {
  const complexityMap = {
    simple: ['GEMMA_2B', 'GEMINI_FLASH'],
    medium: ['GEMMA_7B', 'GEMINI_FLASH'],
    complex: ['GEMMA_27B', 'GEMINI_PRO']
  };

  const modelKey = complexityMap[complexity]?.[0] || 'GEMINI_FLASH';
  return MODELS[modelKey].name;
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

// Batch processing for multiple requests
async function batchProcess(prompts, model = 'gemini-1.5-flash') {
  if (!vertexAI) throw new Error('VertexAI not initialized.');
  const generativeModel = vertexAI.getGenerativeModel({ model });

  const results = await Promise.all(
    prompts.map(prompt => generativeModel.generateContent(prompt))
  );

  return results.map(r => r.response.text());
}

module.exports = {
  generateText,
  analyzeImage,
  analyzeDocument,
  batchProcess,
  selectOptimalModel,
  MODELS
};
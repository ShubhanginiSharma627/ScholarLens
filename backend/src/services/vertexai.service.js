const { VertexAI } = require('@google-cloud/vertexai');
const winston = require('winston');
const promptService = require('./prompt.service');

// Configure logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/ai-service.log' })
  ]
});

// AI Models Configuration
const MODELS = {
  GEMINI_FLASH: process.env.DEFAULT_TEXT_MODEL || 'gemini-1.5-flash',
  GEMINI_PRO: process.env.DEFAULT_VISION_MODEL || 'gemini-1.5-pro',
  GEMINI_PRO_VISION: 'gemini-1.5-pro-vision',
  GEMMA_2B: process.env.GEMMA_2B_MODEL || 'gemma-2b-it',
  GEMMA_7B: process.env.GEMMA_7B_MODEL || 'gemma-7b-it',
  GEMMA_27B: process.env.GEMMA_27B_MODEL || 'gemma-27b-it'
};

let vertexAI;
try {
  vertexAI = new VertexAI({ 
    project: process.env.GOOGLE_CLOUD_PROJECT || 'default-project', 
    location: process.env.VERTEX_AI_LOCATION || 'us-central1' 
  });
  logger.info('VertexAI initialized successfully');
} catch (error) {
  logger.error('VertexAI initialization failed:', error.message);
  vertexAI = null;
}

// Model selection based on task complexity and requirements
function selectOptimalModel(taskType, complexity = 'medium') {
  const modelMap = {
    'quick_explanation': complexity === 'low' ? MODELS.GEMMA_2B : MODELS.GEMINI_FLASH,
    'detailed_analysis': MODELS.GEMINI_PRO,
    'flashcard_generation': MODELS.GEMMA_7B,
    'quiz_creation': MODELS.GEMMA_27B,
    'chat_response': MODELS.GEMINI_FLASH,
    'image_analysis': MODELS.GEMINI_PRO_VISION,
    'document_analysis': MODELS.GEMINI_PRO,
    'study_plan': MODELS.GEMMA_27B,
    'concept_explanation': MODELS.GEMMA_7B
  };
  
  return modelMap[taskType] || MODELS.GEMINI_FLASH;
}

async function generateText(prompt, taskType = 'general', complexity = 'medium', options = {}) {
  if (!vertexAI) throw new Error('VertexAI not initialized. Check GOOGLE_CLOUD_PROJECT.');
  
  const model = options.model || selectOptimalModel(taskType, complexity);
  const generativeModel = vertexAI.getGenerativeModel({ model });

  try {
    logger.info(`Generating text with model: ${model}, task: ${taskType}`);
    
    const generationConfig = {
      temperature: options.temperature || 0.7,
      topP: options.topP || 0.8,
      topK: options.topK || 40,
      maxOutputTokens: options.maxTokens || 2048,
    };

    const result = await generativeModel.generateContent({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig
    });
    
    const response = await result.response;
    const text = response.text();
    
    logger.info(`Text generation successful, length: ${text.length}`);
    return text;
  } catch (error) {
    logger.error(`Text generation failed: ${error.message}`);
    throw error;
  }
}

async function analyzeImage(imageData, prompt, taskType = 'image_analysis', options = {}) {
  if (!vertexAI) throw new Error('VertexAI not initialized. Check GOOGLE_CLOUD_PROJECT.');
  
  const model = options.model || selectOptimalModel(taskType);
  const generativeModel = vertexAI.getGenerativeModel({ model });

  try {
    logger.info(`Analyzing image with model: ${model}`);
    
    const image = {
      inlineData: {
        mimeType: options.mimeType || 'image/jpeg',
        data: imageData,
      },
    };

    const result = await generativeModel.generateContent([prompt, image]);
    const response = await result.response;
    const text = response.text();
    
    logger.info(`Image analysis successful, response length: ${text.length}`);
    return text;
  } catch (error) {
    logger.error(`Image analysis failed: ${error.message}`);
    throw error;
  }
}

async function analyzeDocument(fileUri, prompt, taskType = 'document_analysis', options = {}) {
  if (!vertexAI) throw new Error('VertexAI not initialized. Check GOOGLE_CLOUD_PROJECT.');
  
  const model = options.model || selectOptimalModel(taskType);
  const generativeModel = vertexAI.getGenerativeModel({ model });

  try {
    logger.info(`Analyzing document with model: ${model}, URI: ${fileUri}`);
    
    const filePart = {
      fileData: {
        mimeType: options.mimeType || 'application/pdf',
        fileUri,
      },
    };

    const result = await generativeModel.generateContent([prompt, filePart]);
    const response = await result.response;
    const text = response.text();
    
    logger.info(`Document analysis successful, response length: ${text.length}`);
    return text;
  } catch (error) {
    logger.error(`Document analysis failed: ${error.message}`);
    throw error;
  }
}

// Batch processing for multiple requests
async function batchGenerate(requests) {
  if (!vertexAI) throw new Error('VertexAI not initialized. Check GOOGLE_CLOUD_PROJECT.');
  
  try {
    logger.info(`Processing batch of ${requests.length} requests`);
    
    const promises = requests.map(async (request) => {
      const { prompt, taskType, complexity, options = {} } = request;
      return await generateText(prompt, taskType, complexity, options);
    });
    
    const results = await Promise.allSettled(promises);
    
    const successful = results.filter(r => r.status === 'fulfilled').length;
    logger.info(`Batch processing completed: ${successful}/${requests.length} successful`);
    
    return results.map(result => ({
      success: result.status === 'fulfilled',
      data: result.status === 'fulfilled' ? result.value : null,
      error: result.status === 'rejected' ? result.reason.message : null
    }));
  } catch (error) {
    logger.error(`Batch processing failed: ${error.message}`);
    throw error;
  }
}

// Generate flashcards using optimized model and prompt templates
async function generateFlashcards(topic, count = 5, difficulty = 'medium', options = {}) {
  try {
    const prompt = await promptService.getFlashcardPrompt({
      topic,
      count,
      difficulty,
      context: options.context,
      tags: options.tags
    });
    
    return await generateText(prompt, 'flashcard_generation', difficulty, options);
  } catch (error) {
    logger.error('Flashcard generation failed:', error.message);
    // Fallback to simple prompt if prompt service fails
    const fallbackPrompt = `Create ${count} flashcards for the topic: ${topic}. 
    Difficulty level: ${difficulty}
    
    Return valid JSON with flashcards array containing question, answer, difficulty, and tags fields.`;
    
    return await generateText(fallbackPrompt, 'flashcard_generation', difficulty, options);
  }
}

// Generate quiz questions
async function generateQuizQuestions(topic, count = 5, type = 'multiple_choice', options = {}) {
  try {
    // Use tutor chat prompt for quiz generation
    const prompt = await promptService.getTutorChatPrompt({
      message: `Create ${count} ${type} quiz questions for the topic: ${topic}`,
      session_type: 'exam_prep',
      subject: options.subject,
      student_level: options.difficulty || 'intermediate'
    });
    
    return await generateText(prompt, 'quiz_creation', 'high', options);
  } catch (error) {
    logger.error('Quiz generation failed:', error.message);
    // Fallback to simple prompt
    const fallbackPrompt = `Create ${count} ${type} quiz questions for the topic: ${topic}.
    
    For multiple choice questions, provide 4 options (A, B, C, D) with one correct answer.
    For true/false questions, provide the statement and correct answer.
    For short answer questions, provide the question and expected answer.
    
    Return valid JSON format.`;
    
    return await generateText(fallbackPrompt, 'quiz_creation', 'high', options);
  }
}

// Get available models
function getAvailableModels() {
  return {
    models: MODELS,
    taskTypes: [
      'quick_explanation',
      'detailed_analysis', 
      'flashcard_generation',
      'quiz_creation',
      'chat_response',
      'image_analysis',
      'document_analysis',
      'study_plan',
      'concept_explanation',
      'syllabus_analysis',
      'tutor_chat'
    ],
    complexityLevels: ['low', 'medium', 'high']
  };
}

// Generate topic explanation using prompt templates
async function generateExplanation(topic, options = {}) {
  try {
    const prompt = await promptService.getExplanationPrompt({
      topic,
      audience: options.audience || 'student',
      type: options.type || 'detailed',
      syllabus_context: options.context,
      variation: options.variation
    });
    
    return await generateText(prompt, 'concept_explanation', options.complexity || 'medium', options);
  } catch (error) {
    logger.error('Explanation generation failed:', error.message);
    throw error;
  }
}

// Generate study plan using prompt templates
async function generateStudyPlan(subjects, options = {}) {
  try {
    const prompt = await promptService.getStudyPlanningPrompt({
      subjects,
      exam_dates: options.examDates,
      available_time: options.availableTime,
      current_level: options.currentLevel || 'intermediate',
      study_preferences: options.studyPreferences,
      goals: options.goals,
      constraints: options.constraints
    });
    
    return await generateText(prompt, 'study_plan', 'high', options);
  } catch (error) {
    logger.error('Study plan generation failed:', error.message);
    throw error;
  }
}

// Generate revision plan using prompt templates
async function generateRevisionPlan(topic, options = {}) {
  try {
    const prompt = await promptService.getRevisionPlanPrompt({
      topic,
      audience: options.audience || 'student',
      length: options.length || 'comprehensive',
      constraints: options.constraints
    });
    
    return await generateText(prompt, 'study_plan', 'high', options);
  } catch (error) {
    logger.error('Revision plan generation failed:', error.message);
    throw error;
  }
}

// Generate tutor chat response using prompt templates
async function generateTutorResponse(message, options = {}) {
  try {
    const prompt = await promptService.getTutorChatPrompt({
      message,
      subject: options.subject,
      student_level: options.studentLevel,
      conversation_history: options.conversationHistory,
      learning_goals: options.learningGoals,
      session_type: options.sessionType || 'general_chat'
    });
    
    return await generateText(prompt, 'chat_response', 'medium', options);
  } catch (error) {
    logger.error('Tutor response generation failed:', error.message);
    throw error;
  }
}

// Analyze syllabus using prompt templates
async function analyzeSyllabus(syllabusContent, options = {}) {
  try {
    const prompt = await promptService.getSyllabusAnalysisPrompt({
      syllabus_content: syllabusContent,
      course_level: options.courseLevel,
      subject_area: options.subjectArea,
      analysis_type: options.analysisType || 'structure_extraction',
      semester_length: options.semesterLength
    });
    
    return await generateText(prompt, 'document_analysis', 'high', options);
  } catch (error) {
    logger.error('Syllabus analysis failed:', error.message);
    throw error;
  }
}

// Enhanced image analysis with prompt templates
async function analyzeImageWithPrompt(imageData, options = {}) {
  try {
    const prompt = await promptService.getImageAnalysisPrompt({
      analysis_type: options.analysisType || 'general',
      subject: options.subject,
      language: options.language || 'English',
      difficulty: options.difficulty
    });
    
    return await analyzeImage(imageData, prompt, 'image_analysis', options);
  } catch (error) {
    logger.error('Enhanced image analysis failed:', error.message);
    throw error;
  }
}

module.exports = { 
  generateText, 
  analyzeImage, 
  analyzeDocument,
  batchGenerate,
  generateFlashcards,
  generateQuizQuestions,
  generateExplanation,
  generateStudyPlan,
  generateRevisionPlan,
  generateTutorResponse,
  analyzeSyllabus,
  analyzeImageWithPrompt,
  selectOptimalModel,
  getAvailableModels,
  MODELS
};
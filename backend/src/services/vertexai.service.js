const { VertexAI } = require('@google-cloud/vertexai');
const winston = require('winston');
const promptService = require('./prompt.service');
function extractText(response) {
  try {
    const text =
      response?.candidates?.[0]?.content?.parts
        ?.map(p => p.text)
        ?.join(' ')
        ?.trim() || '';

    logger.debug(`Extracted text length: ${text.length}`);

    if (!text) {
      logger.warn('Empty text extracted from AI response');
      logger.debug('Full response:', JSON.stringify(response, null, 2));
    }

    return text;
  } catch (error) {
    logger.error('Error extracting text:', error.message);
    return '';
  }
}

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
  GEMINI_TEXT: process.env.DEFAULT_TEXT_MODEL || 'gemini-1.5-pro',
  GEMINI_VISION: process.env.DEFAULT_VISION_MODEL || 'gemini-1.5-pro',
  GEMINI_PRO: process.env.DEFAULT_DOCUMENT_MODEL || 'gemini-1.5-pro',
  GEMINI_FLASH: process.env.DEFAULT_TEXT_MODEL || 'gemini-1.5-pro',
  GEMMA_2B: process.env.GEMMA_2B_MODEL || 'gemini-1.5-pro',
};

// Log model configuration for debugging
console.log('AI Models Configuration:', MODELS);

// Task type to prompt type mapping
const TASK_TO_PROMPT_MAP = {
  'quick_explanation': 'EXPLANATION',
  'detailed_analysis': 'EXPLANATION', 
  'flashcard_generation': 'FLASHCARD_GENERATION',
  'quiz_creation': 'TUTOR_CHAT',
  'chat_response': 'TUTOR_CHAT',
  'image_analysis': 'IMAGE_ANALYSIS',
  'document_analysis': 'SYLLABUS_ANALYSIS',
  'study_plan': 'STUDY_PLANNING',
  'concept_explanation': 'EXPLANATION',
  'syllabus_analysis': 'SYLLABUS_ANALYSIS',
  'tutor_chat': 'TUTOR_CHAT',
  'general': 'TUTOR_CHAT'
};

/**
 * Get system prompt for a specific task type
 * @param {string} taskType - The task type to get system prompt for
 * @returns {Promise<string|null>} - The system prompt or null if not found
 */
async function getSystemPromptForTask(taskType) {
  try {
    const promptType = TASK_TO_PROMPT_MAP[taskType];
    if (!promptType) {
      logger.debug(`No system prompt mapping found for task type: ${taskType}`);
      return null;
    }
    
    const systemPrompt = await promptService.loadPrompt(promptType);
    logger.debug(`Loaded system prompt for task type: ${taskType} -> ${promptType}`);
    return systemPrompt;
  } catch (error) {
    logger.warn(`Failed to load system prompt for task type ${taskType}:`, error.message);
    return null;
  }
}


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
    'flashcard_generation': MODELS.GEMMA_2B,
    'quiz_creation': MODELS.GEMMA_2B,
    'chat_response': MODELS.GEMINI_FLASH,
    'image_analysis': MODELS.GEMINI_VISION,
    'document_analysis': MODELS.GEMINI_PRO,
    'study_plan': MODELS.GEMMA_2B,
    'concept_explanation': MODELS.GEMMA_2B,
    'general': MODELS.GEMINI_FLASH
  };
  
  let selectedModel = modelMap[taskType] || MODELS.GEMINI_FLASH;
  
  // Ensure we have a valid model - double fallback
  if (!selectedModel || selectedModel.trim() === '') {
    selectedModel = 'gemini-1.5-pro'; // Hard-coded fallback
    logger.warn(`Using hard-coded fallback model for taskType: ${taskType}`);
  }
  
  // Log model selection for debugging
  logger.info(`Model selection - TaskType: ${taskType}, Complexity: ${complexity}, Selected: ${selectedModel}`);
  
  return selectedModel;
}

async function generateText(prompt, taskType = 'general', complexity = 'medium', options = {}) {
  if (!vertexAI) throw new Error('VertexAI not initialized. Check GOOGLE_CLOUD_PROJECT.');
  
  let model = options.model || selectOptimalModel(taskType, complexity);
  
  // Validate model parameter and provide fallback
  if (!model || model.trim() === '') {
    logger.error(`Empty model parameter for taskType: ${taskType}, complexity: ${complexity}`);
    model = 'gemini-1.5-pro'; // Hard-coded fallback
    logger.warn(`Using fallback model: ${model}`);
  }
  
  logger.info(`Generating text with model: ${model}, task: ${taskType}`);

  try {
    const generationConfig = {
      temperature: options.temperature || 0.7,
      topP: options.topP || 0.8,
      topK: options.topK || 40,
      maxOutputTokens: options.maxTokens || 2048,
    };

    // Get system prompt based on task type
    const systemPrompt = await getSystemPromptForTask(taskType);
    logger.debug(`System prompt loaded: ${systemPrompt ? 'Yes' : 'No'}`);
    
    // Configure model with system instruction if available
    const modelConfig = { model };
    if (systemPrompt) {
      modelConfig.systemInstruction = {
        parts: [{ text: systemPrompt }]
      };
      logger.debug(`System instruction set for model`);
    }
    
    const generativeModel = vertexAI.getGenerativeModel(modelConfig);

    logger.debug(`User prompt: ${prompt.substring(0, 200)}...`);
    
    const result = await generativeModel.generateContent({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig
    });
    
    logger.debug(`Generation result received`);
    
    const response = await result.response;
    logger.info(`Generation result received`, response);

    const text = extractText(response);
    
    logger.info(`Text generation successful, length: ${text.length}`);
    
    if (text.length === 0) {
      logger.error('Generated text is empty');
      logger.debug('Full response object:', JSON.stringify(response, null, 2));
      throw new Error('Generated response is empty');
    }
    
    return text;
  } catch (error) {
    logger.error(`Text generation failed: ${error.message}`);
    logger.error('Stack trace:', error.stack);
    
    // Provide a fallback response for tutor chat to prevent "no generated response" error
    if (taskType === 'chat_response' || taskType === 'tutor_chat') {
      logger.warn('Providing fallback tutor response due to generation failure');
      return "I apologize, but I'm experiencing technical difficulties right now. Please try asking your question again, or contact support if the issue persists.";
    }
    
    throw error;
  }
}

async function analyzeImage(imageData, prompt, taskType = 'image_analysis', options = {}) {
  if (!vertexAI) throw new Error('VertexAI not initialized. Check GOOGLE_CLOUD_PROJECT.');
  
  const model = options.model || selectOptimalModel(taskType);

  try {
    logger.info(`Analyzing image with model: ${model}`);
    
    const image = {
      inlineData: {
        mimeType: options.mimeType || 'image/jpeg',
        data: imageData,
      },
    };

    // Get system prompt for image analysis
    const systemPrompt = await getSystemPromptForTask(taskType);
    
    // Configure model with system instruction if available
    const modelConfig = { model };
    if (systemPrompt) {
      modelConfig.systemInstruction = {
        parts: [{ text: systemPrompt }]
      };
    }
    
    const generativeModel = vertexAI.getGenerativeModel(modelConfig);

    const result = await generativeModel.generateContent({
      contents: [{ role: 'user', parts: [{ text: prompt }, image] }]
    });
    
    const response = await result.response;
    const text = extractText(response);
    
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

  try {
    logger.info(`Analyzing document with model: ${model}, URI: ${fileUri}`);
    
    const filePart = {
      fileData: {
        mimeType: options.mimeType || 'application/pdf',
        fileUri,
      },
    };

    // Get system prompt for document analysis
    const systemPrompt = await getSystemPromptForTask(taskType);
    
    // Configure model with system instruction if available
    const modelConfig = { model };
    if (systemPrompt) {
      modelConfig.systemInstruction = {
        parts: [{ text: systemPrompt }]
      };
    }
    
    const generativeModel = vertexAI.getGenerativeModel(modelConfig);

    const result = await generativeModel.generateContent({
      contents: [{ role: 'user', parts: [{ text: prompt }, filePart] }]
    });
    
    const response = await result.response;
    const text = extractText(response);
    
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
    // Build user prompt with parameters (the system prompt will be added automatically)
    const userPrompt = `Create ${count} flashcards for the topic: ${topic}. 
    Difficulty level: ${difficulty}
    ${options.context ? `Context: ${options.context}` : ''}
    ${options.tags ? `Tags: ${options.tags.join(', ')}` : ''}
    
    Return the response as valid JSON in this exact format:
    {
      "flashcards": [
        {
          "question": "Your question here",
          "answer": "Your answer here",
          "difficulty": "${difficulty}",
          "tags": ["${topic}"],
          "category": "Main category"
        }
      ]
    }`;
    
    logger.info(`Generating flashcards for topic: ${topic}, count: ${count}, difficulty: ${difficulty}`);
    
    const result = await generateText(userPrompt, 'flashcard_generation', difficulty, options);
    
    logger.info(`Flashcard generation result length: ${result.length}`);
    logger.debug(`Flashcard generation result: ${result.substring(0, 500)}...`);
    
    return result;
  } catch (error) {
    logger.error('Flashcard generation failed:', error.message);
    // Fallback to simple prompt if system prompt fails
    const fallbackPrompt = `Create ${count} flashcards for the topic: ${topic}. 
    Difficulty level: ${difficulty}
    
    Return valid JSON with flashcards array containing question, answer, difficulty, and tags fields.
    
    Format:
    {
      "flashcards": [
        {"question": "Q1", "answer": "A1", "difficulty": "${difficulty}", "tags": ["${topic}"]},
        {"question": "Q2", "answer": "A2", "difficulty": "${difficulty}", "tags": ["${topic}"]}
      ]
    }`;
    
    logger.info('Using fallback prompt for flashcard generation');
    return await generateText(fallbackPrompt, 'flashcard_generation', difficulty, options);
  }
}

// Generate quiz questions
async function generateQuizQuestions(topic, count = 5, type = 'multiple_choice', options = {}) {
  try {
    // Build user prompt with parameters (the system prompt will be added automatically)
    const userPrompt = `Create ${count} ${type} quiz questions for the topic: ${topic}.
    ${options.subject ? `Subject: ${options.subject}` : ''}
    ${options.difficulty ? `Difficulty: ${options.difficulty}` : ''}
    
    For multiple choice questions, provide 4 options (A, B, C, D) with one correct answer.
    For true/false questions, provide the statement and correct answer.
    For short answer questions, provide the question and expected answer.`;
    
    return await generateText(userPrompt, 'quiz_creation', 'high', options);
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
    // Build user prompt with parameters (the system prompt will be added automatically)
    const userPrompt = `Explain the topic: ${topic}
    ${options.audience ? `Audience: ${options.audience}` : ''}
    ${options.type ? `Type: ${options.type}` : ''}
    ${options.context ? `Context: ${options.context}` : ''}
    ${options.variation ? `Variation: ${options.variation}` : ''}`;
    
    return await generateText(userPrompt, 'concept_explanation', options.complexity || 'medium', options);
  } catch (error) {
    logger.error('Explanation generation failed:', error.message);
    throw error;
  }
}

// Generate study plan using prompt templates
async function generateStudyPlan(subjects, options = {}) {
  try {
    // Build user prompt with parameters (the system prompt will be added automatically)
    const userPrompt = `Create a study plan for the following subjects: ${Array.isArray(subjects) ? subjects.join(', ') : subjects}
    ${options.examDates ? `Exam dates: ${JSON.stringify(options.examDates)}` : ''}
    ${options.availableTime ? `Available time: ${options.availableTime}` : ''}
    ${options.currentLevel ? `Current level: ${options.currentLevel}` : ''}
    ${options.studyPreferences ? `Study preferences: ${JSON.stringify(options.studyPreferences)}` : ''}
    ${options.goals ? `Goals: ${JSON.stringify(options.goals)}` : ''}
    ${options.constraints ? `Constraints: ${JSON.stringify(options.constraints)}` : ''}`;
    
    return await generateText(userPrompt, 'study_plan', 'high', options);
  } catch (error) {
    logger.error('Study plan generation failed:', error.message);
    throw error;
  }
}

// Generate revision plan using prompt templates
async function generateRevisionPlan(topic, options = {}) {
  try {
    // Build user prompt with parameters (the system prompt will be added automatically)
    const userPrompt = `Create a revision plan for the topic: ${topic}
    ${options.audience ? `Audience: ${options.audience}` : ''}
    ${options.length ? `Length: ${options.length}` : ''}
    ${options.constraints ? `Constraints: ${JSON.stringify(options.constraints)}` : ''}`;
    
    return await generateText(userPrompt, 'study_plan', 'high', options);
  } catch (error) {
    logger.error('Revision plan generation failed:', error.message);
    throw error;
  }
}

// Generate tutor chat response using prompt templates
async function generateTutorResponse(message, options = {}) {
  try {
    logger.info(`Generating tutor response for message: "${message.substring(0, 50)}..."`);
    logger.info(`Options:`, options);
    
    // Build user prompt with parameters (the system prompt will be added automatically)
    const userPrompt = `Student message: ${message}
    ${options.subject ? `Subject: ${options.subject}` : ''}
    ${options.studentLevel ? `Student level: ${options.studentLevel}` : ''}
    ${options.conversationHistory ? `Conversation history: ${JSON.stringify(options.conversationHistory)}` : ''}
    ${options.learningGoals ? `Learning goals: ${JSON.stringify(options.learningGoals)}` : ''}
    ${options.sessionType ? `Session type: ${options.sessionType}` : ''}`;
    
    logger.info(`Generated user prompt length: ${userPrompt.length}`);
    
    return await generateText(userPrompt, 'chat_response', 'medium', options);
  } catch (error) {
    logger.error('Tutor response generation failed:', error.message);
    logger.error('Stack trace:', error.stack);
    throw error;
  }
}

// Analyze syllabus using prompt templates
async function analyzeSyllabus(syllabusContent, options = {}) {
  try {
    // Build user prompt with parameters (the system prompt will be added automatically)
    const userPrompt = `Analyze the following syllabus content: ${syllabusContent}
    ${options.courseLevel ? `Course level: ${options.courseLevel}` : ''}
    ${options.subjectArea ? `Subject area: ${options.subjectArea}` : ''}
    ${options.analysisType ? `Analysis type: ${options.analysisType}` : ''}
    ${options.semesterLength ? `Semester length: ${options.semesterLength}` : ''}`;
    
    return await generateText(userPrompt, 'document_analysis', 'high', options);
  } catch (error) {
    logger.error('Syllabus analysis failed:', error.message);
    throw error;
  }
}

// Enhanced image analysis with prompt templates
async function analyzeImageWithPrompt(imageData, options = {}) {
  try {
    // Build user prompt with parameters (the system prompt will be added automatically)
    const userPrompt = `Analyze this image with the following parameters:
    ${options.analysisType ? `Analysis type: ${options.analysisType}` : ''}
    ${options.subject ? `Subject: ${options.subject}` : ''}
    ${options.language ? `Language: ${options.language}` : ''}
    ${options.difficulty ? `Difficulty: ${options.difficulty}` : ''}`;
    
    return await analyzeImage(imageData, userPrompt, 'image_analysis', options);
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
  getSystemPromptForTask,
  MODELS
};
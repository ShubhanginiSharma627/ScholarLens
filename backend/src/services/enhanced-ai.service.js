const vertexaiService = require('./vertexai.service');
const scienceqaService = require('./scienceqa.service');
const { createLogger, logPerformance } = require('../config/logging.config');

// Create service-specific logger
const logger = createLogger('enhanced-ai-service');

/**
 * Enhanced explanation generation with ScienceQA cache
 * @param {string} topic - Topic to explain
 * @param {Object} options - Generation options
 * @returns {Promise<string>} - Generated explanation
 */
async function generateExplanationWithCache(topic, options = {}) {
  try {
    logger.info(`Generating explanation for topic: "${topic}" with cache layer`);
    
    // Step 1: Try to get context from ScienceQA
    const cachedContext = await scienceqaService.retrieveContext(topic, options.subject);
    
    if (cachedContext) {
      logger.info('Using ScienceQA cached context for explanation');
      
      // Enhance the prompt with cached context
      const enhancedPrompt = `Using the following educational context, provide a comprehensive explanation of the topic: ${topic}

Educational Context:
${cachedContext.context}

Topic: ${cachedContext.topic}
Confidence: ${cachedContext.confidence}

Please provide a detailed explanation that builds upon this context while ensuring accuracy and educational value.

${options.audience ? `Target Audience: ${options.audience}` : ''}
${options.type ? `Explanation Type: ${options.type}` : ''}
${options.variation ? `Variation: ${options.variation}` : ''}`;

      const explanation = await vertexaiService.generateText(
        enhancedPrompt, 
        'concept_explanation', 
        options.complexity || 'medium', 
        {
          ...options,
          context: cachedContext.context
        }
      );

      return {
        explanation,
        source: 'enhanced_with_cache',
        cacheHit: true,
        cachedTopic: cachedContext.topic,
        confidence: cachedContext.confidence
      };
    }

    // Step 2: Fallback to standard VertexAI
    logger.info('No suitable cache found, using standard VertexAI');
    const explanation = await vertexaiService.generateExplanation(topic, options);
    
    return {
      explanation,
      source: 'vertexai_only',
      cacheHit: false
    };

  } catch (error) {
    logger.error('Enhanced explanation generation failed:', error.message);
    throw error;
  }
}

/**
 * Enhanced quiz generation with ScienceQA cache
 * @param {string} topic - Topic for quiz
 * @param {number} count - Number of questions
 * @param {string} type - Question type
 * @param {Object} options - Generation options
 * @returns {Promise<Object>} - Generated quiz
 */
async function generateQuizWithCache(topic, count = 5, type = 'multiple_choice', options = {}) {
  try {
    logger.info(`Generating quiz for topic: "${topic}" with cache layer`);
    
    // Step 1: Try to get questions from ScienceQA
    const cachedQuestions = await scienceqaService.generateQuiz(
      topic, 
      options.difficulty || 'Medium', 
      count
    );
    
    if (cachedQuestions && cachedQuestions.length > 0) {
      logger.info(`Using ${cachedQuestions.length} cached questions from ScienceQA`);
      
      // If we have enough cached questions, return them
      if (cachedQuestions.length >= count) {
        return {
          quiz: cachedQuestions.slice(0, count),
          source: 'scienceqa_cache',
          cacheHit: true,
          totalQuestions: cachedQuestions.length
        };
      }
      
      // If we have some but not enough, supplement with VertexAI
      const remainingCount = count - cachedQuestions.length;
      logger.info(`Supplementing ${remainingCount} questions with VertexAI`);
      
      const aiQuiz = await vertexaiService.generateQuizQuestions(
        topic, 
        remainingCount, 
        type, 
        options
      );
      
      // Parse AI response if it's a string
      let aiQuestions = [];
      if (typeof aiQuiz === 'string') {
        try {
          const parsed = JSON.parse(aiQuiz);
          aiQuestions = parsed.questions || parsed.quiz || [];
        } catch (e) {
          logger.warn('Failed to parse AI quiz response');
        }
      }
      
      return {
        quiz: [...cachedQuestions, ...aiQuestions],
        source: 'hybrid_cache_ai',
        cacheHit: true,
        cachedQuestions: cachedQuestions.length,
        aiQuestions: aiQuestions.length
      };
    }

    // Step 2: Fallback to standard VertexAI
    logger.info('No suitable cached questions found, using standard VertexAI');
    const aiQuiz = await vertexaiService.generateQuizQuestions(topic, count, type, options);
    
    return {
      quiz: aiQuiz,
      source: 'vertexai_only',
      cacheHit: false
    };

  } catch (error) {
    logger.error('Enhanced quiz generation failed:', error.message);
    throw error;
  }
}

/**
 * Enhanced tutor response with context awareness
 * @param {string} message - Student message
 * @param {Object} options - Response options
 * @returns {Promise<Object>} - Generated response
 */
async function generateTutorResponseWithCache(message, options = {}) {
  const requestId = `enhanced_tutor_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  try {
    logger.info(`[${requestId}] Starting enhanced tutor response generation`, {
      messageLength: message.length,
      messagePreview: message.substring(0, 100),
      options: {
        subject: options.subject,
        studentLevel: options.studentLevel,
        sessionType: options.sessionType,
        hasConversationHistory: !!options.conversationHistory,
        hasLearningGoals: !!options.learningGoals
      }
    });
    
    // Step 1: Try to get relevant context from ScienceQA
    logger.info(`[${requestId}] Attempting to retrieve context from ScienceQA`);
    const startCacheTime = Date.now();
    
    let cachedContext = null;
    try {
      cachedContext = await scienceqaService.retrieveContext(message, options.subject);
      const cacheTime = Date.now() - startCacheTime;
      
      logger.info(`[${requestId}] ScienceQA context retrieval completed`, {
        duration: cacheTime,
        contextFound: !!cachedContext,
        contextTopic: cachedContext?.topic,
        contextConfidence: cachedContext?.confidence
      });
    } catch (cacheError) {
      const cacheTime = Date.now() - startCacheTime;
      logger.warn(`[${requestId}] ScienceQA context retrieval failed`, {
        duration: cacheTime,
        error: cacheError.message
      });
    }
    
    if (cachedContext) {
      logger.info(`[${requestId}] Using ScienceQA context for enhanced tutor response`, {
        topic: cachedContext.topic,
        confidence: cachedContext.confidence,
        contextLength: cachedContext.context?.length || 0
      });
      
      // Enhance the options with cached context
      const enhancedOptions = {
        ...options,
        context: cachedContext.context,
        relatedTopic: cachedContext.topic,
        confidence: cachedContext.confidence
      };
      
      const startGenTime = Date.now();
      const response = await vertexaiService.generateTutorResponse(message, enhancedOptions);
      const genTime = Date.now() - startGenTime;
      
      logger.info(`[${requestId}] Enhanced tutor response generated successfully`, {
        responseLength: response.length,
        generationTime: genTime,
        source: 'enhanced_with_cache',
        relatedTopic: cachedContext.topic
      });
      
      return {
        response,
        source: 'enhanced_with_cache',
        cacheHit: true,
        relatedTopic: cachedContext.topic,
        confidence: cachedContext.confidence
      };
    }

    // Step 2: Fallback to standard VertexAI
    logger.info(`[${requestId}] No suitable context found, using standard tutor response`);
    const startGenTime = Date.now();
    const response = await vertexaiService.generateTutorResponse(message, options);
    const genTime = Date.now() - startGenTime;
    
    logger.info(`[${requestId}] Standard tutor response generated successfully`, {
      responseLength: response.length,
      generationTime: genTime,
      source: 'vertexai_only'
    });
    
    return {
      response,
      source: 'vertexai_only',
      cacheHit: false
    };

  } catch (error) {
    logger.error(`[${requestId}] Enhanced tutor response generation failed`, {
      error: error.message,
      stack: error.stack,
      messageLength: message.length,
      options,
      errorCode: error.code,
      errorDetails: error.details
    });
    
    // Provide a fallback response to prevent complete failure
    logger.warn(`[${requestId}] Providing fallback response due to generation failure`);
    return {
      response: "I apologize, but I'm experiencing technical difficulties right now. Please try asking your question again, or contact support if the issue persists.",
      source: 'fallback_error',
      cacheHit: false,
      error: error.message
    };
  }
}

/**
 * Enhanced flashcard generation with context
 * @param {string} topic - Topic for flashcards
 * @param {number} count - Number of flashcards
 * @param {string} difficulty - Difficulty level
 * @param {Object} options - Generation options
 * @returns {Promise<Object>} - Generated flashcards
 */
async function generateFlashcardsWithCache(topic, count = 5, difficulty = 'medium', options = {}) {
  try {
    logger.info(`Generating flashcards for topic: "${topic}" with cache layer`);
    
    // Step 1: Try to get context from ScienceQA
    const cachedContext = await scienceqaService.retrieveContext(topic, options.subject);
    
    if (cachedContext) {
      logger.info('Using ScienceQA context for enhanced flashcard generation');
      
      // Enhance the options with cached context
      const enhancedOptions = {
        ...options,
        context: cachedContext.context,
        relatedTopic: cachedContext.topic
      };
      
      const flashcards = await vertexaiService.generateFlashcards(
        topic, 
        count, 
        difficulty, 
        enhancedOptions
      );
      
      return {
        flashcards,
        source: 'enhanced_with_cache',
        cacheHit: true,
        relatedTopic: cachedContext.topic,
        confidence: cachedContext.confidence
      };
    }

    // Step 2: Fallback to standard VertexAI
    logger.info('No suitable context found, using standard flashcard generation');
    const flashcards = await vertexaiService.generateFlashcards(topic, count, difficulty, options);
    
    return {
      flashcards,
      source: 'vertexai_only',
      cacheHit: false
    };

  } catch (error) {
    logger.error('Enhanced flashcard generation failed:', error.message);
    throw error;
  }
}

/**
 * Get enhanced AI service status
 * @returns {Promise<Object>}
 */
async function getEnhancedServiceStatus() {
  try {
    const vertexaiStatus = vertexaiService.getAvailableModels();
    const scienceqaStatus = await scienceqaService.getServiceStatus();
    
    return {
      vertexai: {
        available: true,
        models: vertexaiStatus.models,
        taskTypes: vertexaiStatus.taskTypes
      },
      scienceqa: scienceqaStatus,
      enhanced: {
        cacheEnabled: scienceqaStatus.enabled && scienceqaStatus.available,
        features: [
          'cached_explanations',
          'cached_quiz_generation',
          'cached_tutor_responses',
          'cached_flashcards',
          'hybrid_generation'
        ]
      }
    };
  } catch (error) {
    logger.error('Error getting enhanced service status:', error.message);
    throw error;
  }
}

// Export all original VertexAI functions plus enhanced ones
module.exports = {
  // Enhanced functions with cache
  generateExplanationWithCache,
  generateQuizWithCache,
  generateTutorResponseWithCache,
  generateFlashcardsWithCache,
  getEnhancedServiceStatus,
  
  // Original VertexAI functions (for backward compatibility)
  generateText: vertexaiService.generateText,
  analyzeImage: vertexaiService.analyzeImage,
  analyzeDocument: vertexaiService.analyzeDocument,
  batchGenerate: vertexaiService.batchGenerate,
  generateFlashcards: vertexaiService.generateFlashcards,
  generateQuizQuestions: vertexaiService.generateQuizQuestions,
  generateExplanation: vertexaiService.generateExplanation,
  generateStudyPlan: vertexaiService.generateStudyPlan,
  generateRevisionPlan: vertexaiService.generateRevisionPlan,
  generateTutorResponse: vertexaiService.generateTutorResponse,
  analyzeSyllabus: vertexaiService.analyzeSyllabus,
  analyzeImageWithPrompt: vertexaiService.analyzeImageWithPrompt,
  selectOptimalModel: vertexaiService.selectOptimalModel,
  getAvailableModels: vertexaiService.getAvailableModels,
  getSystemPromptForTask: vertexaiService.getSystemPromptForTask,
  MODELS: vertexaiService.MODELS,
  
  // ScienceQA functions
  scienceqa: scienceqaService
};
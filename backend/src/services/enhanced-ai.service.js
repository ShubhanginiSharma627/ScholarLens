const vertexaiService = require('./vertexai.service');
const scienceqaService = require('./scienceqa.service');
const { createLogger, logPerformance } = require('../config/logging.config');
const logger = createLogger('enhanced-ai-service');
async function generateExplanationWithCache(topic, options = {}) {
  try {
    logger.info(`Generating explanation for topic: "${topic}" with cache layer`);
    const cachedContext = await scienceqaService.retrieveContext(topic, options.subject);
    if (cachedContext) {
      logger.info('Using ScienceQA cached context for explanation');
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
async function generateQuizWithCache(topic, count = 5, type = 'multiple_choice', options = {}) {
  try {
    logger.info(`Generating quiz for topic: "${topic}" with cache layer`);
    const cachedQuestions = await scienceqaService.generateQuiz(
      topic, 
      options.difficulty || 'Medium', 
      count
    );
    if (cachedQuestions && cachedQuestions.length > 0) {
      logger.info(`Using ${cachedQuestions.length} cached questions from ScienceQA`);
      if (cachedQuestions.length >= count) {
        return {
          quiz: cachedQuestions.slice(0, count),
          source: 'scienceqa_cache',
          cacheHit: true,
          totalQuestions: cachedQuestions.length
        };
      }
      const remainingCount = count - cachedQuestions.length;
      logger.info(`Supplementing ${remainingCount} questions with VertexAI`);
      const aiQuiz = await vertexaiService.generateQuizQuestions(
        topic, 
        remainingCount, 
        type, 
        options
      );
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
    logger.warn(`[${requestId}] Providing fallback response due to generation failure`);
    return {
      response: "I apologize, but I'm experiencing technical difficulties right now. Please try asking your question again, or contact support if the issue persists.",
      source: 'fallback_error',
      cacheHit: false,
      error: error.message
    };
  }
}
async function generateFlashcardsWithCache(topic, count = 5, difficulty = 'medium', options = {}) {
  try {
    logger.info(`Generating flashcards for topic: "${topic}" with cache layer`);
    const cachedContext = await scienceqaService.retrieveContext(topic, options.subject);
    if (cachedContext) {
      logger.info('Using ScienceQA context for enhanced flashcard generation');
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
module.exports = {
  generateExplanationWithCache,
  generateQuizWithCache,
  generateTutorResponseWithCache,
  generateFlashcardsWithCache,
  getEnhancedServiceStatus,
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
  scienceqa: scienceqaService
};
const enhancedAiService = require('../services/enhanced-ai.service');
const firestore = require('@google-cloud/firestore');
const { createLogger, logBusiness, logPerformance } = require('../config/logging.config');
const db = new firestore.Firestore();
const logger = createLogger('enhanced-ai-controller');
const explainTopicWithCache = async (req, res) => {
  try {
    const { topic, audience, type, context, variation, subject } = req.body;
    const userId = req.user?.userId;
    if (!topic) {
      return res.status(400).json({
        success: false,
        error: { message: 'Topic is required' }
      });
    }
    const result = await enhancedAiService.generateExplanationWithCache(topic, {
      audience: audience || 'student',
      type: type || 'detailed',
      context,
      variation,
      subject
    });
    if (userId) {
      await db.collection('interactions').add({
        type: 'enhanced_topic_explanation',
        userId,
        topic,
        audience,
        explanationType: type,
        cacheHit: result.cacheHit,
        source: result.source,
        timestamp: new Date(),
      });
    }
    res.json({
      success: true,
      data: { 
        explanation: result.explanation,
        topic,
        type: type || 'detailed',
        cacheHit: result.cacheHit,
        source: result.source,
        ...(result.cachedTopic && { cachedTopic: result.cachedTopic }),
        ...(result.confidence && { confidence: result.confidence })
      }
    });
  } catch (error) {
    logger.error('Enhanced topic explanation error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to generate explanation' }
    });
  }
};
const createQuizQuestionsWithCache = async (req, res) => {
  try {
    const { topic, count, type, subject, difficulty } = req.body;
    const userId = req.user?.userId;
    if (!topic) {
      return res.status(400).json({
        success: false,
        error: { message: 'Topic is required' }
      });
    }
    const result = await enhancedAiService.generateQuizWithCache(
      topic, 
      count || 5, 
      type || 'multiple_choice', 
      {
        subject,
        difficulty
      }
    );
    if (userId) {
      await db.collection('interactions').add({
        type: 'enhanced_quiz_generation',
        userId,
        topic,
        questionCount: count || 5,
        questionType: type || 'multiple_choice',
        cacheHit: result.cacheHit,
        source: result.source,
        timestamp: new Date(),
      });
    }
    res.json({
      success: true,
      data: { 
        quiz: result.quiz,
        topic,
        questionCount: count || 5,
        questionType: type || 'multiple_choice',
        cacheHit: result.cacheHit,
        source: result.source,
        ...(result.cachedQuestions && { cachedQuestions: result.cachedQuestions }),
        ...(result.aiQuestions && { aiQuestions: result.aiQuestions })
      }
    });
  } catch (error) {
    logger.error('Enhanced quiz generation error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to generate quiz questions' }
    });
  }
};
const chatWithTutorWithCache = async (req, res) => {
  const requestId = `enhanced_chat_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  try {
    const { message, subject, studentLevel, conversationHistory, learningGoals, sessionType } = req.body;
    const userId = req.user?.userId;
    logger.info(`[${requestId}] Enhanced tutor chat request received`, {
      userId: userId || 'anonymous',
      messageLength: message?.length || 0,
      messagePreview: message?.substring(0, 50) || '',
      subject,
      studentLevel,
      sessionType: sessionType || 'general_chat',
      hasConversationHistory: !!conversationHistory,
      hasLearningGoals: !!learningGoals,
      requestHeaders: {
        userAgent: req.headers['user-agent'],
        contentType: req.headers['content-type']
      }
    });
    if (!message) {
      logger.warn(`[${requestId}] Missing message in request body`);
      return res.status(400).json({
        success: false,
        error: { message: 'Message is required' }
      });
    }
    const startTime = Date.now();
    try {
      const result = await enhancedAiService.generateTutorResponseWithCache(message, {
        subject,
        studentLevel,
        conversationHistory,
        learningGoals,
        sessionType: sessionType || 'general_chat'
      });
      const processingTime = Date.now() - startTime;
      logger.info(`[${requestId}] Enhanced tutor response generated`, {
        responseLength: result.response?.length || 0,
        processingTime,
        source: result.source,
        cacheHit: result.cacheHit,
        relatedTopic: result.relatedTopic,
        confidence: result.confidence,
        hasError: !!result.error
      });
      if (!result.response || result.response.trim() === '') {
        logger.error(`[${requestId}] Empty enhanced tutor response`, {
          processingTime,
          source: result.source,
          error: result.error
        });
        return res.status(500).json({
          success: false,
          error: { message: 'Failed to generate response. Please try again.' }
        });
      }
      if (userId) {
        try {
          await db.collection('chat_sessions').add({
            userId,
            userMessage: message,
            tutorResponse: result.response,
            subject,
            sessionType,
            cacheHit: result.cacheHit,
            source: result.source,
            relatedTopic: result.relatedTopic,
            confidence: result.confidence,
            processingTime,
            timestamp: new Date(),
          });
          logger.debug(`[${requestId}] Enhanced chat session logged to database`);
        } catch (dbError) {
          logger.error(`[${requestId}] Failed to log enhanced chat session`, {
            error: dbError.message,
            userId
          });
        }
      }
      res.json({
        success: true,
        data: { 
          response: result.response,
          sessionType: sessionType || 'general_chat',
          cacheHit: result.cacheHit,
          source: result.source,
          processingTime,
          ...(result.relatedTopic && { relatedTopic: result.relatedTopic }),
          ...(result.confidence && { confidence: result.confidence }),
          timestamp: new Date().toISOString()
        }
      });
    } catch (generationError) {
      const processingTime = Date.now() - startTime;
      logger.error(`[${requestId}] Enhanced tutor response generation failed`, {
        error: generationError.message,
        stack: generationError.stack,
        processingTime,
        messageLength: message.length,
        subject,
        studentLevel,
        sessionType,
        errorCode: generationError.code
      });
      let errorMessage = 'Failed to generate tutor response';
      let statusCode = 500;
      if (generationError.message.includes('BILLING_DISABLED')) {
        errorMessage = 'AI service is temporarily unavailable due to billing configuration.';
        statusCode = 503;
      } else if (generationError.message.includes('NOT_FOUND')) {
        errorMessage = 'AI model is temporarily unavailable. Please try again later.';
        statusCode = 503;
      } else if (generationError.message.includes('timeout')) {
        errorMessage = 'Request timed out. Please try again with a shorter message.';
        statusCode = 408;
      }
      return res.status(statusCode).json({
        success: false,
        error: { 
          message: errorMessage,
          code: generationError.code || 'ENHANCED_GENERATION_ERROR',
          processingTime
        }
      });
    }
  } catch (error) {
    logger.error(`[${requestId}] Enhanced tutor chat request failed`, {
      error: error.message,
      stack: error.stack,
      requestBody: req.body,
      userId: req.user?.userId || 'anonymous'
    });
    res.status(500).json({
      success: false,
      error: { 
        message: 'Internal server error. Please try again later.',
        code: 'ENHANCED_INTERNAL_ERROR'
      }
    });
  }
};
const generateFlashcardsWithCache = async (req, res) => {
  try {
    const { topic, count, difficulty, tags, subject } = req.body;
    const userId = req.user?.userId;
    if (!topic) {
      return res.status(400).json({
        success: false,
        error: { message: 'Topic is required' }
      });
    }
    const result = await enhancedAiService.generateFlashcardsWithCache(
      topic,
      count || 5,
      difficulty || 'medium',
      {
        tags,
        subject
      }
    );
    let flashcardsData = result.flashcards;
    if (typeof flashcardsData === 'string') {
      try {
        const cleanedResponse = flashcardsData.replace(/```json\n?|\n?```/g, '').trim();
        const parsed = JSON.parse(cleanedResponse);
        flashcardsData = parsed.flashcards || parsed;
      } catch (parseError) {
        logger.error('Failed to parse flashcards response:', parseError.message);
        return res.status(500).json({
          success: false,
          error: { message: 'Failed to parse flashcards response' }
        });
      }
    }
    if (!Array.isArray(flashcardsData)) {
      flashcardsData = [];
    }
    const savedFlashcards = [];
    if (userId && flashcardsData.length > 0) {
      for (const flashcard of flashcardsData) {
        try {
          const flashcardDoc = {
            userId,
            question: flashcard.question,
            answer: flashcard.answer,
            difficulty: flashcard.difficulty || difficulty || 'medium',
            tags: flashcard.tags || [topic],
            category: flashcard.category || topic,
            source: result.source,
            cacheHit: result.cacheHit,
            createdAt: new Date(),
            updatedAt: new Date(),
            isActive: true,
            studyCount: 0,
            correctCount: 0,
            lastStudied: null
          };
          const cleanedDoc = Object.fromEntries(
            Object.entries(flashcardDoc).filter(([_, value]) => value !== undefined)
          );
          const docRef = await db.collection('flashcards').add(cleanedDoc);
          savedFlashcards.push({
            id: docRef.id,
            ...cleanedDoc
          });
        } catch (saveError) {
          logger.error('Error saving flashcard:', saveError.message);
        }
      }
      await db.collection('interactions').add({
        type: 'enhanced_flashcard_generation',
        userId,
        topic,
        count: savedFlashcards.length,
        difficulty,
        cacheHit: result.cacheHit,
        source: result.source,
        timestamp: new Date(),
      });
    }
    res.status(201).json({
      success: true,
      data: {
        flashcards: savedFlashcards,
        generated: savedFlashcards.length,
        topic,
        cacheHit: result.cacheHit,
        source: result.source,
        ...(result.relatedTopic && { relatedTopic: result.relatedTopic }),
        ...(result.confidence && { confidence: result.confidence }),
        metadata: {
          difficulty: difficulty || 'medium',
          tags: tags || [topic]
        }
      }
    });
  } catch (error) {
    logger.error('Enhanced flashcard generation error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to generate flashcards' }
    });
  }
};
const getEnhancedAIStatus = async (req, res) => {
  try {
    const status = await enhancedAiService.getEnhancedServiceStatus();
    res.json({
      success: true,
      data: {
        ...status,
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    logger.error('Enhanced AI status check error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to get enhanced AI service status' }
    });
  }
};
const analyzeQuizPerformance = async (req, res) => {
  try {
    const { results } = req.body;
    const userId = req.user?.userId;
    if (!results || !Array.isArray(results)) {
      return res.status(400).json({
        success: false,
        error: { message: 'Results array is required' }
      });
    }
    let feedback = null;
    let source = 'none';
    try {
      feedback = await enhancedAiService.scienceqa.analyzePerformance(results);
      if (feedback) {
        source = 'scienceqa';
      }
    } catch (error) {
      logger.warn('ScienceQA performance analysis failed:', error.message);
    }
    if (!feedback) {
      const totalQuestions = results.length;
      const correctAnswers = results.filter(r => r.is_correct).length;
      const accuracy = (correctAnswers / totalQuestions) * 100;
      if (accuracy >= 90) {
        feedback = "Excellent performance! You've mastered this topic.";
      } else if (accuracy >= 70) {
        feedback = "Good job! Consider reviewing the questions you missed.";
      } else if (accuracy >= 50) {
        feedback = "You're making progress. Focus on reviewing the fundamentals.";
      } else {
        feedback = "Keep practicing! Consider reviewing the study materials.";
      }
      source = 'basic_analysis';
    }
    if (userId) {
      await db.collection('quiz_analyses').add({
        userId,
        results,
        feedback,
        source,
        accuracy: (results.filter(r => r.is_correct).length / results.length) * 100,
        timestamp: new Date(),
      });
    }
    res.json({
      success: true,
      data: {
        feedback,
        source,
        totalQuestions: results.length,
        correctAnswers: results.filter(r => r.is_correct).length,
        accuracy: Math.round((results.filter(r => r.is_correct).length / results.length) * 100),
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    logger.error('Quiz performance analysis error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to analyze quiz performance' }
    });
  }
};
module.exports = {
  explainTopicWithCache,
  createQuizQuestionsWithCache,
  chatWithTutorWithCache,
  generateFlashcardsWithCache,
  getEnhancedAIStatus,
  analyzeQuizPerformance
};
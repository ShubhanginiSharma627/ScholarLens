const enhancedAiService = require('../services/enhanced-ai.service');
const firestore = require('@google-cloud/firestore');
const winston = require('winston');

const db = new firestore.Firestore();

// Configure logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/enhanced-ai-controller.log' })
  ]
});

// Enhanced topic explanation with cache
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

    // Log interaction if user is authenticated
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

// Enhanced quiz generation with cache
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

    // Log interaction if user is authenticated
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

// Enhanced tutor chat with cache
const chatWithTutorWithCache = async (req, res) => {
  try {
    const { message, subject, studentLevel, conversationHistory, learningGoals, sessionType } = req.body;
    const userId = req.user?.userId;

    if (!message) {
      return res.status(400).json({
        success: false,
        error: { message: 'Message is required' }
      });
    }

    const result = await enhancedAiService.generateTutorResponseWithCache(message, {
      subject,
      studentLevel,
      conversationHistory,
      learningGoals,
      sessionType: sessionType || 'general_chat'
    });

    // Log interaction if user is authenticated
    if (userId) {
      await db.collection('chat_sessions').add({
        userId,
        userMessage: message,
        tutorResponse: result.response,
        subject,
        sessionType,
        cacheHit: result.cacheHit,
        source: result.source,
        timestamp: new Date(),
      });
    }

    res.json({
      success: true,
      data: { 
        response: result.response,
        sessionType: sessionType || 'general_chat',
        cacheHit: result.cacheHit,
        source: result.source,
        ...(result.relatedTopic && { relatedTopic: result.relatedTopic }),
        ...(result.confidence && { confidence: result.confidence }),
        timestamp: new Date().toISOString()
      }
    });

  } catch (error) {
    logger.error('Enhanced tutor chat error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to generate tutor response' }
    });
  }
};

// Enhanced flashcard generation with cache
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

    // Parse the flashcards response if it's a string
    let flashcardsData = result.flashcards;
    if (typeof flashcardsData === 'string') {
      try {
        // Remove markdown code blocks if present
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

    // Ensure flashcardsData is an array
    if (!Array.isArray(flashcardsData)) {
      flashcardsData = [];
    }

    // Save flashcards to database if user is authenticated
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

          // Only add fields that are not undefined
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

      // Log interaction
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

// Get enhanced AI service status
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

// Analyze quiz performance (uses ScienceQA if available)
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

    // Try ScienceQA first
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

    // Fallback to basic analysis if ScienceQA fails
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

    // Log interaction if user is authenticated
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
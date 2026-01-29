const { 
  generateExplanation,
  generateStudyPlan,
  generateRevisionPlan,
  generateTutorResponse,
  analyzeSyllabus,
  analyzeImageWithPrompt,
  generateQuizQuestions
} = require('../services/vertexai.service');
const firestore = require('@google-cloud/firestore');
const { createLogger, logBusiness, logPerformance } = require('../config/logging.config');

const db = new firestore.Firestore();

// Create service-specific logger
const logger = createLogger('ai-controller');

// Helper function to safely prepare Firestore data by removing undefined values
const prepareFirestoreData = (data) => {
  const cleanData = {};
  for (const [key, value] of Object.entries(data)) {
    if (value !== undefined && value !== null) {
      cleanData[key] = value;
    }
  }
  return cleanData;
};

// Generate topic explanation
const explainTopic = async (req, res) => {
  try {
    const { topic, audience, type, context, variation } = req.body;
    const userId = req.user?.userId;

    if (!topic) {
      return res.status(400).json({
        success: false,
        error: { message: 'Topic is required' }
      });
    }

    const explanation = await generateExplanation(topic, {
      audience: audience || 'student',
      type: type || 'detailed',
      context,
      variation
    });

    // Log interaction if user is authenticated
    if (userId) {
      const interactionData = prepareFirestoreData({
        type: 'topic_explanation',
        userId,
        topic,
        audience,
        explanationType: type,
        timestamp: new Date(),
      });
      await db.collection('interactions').add(interactionData);
    }

    res.json({
      success: true,
      data: { 
        explanation,
        topic,
        type: type || 'detailed'
      }
    });

  } catch (error) {
    logger.error('Topic explanation error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to generate explanation' }
    });
  }
};

// Generate study plan
const createStudyPlan = async (req, res) => {
  try {
    const { subjects, examDates, availableTime, currentLevel, studyPreferences, goals, constraints } = req.body;
    const userId = req.user?.userId;

    if (!subjects || !Array.isArray(subjects) || subjects.length === 0) {
      return res.status(400).json({
        success: false,
        error: { message: 'Subjects array is required' }
      });
    }

    const studyPlan = await generateStudyPlan(subjects, {
      examDates,
      availableTime,
      currentLevel: currentLevel || 'intermediate',
      studyPreferences,
      goals,
      constraints
    });

    // Log interaction if user is authenticated
    if (userId) {
      const interactionData = prepareFirestoreData({
        type: 'study_plan_generation',
        userId,
        subjects,
        currentLevel,
        timestamp: new Date(),
      });
      await db.collection('interactions').add(interactionData);
    }

    res.json({
      success: true,
      data: { 
        studyPlan,
        subjects,
        generatedAt: new Date().toISOString()
      }
    });

  } catch (error) {
    logger.error('Study plan generation error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to generate study plan' }
    });
  }
};

// Generate revision plan
const createRevisionPlan = async (req, res) => {
  try {
    const { topic, audience, length, constraints } = req.body;
    const userId = req.user?.userId;

    if (!topic) {
      return res.status(400).json({
        success: false,
        error: { message: 'Topic is required' }
      });
    }

    const revisionPlan = await generateRevisionPlan(topic, {
      audience: audience || 'student',
      length: length || 'comprehensive',
      constraints
    });

    // Log interaction if user is authenticated
    if (userId) {
      const interactionData = prepareFirestoreData({
        type: 'revision_plan_generation',
        userId,
        topic,
        audience,
        length,
        timestamp: new Date(),
      });
      await db.collection('interactions').add(interactionData);
    }

    res.json({
      success: true,
      data: { 
        revisionPlan,
        topic,
        length: length || 'comprehensive'
      }
    });

  } catch (error) {
    logger.error('Revision plan generation error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to generate revision plan' }
    });
  }
};

// Generate tutor chat response
const chatWithTutor = async (req, res) => {
  const requestId = `chat_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  try {
    const { message, subject, studentLevel, conversationHistory, learningGoals, sessionType } = req.body;
    const userId = req.user?.userId;

    logger.info(`[${requestId}] Tutor chat request received`, {
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

    logger.info(`[${requestId}] Processing tutor chat request`, {
      messageLength: message.length,
      subject,
      studentLevel,
      sessionType: sessionType || 'general_chat'
    });

    const startTime = Date.now();
    
    try {
      const tutorResponse = await generateTutorResponse(message, {
        subject,
        studentLevel,
        conversationHistory,
        learningGoals,
        sessionType: sessionType || 'general_chat'
      });

      const processingTime = Date.now() - startTime;

      // Validate that we got a response
      if (!tutorResponse || tutorResponse.trim() === '') {
        logger.error(`[${requestId}] Empty tutor response received`, {
          processingTime,
          originalMessage: message,
          options: { subject, studentLevel, sessionType }
        });
        return res.status(500).json({
          success: false,
          error: { message: 'Failed to generate response. Please try again.' }
        });
      }

      logger.info(`[${requestId}] Tutor response generated successfully`, {
        responseLength: tutorResponse.length,
        processingTime,
        userId: userId || 'anonymous'
      });

      // Log business metrics
      logBusiness('tutor_chat_success', userId, {
        messageLength: message.length,
        subject,
        sessionType: sessionType || 'general_chat',
        processingTime,
        responseLength: tutorResponse.length
      });

      // Log performance metrics
      logPerformance('tutor_chat_generation', processingTime, {
        requestId,
        userId: userId || 'anonymous',
        messageLength: message.length,
        responseLength: tutorResponse.length
      });

      // Log interaction if user is authenticated
      if (userId) {
        try {
          // Prepare chat session data, filtering out undefined values
          const chatSessionData = {
            userId,
            userMessage: message,
            tutorResponse,
            sessionType: sessionType || 'general_chat',
            processingTime,
            timestamp: new Date(),
          };
          
          // Only add subject if it's defined
          if (subject !== undefined && subject !== null) {
            chatSessionData.subject = subject;
          }
          
          await db.collection('chat_sessions').add(chatSessionData);
          logger.debug(`[${requestId}] Chat session logged to database`);
        } catch (dbError) {
          logger.error(`[${requestId}] Failed to log chat session to database`, {
            error: dbError.message,
            userId,
            subject: subject || 'undefined',
            sessionType: sessionType || 'undefined'
          });
          // Don't fail the request if logging fails
        }
      }

      res.json({
        success: true,
        data: { 
          response: tutorResponse,
          sessionType: sessionType || 'general_chat',
          processingTime,
          timestamp: new Date().toISOString()
        }
      });

    } catch (generationError) {
      const processingTime = Date.now() - startTime;
      
      logger.error(`[${requestId}] Tutor response generation failed`, {
        error: generationError.message,
        stack: generationError.stack,
        processingTime,
        messageLength: message.length,
        subject,
        studentLevel,
        sessionType,
        errorCode: generationError.code
      });

      // Provide specific error messages based on error type
      let errorMessage = 'Failed to generate tutor response';
      let statusCode = 500;
      
      if (generationError.message.includes('BILLING_DISABLED')) {
        errorMessage = 'AI service is temporarily unavailable due to billing configuration. Please contact support.';
        statusCode = 503;
      } else if (generationError.message.includes('NOT_FOUND')) {
        errorMessage = 'AI model is temporarily unavailable. Please try again later.';
        statusCode = 503;
      } else if (generationError.message.includes('model parameter must not be empty')) {
        errorMessage = 'AI service configuration error. Please contact support.';
        statusCode = 500;
      } else if (generationError.message.includes('Generated response is empty')) {
        errorMessage = 'Unable to generate a response. Please rephrase your question and try again.';
        statusCode = 422;
      } else if (generationError.message.includes('timeout')) {
        errorMessage = 'Request timed out. Please try again with a shorter message.';
        statusCode = 408;
      }
      
      return res.status(statusCode).json({
        success: false,
        error: { 
          message: errorMessage,
          code: generationError.code || 'GENERATION_ERROR',
          processingTime
        }
      });
    }

  } catch (error) {
    logger.error(`[${requestId}] Tutor chat request failed`, {
      error: error.message,
      stack: error.stack,
      requestBody: req.body,
      userId: req.user?.userId || 'anonymous'
    });
    
    res.status(500).json({
      success: false,
      error: { 
        message: 'Internal server error. Please try again later.',
        code: 'INTERNAL_ERROR'
      }
    });
  }
};

// Analyze syllabus
const analyzeSyllabusDocument = async (req, res) => {
  try {
    const { syllabusContent, courseLevel, subjectArea, analysisType, semesterLength } = req.body;
    const userId = req.user?.userId;

    if (!syllabusContent) {
      return res.status(400).json({
        success: false,
        error: { message: 'Syllabus content is required' }
      });
    }

    const analysis = await analyzeSyllabus(syllabusContent, {
      courseLevel,
      subjectArea,
      analysisType: analysisType || 'structure_extraction',
      semesterLength
    });

    // Log interaction if user is authenticated
    if (userId) {
      const interactionData = prepareFirestoreData({
        type: 'syllabus_analysis',
        userId,
        courseLevel,
        subjectArea,
        analysisType,
        timestamp: new Date(),
      });
      await db.collection('interactions').add(interactionData);
    }

    res.json({
      success: true,
      data: { 
        analysis,
        analysisType: analysisType || 'structure_extraction',
        processedAt: new Date().toISOString()
      }
    });

  } catch (error) {
    logger.error('Syllabus analysis error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to analyze syllabus' }
    });
  }
};

// Analyze image with enhanced prompts
const analyzeEducationalImage = async (req, res) => {
  try {
    const { imageData, analysisType, subject, language, difficulty } = req.body;
    const userId = req.user?.userId;

    if (!imageData) {
      return res.status(400).json({
        success: false,
        error: { message: 'Image data is required' }
      });
    }

    const analysis = await analyzeImageWithPrompt(imageData, {
      analysisType: analysisType || 'general',
      subject,
      language: language || 'English',
      difficulty
    });

    // Log interaction if user is authenticated
    if (userId) {
      const interactionData = prepareFirestoreData({
        type: 'image_analysis',
        userId,
        analysisType,
        subject,
        language,
        timestamp: new Date(),
      });
      await db.collection('interactions').add(interactionData);
    }

    res.json({
      success: true,
      data: { 
        analysis,
        analysisType: analysisType || 'general',
        processedAt: new Date().toISOString()
      }
    });

  } catch (error) {
    logger.error('Image analysis error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to analyze image' }
    });
  }
};

// Generate quiz questions
const createQuizQuestions = async (req, res) => {
  try {
    const { topic, count, type, subject, difficulty } = req.body;
    const userId = req.user?.userId;

    if (!topic) {
      return res.status(400).json({
        success: false,
        error: { message: 'Topic is required' }
      });
    }

    const quiz = await generateQuizQuestions(topic, count || 5, type || 'multiple_choice', {
      subject,
      difficulty
    });

    // Log interaction if user is authenticated
    if (userId) {
      const interactionData = prepareFirestoreData({
        type: 'quiz_generation',
        userId,
        topic,
        questionCount: count || 5,
        questionType: type || 'multiple_choice',
        timestamp: new Date(),
      });
      await db.collection('interactions').add(interactionData);
    }

    res.json({
      success: true,
      data: { 
        quiz,
        topic,
        questionCount: count || 5,
        questionType: type || 'multiple_choice'
      }
    });

  } catch (error) {
    logger.error('Quiz generation error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to generate quiz questions' }
    });
  }
};

// Get AI service status and available features
const getAIStatus = async (req, res) => {
  try {
    const { getAvailableModels } = require('../services/vertexai.service');
    const { getAvailablePrompts } = require('../services/prompt.service');
    
    const models = getAvailableModels();
    const prompts = getAvailablePrompts();

    res.json({
      success: true,
      data: {
        status: 'operational',
        models,
        prompts,
        features: [
          'topic_explanation',
          'study_plan_generation',
          'revision_plan_generation',
          'tutor_chat',
          'syllabus_analysis',
          'image_analysis',
          'quiz_generation',
          'flashcard_generation'
        ],
        timestamp: new Date().toISOString()
      }
    });

  } catch (error) {
    logger.error('AI status check error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to get AI service status' }
    });
  }
};

module.exports = {
  explainTopic,
  createStudyPlan,
  createRevisionPlan,
  chatWithTutor,
  analyzeSyllabusDocument,
  analyzeEducationalImage,
  createQuizQuestions,
  getAIStatus
};
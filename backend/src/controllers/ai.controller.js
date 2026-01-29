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
    new winston.transports.File({ filename: 'logs/ai-controller.log' })
  ]
});

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
      await db.collection('interactions').add({
        type: 'topic_explanation',
        userId,
        topic,
        audience,
        explanationType: type,
        timestamp: new Date(),
      });
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
      await db.collection('interactions').add({
        type: 'study_plan_generation',
        userId,
        subjects,
        currentLevel,
        timestamp: new Date(),
      });
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
      await db.collection('interactions').add({
        type: 'revision_plan_generation',
        userId,
        topic,
        audience,
        length,
        timestamp: new Date(),
      });
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
  try {
    const { message, subject, studentLevel, conversationHistory, learningGoals, sessionType } = req.body;
    const userId = req.user?.userId;

    if (!message) {
      return res.status(400).json({
        success: false,
        error: { message: 'Message is required' }
      });
    }

    logger.info(`Processing tutor chat request for message: "${message.substring(0, 50)}..."`);

    const tutorResponse = await generateTutorResponse(message, {
      subject,
      studentLevel,
      conversationHistory,
      learningGoals,
      sessionType: sessionType || 'general_chat'
    });

    // Validate that we got a response
    if (!tutorResponse || tutorResponse.trim() === '') {
      logger.error('Empty tutor response received');
      return res.status(500).json({
        success: false,
        error: { message: 'Failed to generate response. Please try again.' }
      });
    }

    // Log interaction if user is authenticated
    if (userId) {
      await db.collection('chat_sessions').add({
        userId,
        userMessage: message,
        tutorResponse,
        subject,
        sessionType,
        timestamp: new Date(),
      });
    }

    logger.info(`Tutor response generated successfully, length: ${tutorResponse.length}`);

    res.json({
      success: true,
      data: { 
        response: tutorResponse,
        sessionType: sessionType || 'general_chat',
        timestamp: new Date().toISOString()
      }
    });

  } catch (error) {
    logger.error('Tutor chat error:', error);
    
    // Provide specific error messages based on error type
    let errorMessage = 'Failed to generate tutor response';
    
    if (error.message.includes('BILLING_DISABLED')) {
      errorMessage = 'AI service is temporarily unavailable due to billing configuration. Please contact support.';
    } else if (error.message.includes('NOT_FOUND')) {
      errorMessage = 'AI model is temporarily unavailable. Please try again later.';
    } else if (error.message.includes('model parameter must not be empty')) {
      errorMessage = 'AI service configuration error. Please contact support.';
    } else if (error.message.includes('Generated response is empty')) {
      errorMessage = 'Unable to generate a response. Please rephrase your question and try again.';
    }
    
    res.status(500).json({
      success: false,
      error: { message: errorMessage }
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
      await db.collection('interactions').add({
        type: 'syllabus_analysis',
        userId,
        courseLevel,
        subjectArea,
        analysisType,
        timestamp: new Date(),
      });
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
      await db.collection('interactions').add({
        type: 'image_analysis',
        userId,
        analysisType,
        subject,
        language,
        timestamp: new Date(),
      });
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
      await db.collection('interactions').add({
        type: 'quiz_generation',
        userId,
        topic,
        questionCount: count || 5,
        questionType: type || 'multiple_choice',
        timestamp: new Date(),
      });
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
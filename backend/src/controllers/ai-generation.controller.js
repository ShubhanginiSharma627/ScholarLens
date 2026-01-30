const aiGenerationService = require('../services/ai-generation.service');
const aiGenerationDB = require('../services/ai-generation-db.service');
const winston = require('winston');
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/ai-generation-controller.log' })
  ]
});
const generateFromContent = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { contentSource, options = {} } = req.body;
    if (!contentSource || !contentSource.type || !contentSource.content) {
      return res.status(400).json({
        success: false,
        error: { message: 'Content source with type and content is required' }
      });
    }
    const validTypes = ['image', 'pdf', 'text', 'topic'];
    if (!validTypes.includes(contentSource.type)) {
      return res.status(400).json({
        success: false,
        error: { message: `Invalid content type. Must be one of: ${validTypes.join(', ')}` }
      });
    }
    logger.info(`Generating flashcards from ${contentSource.type} for user: ${userId}`);
    const result = await aiGenerationService.processContentAndGenerate(
      userId,
      contentSource,
      options
    );
    res.status(201).json({
      success: true,
      data: result
    });
  } catch (error) {
    logger.error('Generate from content error:', error);
    res.status(500).json({
      success: false,
      error: { 
        message: 'Failed to generate flashcards from content',
        details: error.message
      }
    });
  }
};
const getGenerationSession = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { sessionId } = req.params;
    const session = await aiGenerationDB.getGenerationSession(sessionId);
    if (!session) {
      return res.status(404).json({
        success: false,
        error: { message: 'Generation session not found' }
      });
    }
    if (session.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied' }
      });
    }
    const flashcards = await aiGenerationDB.getGeneratedFlashcards(sessionId);
    res.json({
      success: true,
      data: {
        session,
        flashcards
      }
    });
  } catch (error) {
    logger.error('Get generation session error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to get generation session' }
    });
  }
};
const getUserSessions = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { limit = 20, offset = 0 } = req.query;
    const sessions = await aiGenerationDB.getUserGenerationSessions(
      userId,
      parseInt(limit),
      parseInt(offset)
    );
    res.json({
      success: true,
      data: {
        sessions,
        total: sessions.length,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (error) {
    logger.error('Get user sessions error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to get user sessions' }
    });
  }
};
const updateGeneratedFlashcard = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { flashcardId } = req.params;
    const updates = req.body;
    const flashcards = await aiGenerationDB.getGeneratedFlashcards(updates.sessionId);
    const flashcard = flashcards.find(f => f.id === flashcardId);
    if (!flashcard) {
      return res.status(404).json({
        success: false,
        error: { message: 'Generated flashcard not found' }
      });
    }
    const session = await aiGenerationDB.getGenerationSession(flashcard.sessionId);
    if (!session || session.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied' }
      });
    }
    await aiGenerationDB.updateGeneratedFlashcard(flashcardId, updates);
    await aiGenerationDB.trackAnalyticsEvent(
      userId,
      flashcard.sessionId,
      'flashcard_edited',
      { flashcardId, updates: Object.keys(updates) }
    );
    res.json({
      success: true,
      data: { message: 'Flashcard updated successfully' }
    });
  } catch (error) {
    logger.error('Update generated flashcard error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to update flashcard' }
    });
  }
};
const deleteGeneratedFlashcard = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { flashcardId } = req.params;
    const { sessionId } = req.body;
    const session = await aiGenerationDB.getGenerationSession(sessionId);
    if (!session || session.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied' }
      });
    }
    await aiGenerationDB.deleteGeneratedFlashcard(flashcardId);
    await aiGenerationDB.trackAnalyticsEvent(
      userId,
      sessionId,
      'flashcard_deleted',
      { flashcardId }
    );
    res.json({
      success: true,
      data: { message: 'Flashcard deleted successfully' }
    });
  } catch (error) {
    logger.error('Delete generated flashcard error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to delete flashcard' }
    });
  }
};
const regenerateFlashcard = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { flashcardId } = req.params;
    const { feedback, sessionId } = req.body;
    const session = await aiGenerationDB.getGenerationSession(sessionId);
    if (!session || session.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied' }
      });
    }
    const flashcards = await aiGenerationDB.getGeneratedFlashcards(sessionId);
    const originalFlashcard = flashcards.find(f => f.id === flashcardId);
    if (!originalFlashcard) {
      return res.status(404).json({
        success: false,
        error: { message: 'Flashcard not found' }
      });
    }
    const regeneratedFlashcard = {
      ...originalFlashcard,
      id: require('uuid').v4(),
      generatedAt: new Date(),
      confidence: Math.max(0.1, originalFlashcard.confidence - 0.1),
      feedback: feedback || 'Regenerated based on user request'
    };
    await aiGenerationDB.updateGeneratedFlashcard(flashcardId, regeneratedFlashcard);
    await aiGenerationDB.trackAnalyticsEvent(
      userId,
      sessionId,
      'flashcard_regenerated',
      { flashcardId, feedback }
    );
    res.json({
      success: true,
      data: { flashcard: regeneratedFlashcard }
    });
  } catch (error) {
    logger.error('Regenerate flashcard error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to regenerate flashcard' }
    });
  }
};
const approveAndSaveFlashcards = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { sessionId, flashcardIds } = req.body;
    const session = await aiGenerationDB.getGenerationSession(sessionId);
    if (!session || session.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied' }
      });
    }
    const allFlashcards = await aiGenerationDB.getGeneratedFlashcards(sessionId);
    const flashcardsToSave = flashcardIds 
      ? allFlashcards.filter(f => flashcardIds.includes(f.id))
      : allFlashcards;
    if (flashcardsToSave.length === 0) {
      return res.status(400).json({
        success: false,
        error: { message: 'No flashcards to save' }
      });
    }
    const savedFlashcards = [];
    const firestore = require('@google-cloud/firestore');
    const db = new firestore.Firestore();
    for (const generatedCard of flashcardsToSave) {
      const flashcardData = {
        id: generatedCard.id,
        userId,
        question: generatedCard.question,
        answer: generatedCard.answer,
        difficulty: generatedCard.difficulty,
        tags: generatedCard.concepts || [],
        subject: generatedCard.subject,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        studyStats: {
          timesStudied: 0,
          correctAnswers: 0,
          lastStudied: null,
          nextReview: new Date().toISOString(),
          easeFactor: 2.5,
          interval: 1
        },
        generatedBy: 'ai',
        generationSessionId: sessionId,
        aiGenerated: true,
        aiConfidence: generatedCard.confidence,
        aiConcepts: generatedCard.concepts,
        aiExplanation: generatedCard.explanation,
        aiMemoryTip: generatedCard.memoryTip
      };
      await db.collection('flashcards').doc(generatedCard.id).set(flashcardData);
      savedFlashcards.push(flashcardData);
    }
    await aiGenerationDB.updateSessionStatus(sessionId, 'saved');
    await aiGenerationDB.trackAnalyticsEvent(
      userId,
      sessionId,
      'flashcards_approved',
      { approvedCount: savedFlashcards.length }
    );
    res.json({
      success: true,
      data: {
        message: 'Flashcards approved and saved successfully',
        savedCount: savedFlashcards.length,
        flashcards: savedFlashcards
      }
    });
  } catch (error) {
    logger.error('Approve and save flashcards error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to approve and save flashcards' }
    });
  }
};
const getUserPreferences = async (req, res) => {
  try {
    const userId = req.user.userId;
    const preferences = await aiGenerationDB.getUserPreferences(userId);
    res.json({
      success: true,
      data: { preferences }
    });
  } catch (error) {
    logger.error('Get user preferences error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to get user preferences' }
    });
  }
};
const updateUserPreferences = async (req, res) => {
  try {
    const userId = req.user.userId;
    const preferences = req.body;
    await aiGenerationDB.updateUserPreferences(userId, preferences);
    res.json({
      success: true,
      data: { message: 'Preferences updated successfully' }
    });
  } catch (error) {
    logger.error('Update user preferences error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to update preferences' }
    });
  }
};
const getUserStats = async (req, res) => {
  try {
    const userId = req.user.userId;
    const stats = await aiGenerationDB.getUserGenerationStats(userId);
    res.json({
      success: true,
      data: { stats }
    });
  } catch (error) {
    logger.error('Get user stats error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to get user statistics' }
    });
  }
};
const getHealthStatus = async (req, res) => {
  try {
    const health = await aiGenerationService.getHealthStatus();
    const statusCode = health.status === 'healthy' ? 200 : 503;
    res.status(statusCode).json({
      success: health.status === 'healthy',
      data: health
    });
  } catch (error) {
    logger.error('Health check error:', error);
    res.status(503).json({
      success: false,
      error: { message: 'Health check failed' }
    });
  }
};
module.exports = {
  generateFromContent,
  getGenerationSession,
  getUserSessions,
  updateGeneratedFlashcard,
  deleteGeneratedFlashcard,
  regenerateFlashcard,
  approveAndSaveFlashcards,
  getUserPreferences,
  updateUserPreferences,
  getUserStats,
  getHealthStatus
};
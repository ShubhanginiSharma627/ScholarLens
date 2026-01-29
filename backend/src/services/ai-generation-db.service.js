const firestore = require('@google-cloud/firestore');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');

// Configure logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/ai-generation-db.log' })
  ]
});

const db = new firestore.Firestore();

/**
 * Database service for AI Flashcard Generation
 * Handles all database operations for the AI generation system
 */
class AIGenerationDBService {
  
  // Generation Sessions
  
  /**
   * Create a new generation session
   */
  async createGenerationSession(userId, contentSource) {
    try {
      const sessionId = uuidv4();
      const sessionData = {
        id: sessionId,
        userId,
        contentSource,
        status: 'processing',
        createdAt: new Date().toISOString(),
        completedAt: null,
        errorMessage: null,
        metadata: {}
      };
      
      await db.collection('generation_sessions').doc(sessionId).set(sessionData);
      logger.info(`Created generation session: ${sessionId} for user: ${userId}`);
      
      return sessionData;
    } catch (error) {
      logger.error('Failed to create generation session:', error);
      throw error;
    }
  }
  
  /**
   * Update generation session status
   */
  async updateSessionStatus(sessionId, status, errorMessage = null) {
    try {
      const updateData = {
        status,
        updatedAt: new Date().toISOString()
      };
      
      if (status === 'saved' || status === 'failed') {
        updateData.completedAt = new Date().toISOString();
      }
      
      if (errorMessage) {
        updateData.errorMessage = errorMessage;
      }
      
      await db.collection('generation_sessions').doc(sessionId).update(updateData);
      logger.info(`Updated session ${sessionId} status to: ${status}`);
      
    } catch (error) {
      logger.error(`Failed to update session status: ${sessionId}`, error);
      throw error;
    }
  }
  
  /**
   * Get generation session by ID
   */
  async getGenerationSession(sessionId) {
    try {
      const doc = await db.collection('generation_sessions').doc(sessionId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return doc.data();
    } catch (error) {
      logger.error(`Failed to get generation session: ${sessionId}`, error);
      throw error;
    }
  }
  
  /**
   * Get user's generation sessions
   */
  async getUserGenerationSessions(userId, limit = 20, offset = 0) {
    try {
      const snapshot = await db.collection('generation_sessions')
        .where('userId', '==', userId)
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .offset(offset)
        .get();
      
      const sessions = [];
      snapshot.forEach(doc => {
        sessions.push(doc.data());
      });
      
      return sessions;
    } catch (error) {
      logger.error(`Failed to get user sessions for: ${userId}`, error);
      throw error;
    }
  }
  
  // Generated Flashcards
  
  /**
   * Save generated flashcards to a session
   */
  async saveGeneratedFlashcards(sessionId, flashcards) {
    try {
      const batch = db.batch();
      
      for (const flashcard of flashcards) {
        const flashcardId = flashcard.id || uuidv4();
        const flashcardData = {
          ...flashcard,
          id: flashcardId,
          sessionId,
          generatedAt: new Date().toISOString()
        };
        
        const docRef = db.collection('generated_flashcards').doc(flashcardId);
        batch.set(docRef, flashcardData);
      }
      
      await batch.commit();
      logger.info(`Saved ${flashcards.length} generated flashcards for session: ${sessionId}`);
      
    } catch (error) {
      logger.error(`Failed to save generated flashcards for session: ${sessionId}`, error);
      throw error;
    }
  }
  
  /**
   * Get generated flashcards for a session
   */
  async getGeneratedFlashcards(sessionId) {
    try {
      const snapshot = await db.collection('generated_flashcards')
        .where('sessionId', '==', sessionId)
        .orderBy('generatedAt', 'asc')
        .get();
      
      const flashcards = [];
      snapshot.forEach(doc => {
        flashcards.push(doc.data());
      });
      
      return flashcards;
    } catch (error) {
      logger.error(`Failed to get generated flashcards for session: ${sessionId}`, error);
      throw error;
    }
  }
  
  /**
   * Update a generated flashcard
   */
  async updateGeneratedFlashcard(flashcardId, updates) {
    try {
      const updateData = {
        ...updates,
        updatedAt: new Date().toISOString()
      };
      
      await db.collection('generated_flashcards').doc(flashcardId).update(updateData);
      logger.info(`Updated generated flashcard: ${flashcardId}`);
      
    } catch (error) {
      logger.error(`Failed to update generated flashcard: ${flashcardId}`, error);
      throw error;
    }
  }
  
  /**
   * Delete a generated flashcard
   */
  async deleteGeneratedFlashcard(flashcardId) {
    try {
      await db.collection('generated_flashcards').doc(flashcardId).delete();
      logger.info(`Deleted generated flashcard: ${flashcardId}`);
      
    } catch (error) {
      logger.error(`Failed to delete generated flashcard: ${flashcardId}`, error);
      throw error;
    }
  }
  
  // Content Analysis Cache
  
  /**
   * Cache content analysis result
   */
  async cacheContentAnalysis(contentHash, contentType, analysisResult, ttlHours = 24) {
    try {
      const cacheId = uuidv4();
      const expiresAt = new Date();
      expiresAt.setHours(expiresAt.getHours() + ttlHours);
      
      const cacheData = {
        id: cacheId,
        contentHash,
        contentType,
        analysisResult,
        createdAt: new Date().toISOString(),
        expiresAt: expiresAt.toISOString()
      };
      
      await db.collection('content_analysis_cache').doc(cacheId).set(cacheData);
      logger.info(`Cached content analysis for hash: ${contentHash}`);
      
    } catch (error) {
      logger.error(`Failed to cache content analysis: ${contentHash}`, error);
      throw error;
    }
  }
  
  /**
   * Get cached content analysis
   */
  async getCachedContentAnalysis(contentHash) {
    try {
      const snapshot = await db.collection('content_analysis_cache')
        .where('contentHash', '==', contentHash)
        .where('expiresAt', '>', new Date().toISOString())
        .limit(1)
        .get();
      
      if (snapshot.empty) {
        return null;
      }
      
      const doc = snapshot.docs[0];
      return doc.data().analysisResult;
    } catch (error) {
      logger.error(`Failed to get cached content analysis: ${contentHash}`, error);
      throw error;
    }
  }
  
  // User Preferences
  
  /**
   * Get user's AI generation preferences
   */
  async getUserPreferences(userId) {
    try {
      const doc = await db.collection('ai_generation_preferences').doc(userId).get();
      
      if (!doc.exists) {
        // Return default preferences
        return {
          defaultDifficulty: 'intermediate',
          preferredSubjects: [],
          defaultFlashcardCount: 5,
          includeExplanations: false,
          includeMemoryTips: false,
          qualityThreshold: 0.7
        };
      }
      
      return doc.data();
    } catch (error) {
      logger.error(`Failed to get user preferences: ${userId}`, error);
      throw error;
    }
  }
  
  /**
   * Update user's AI generation preferences
   */
  async updateUserPreferences(userId, preferences) {
    try {
      const updateData = {
        ...preferences,
        updatedAt: new Date().toISOString()
      };
      
      await db.collection('ai_generation_preferences').doc(userId).set(updateData, { merge: true });
      logger.info(`Updated preferences for user: ${userId}`);
      
    } catch (error) {
      logger.error(`Failed to update user preferences: ${userId}`, error);
      throw error;
    }
  }
  
  // Analytics
  
  /**
   * Track generation analytics event
   */
  async trackAnalyticsEvent(userId, sessionId, eventType, eventData = {}) {
    try {
      const eventId = uuidv4();
      const analyticsData = {
        id: eventId,
        userId,
        sessionId,
        eventType,
        eventData,
        timestamp: new Date().toISOString()
      };
      
      await db.collection('generation_analytics').doc(eventId).set(analyticsData);
      logger.debug(`Tracked analytics event: ${eventType} for session: ${sessionId}`);
      
    } catch (error) {
      logger.error(`Failed to track analytics event: ${eventType}`, error);
      // Don't throw error for analytics failures
    }
  }
  
  /**
   * Get user generation statistics
   */
  async getUserGenerationStats(userId) {
    try {
      // Get sessions
      const sessionsSnapshot = await db.collection('generation_sessions')
        .where('userId', '==', userId)
        .get();
      
      let totalSessions = 0;
      let successfulSessions = 0;
      let failedSessions = 0;
      
      sessionsSnapshot.forEach(doc => {
        const session = doc.data();
        totalSessions++;
        
        if (session.status === 'saved') {
          successfulSessions++;
        } else if (session.status === 'failed') {
          failedSessions++;
        }
      });
      
      // Get flashcards
      const flashcardsSnapshot = await db.collection('generated_flashcards')
        .where('sessionId', 'in', sessionsSnapshot.docs.map(doc => doc.id))
        .get();
      
      let totalFlashcards = 0;
      let totalConfidence = 0;
      const subjects = {};
      
      flashcardsSnapshot.forEach(doc => {
        const flashcard = doc.data();
        totalFlashcards++;
        totalConfidence += flashcard.confidence || 0;
        
        if (flashcard.subject) {
          subjects[flashcard.subject] = (subjects[flashcard.subject] || 0) + 1;
        }
      });
      
      const averageConfidence = totalFlashcards > 0 ? totalConfidence / totalFlashcards : 0;
      const mostCommonSubjects = Object.entries(subjects)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 5)
        .map(([subject]) => subject);
      
      return {
        totalSessions,
        successfulSessions,
        failedSessions,
        totalFlashcards,
        averageConfidence,
        mostCommonSubjects
      };
      
    } catch (error) {
      logger.error(`Failed to get user generation stats: ${userId}`, error);
      throw error;
    }
  }
  
  // Utility Methods
  
  /**
   * Cleanup expired cache entries
   */
  async cleanupExpiredCache() {
    try {
      const now = new Date().toISOString();
      const snapshot = await db.collection('content_analysis_cache')
        .where('expiresAt', '<', now)
        .get();
      
      if (snapshot.empty) {
        return 0;
      }
      
      const batch = db.batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      await batch.commit();
      logger.info(`Cleaned up ${snapshot.size} expired cache entries`);
      
      return snapshot.size;
    } catch (error) {
      logger.error('Failed to cleanup expired cache:', error);
      throw error;
    }
  }
  
  /**
   * Get database health status
   */
  async getHealthStatus() {
    try {
      // Test basic connectivity
      await db.collection('generation_sessions').limit(1).get();
      
      return {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        collections: [
          'generation_sessions',
          'generated_flashcards', 
          'content_analysis_cache',
          'ai_generation_preferences',
          'generation_analytics'
        ]
      };
    } catch (error) {
      logger.error('Database health check failed:', error);
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }
}

module.exports = new AIGenerationDBService();
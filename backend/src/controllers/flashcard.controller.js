const firestore = require('@google-cloud/firestore');
const { v4: uuidv4 } = require('uuid');
const { generateFlashcards } = require('../services/vertexai.service');

const db = new firestore.Firestore();

// Create a new flashcard
const createFlashcard = async (req, res) => {
  try {
    const { question, answer, difficulty, tags, setId } = req.body;
    const userId = req.user.userId;
    
    const flashcardId = uuidv4();
    const flashcardData = {
      id: flashcardId,
      userId,
      question,
      answer,
      difficulty: difficulty || 'medium',
      tags: tags || [],
      setId: setId || null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      studyStats: {
        timesStudied: 0,
        correctAnswers: 0,
        lastStudied: null,
        nextReview: new Date().toISOString(),
        easeFactor: 2.5,
        interval: 1
      }
    };
    
    await db.collection('flashcards').doc(flashcardId).set(flashcardData);
    
    res.status(201).json({
      success: true,
      data: { flashcard: flashcardData }
    });
    
  } catch (error) {
    console.error('Create flashcard error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to create flashcard' }
    });
  }
};

// Get user's flashcards
const getFlashcards = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { setId, tags, difficulty, limit = 50, offset = 0 } = req.query;
    
    let query = db.collection('flashcards').where('userId', '==', userId);
    
    if (setId) {
      query = query.where('setId', '==', setId);
    }
    
    if (difficulty) {
      query = query.where('difficulty', '==', difficulty);
    }
    
    const snapshot = await query.limit(parseInt(limit)).offset(parseInt(offset)).get();
    
    let flashcards = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      
      // Filter by tags if provided
      if (tags) {
        const tagArray = tags.split(',');
        const hasMatchingTag = tagArray.some(tag => data.tags.includes(tag));
        if (hasMatchingTag) {
          flashcards.push(data);
        }
      } else {
        flashcards.push(data);
      }
    });
    
    res.json({
      success: true,
      data: { 
        flashcards,
        total: flashcards.length,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
    
  } catch (error) {
    console.error('Get flashcards error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to get flashcards' }
    });
  }
};

// Update flashcard
const updateFlashcard = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    const updates = req.body;
    
    // Check if flashcard exists and belongs to user
    const flashcardDoc = await db.collection('flashcards').doc(id).get();
    if (!flashcardDoc.exists) {
      return res.status(404).json({
        success: false,
        error: { message: 'Flashcard not found' }
      });
    }
    
    const flashcardData = flashcardDoc.data();
    if (flashcardData.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied' }
      });
    }
    
    // Update flashcard
    const updatedData = {
      ...updates,
      updatedAt: new Date().toISOString()
    };
    
    await db.collection('flashcards').doc(id).update(updatedData);
    
    res.json({
      success: true,
      data: { message: 'Flashcard updated successfully' }
    });
    
  } catch (error) {
    console.error('Update flashcard error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to update flashcard' }
    });
  }
};

// Delete flashcard
const deleteFlashcard = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    
    // Check if flashcard exists and belongs to user
    const flashcardDoc = await db.collection('flashcards').doc(id).get();
    if (!flashcardDoc.exists) {
      return res.status(404).json({
        success: false,
        error: { message: 'Flashcard not found' }
      });
    }
    
    const flashcardData = flashcardDoc.data();
    if (flashcardData.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied' }
      });
    }
    
    await db.collection('flashcards').doc(id).delete();
    
    res.json({
      success: true,
      data: { message: 'Flashcard deleted successfully' }
    });
    
  } catch (error) {
    console.error('Delete flashcard error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to delete flashcard' }
    });
  }
};

// Generate flashcards from topic using AI
const generateFlashcardsFromTopic = async (req, res) => {
  try {
    const { topic, count = 5, difficulty = 'medium', setId } = req.body;
    const userId = req.user.userId;
    
    if (!topic) {
      return res.status(400).json({
        success: false,
        error: { message: 'Topic is required' }
      });
    }
    
    // Generate flashcards using AI with enhanced prompt system
    const aiResponse = await generateFlashcards(topic, count, difficulty, {
      context: req.body.context,
      tags: req.body.tags
    });
    
    // Parse AI response and create flashcards
    const flashcardMatches = aiResponse.match(/Q: (.*?)\nA: (.*?)(?=\n\n|$)/gs);
    const createdFlashcards = [];
    
    if (flashcardMatches) {
      for (const match of flashcardMatches) {
        const lines = match.trim().split('\n');
        const question = lines[0].replace('Q: ', '').trim();
        const answer = lines[1].replace('A: ', '').trim();
        
        const flashcardId = uuidv4();
        const flashcardData = {
          id: flashcardId,
          userId,
          question,
          answer,
          difficulty,
          tags: [topic],
          setId: setId || null,
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
          generatedBy: 'ai'
        };
        
        await db.collection('flashcards').doc(flashcardId).set(flashcardData);
        createdFlashcards.push(flashcardData);
      }
    }
    
    // Log interaction
    await db.collection('interactions').add({
      type: 'flashcard_generation',
      userId,
      topic,
      count: createdFlashcards.length,
      timestamp: new Date(),
    });
    
    res.status(201).json({
      success: true,
      data: { 
        flashcards: createdFlashcards,
        generated: createdFlashcards.length,
        topic
      }
    });
    
  } catch (error) {
    console.error('Generate flashcards error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to generate flashcards' }
    });
  }
};

// Create flashcard set
const createFlashcardSet = async (req, res) => {
  try {
    const { name, description, tags } = req.body;
    const userId = req.user.userId;
    
    const setId = uuidv4();
    const setData = {
      id: setId,
      userId,
      name,
      description: description || '',
      tags: tags || [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      flashcardCount: 0
    };
    
    await db.collection('flashcard_sets').doc(setId).set(setData);
    
    res.status(201).json({
      success: true,
      data: { set: setData }
    });
    
  } catch (error) {
    console.error('Create flashcard set error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to create flashcard set' }
    });
  }
};

// Get user's flashcard sets
const getFlashcardSets = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    const snapshot = await db.collection('flashcard_sets').where('userId', '==', userId).get();
    
    const sets = [];
    snapshot.forEach(doc => {
      sets.push(doc.data());
    });
    
    res.json({
      success: true,
      data: { sets }
    });
    
  } catch (error) {
    console.error('Get flashcard sets error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to get flashcard sets' }
    });
  }
};

// Study flashcards (spaced repetition)
const studyFlashcards = async (req, res) => {
  try {
    const { flashcardId, correct, timeSpent } = req.body;
    const userId = req.user.userId;
    
    // Get flashcard
    const flashcardDoc = await db.collection('flashcards').doc(flashcardId).get();
    if (!flashcardDoc.exists) {
      return res.status(404).json({
        success: false,
        error: { message: 'Flashcard not found' }
      });
    }
    
    const flashcardData = flashcardDoc.data();
    if (flashcardData.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied' }
      });
    }
    
    // Update study stats using spaced repetition algorithm
    const stats = flashcardData.studyStats;
    const newStats = { ...stats };
    
    newStats.timesStudied += 1;
    newStats.lastStudied = new Date().toISOString();
    
    if (correct) {
      newStats.correctAnswers += 1;
      
      // Increase interval based on ease factor
      if (newStats.timesStudied === 1) {
        newStats.interval = 1;
      } else if (newStats.timesStudied === 2) {
        newStats.interval = 6;
      } else {
        newStats.interval = Math.round(newStats.interval * newStats.easeFactor);
      }
      
      // Adjust ease factor
      newStats.easeFactor = Math.max(1.3, newStats.easeFactor + 0.1);
    } else {
      // Reset interval for incorrect answers
      newStats.interval = 1;
      newStats.easeFactor = Math.max(1.3, newStats.easeFactor - 0.2);
    }
    
    // Calculate next review date
    const nextReviewDate = new Date();
    nextReviewDate.setDate(nextReviewDate.getDate() + newStats.interval);
    newStats.nextReview = nextReviewDate.toISOString();
    
    // Update flashcard
    await db.collection('flashcards').doc(flashcardId).update({
      studyStats: newStats,
      updatedAt: new Date().toISOString()
    });
    
    // Log study session
    await db.collection('study_sessions').add({
      userId,
      flashcardId,
      correct,
      timeSpent: timeSpent || 0,
      timestamp: new Date(),
      interval: newStats.interval,
      easeFactor: newStats.easeFactor
    });
    
    res.json({
      success: true,
      data: { 
        message: 'Study session recorded',
        nextReview: newStats.nextReview,
        interval: newStats.interval
      }
    });
    
  } catch (error) {
    console.error('Study flashcards error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to record study session' }
    });
  }
};

module.exports = {
  createFlashcard,
  getFlashcards,
  updateFlashcard,
  deleteFlashcard,
  generateFlashcardsFromTopic,
  createFlashcardSet,
  getFlashcardSets,
  studyFlashcards
};
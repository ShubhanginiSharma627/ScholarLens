const jwt = require('jsonwebtoken');
const firestore = require('@google-cloud/firestore');

const db = new firestore.Firestore();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

const authService = {
  // Generate JWT token
  generateToken: (userId) => {
    return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '24h' });
  },

  // Verify JWT token
  verifyToken: (token) => {
    try {
      return jwt.verify(token, JWT_SECRET);
    } catch (error) {
      return null;
    }
  },

  // Register new user
  registerUser: async (email, password, name) => {
    try {
      // Check if user exists
      const userQuery = await db.collection('users').where('email', '==', email).get();
      if (!userQuery.empty) {
        throw new Error('User already exists');
      }

      // Create user document
      const userRef = db.collection('users').doc();
      const user = {
        id: userRef.id,
        email,
        name,
        passwordHash: password, // In production, use bcrypt
        createdAt: new Date(),
        profile: {
          bio: '',
          avatar: '',
          learningStyle: 'visual',
          preferredLanguage: 'en'
        },
        stats: {
          totalMinutesLearned: 0,
          currentStreak: 0,
          longestStreak: 0,
          quizzesCompleted: 0,
          averageScore: 0
        }
      };

      await userRef.set(user);
      return { ...user, token: authService.generateToken(userRef.id) };
    } catch (error) {
      throw error;
    }
  },

  // Login user
  loginUser: async (email, password) => {
    try {
      const userQuery = await db.collection('users').where('email', '==', email).get();
      if (userQuery.empty) {
        throw new Error('User not found');
      }

      const user = userQuery.docs[0].data();
      // In production, use bcrypt.compare
      if (user.passwordHash !== password) {
        throw new Error('Invalid password');
      }

      return { ...user, token: authService.generateToken(user.id) };
    } catch (error) {
      throw error;
    }
  },

  // Get user by ID
  getUserById: async (userId) => {
    const doc = await db.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  },

  // Update user profile
  updateUserProfile: async (userId, updates) => {
    await db.collection('users').doc(userId).update(updates);
    return authService.getUserById(userId);
  }
};

module.exports = authService;
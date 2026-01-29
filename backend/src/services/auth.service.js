const jwt = require('jsonwebtoken');
const firestore = require('@google-cloud/firestore');

const db = new firestore.Firestore();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

console.log('🔐 AuthService initialized');
console.log('📦 Firestore connected');

const authService = {
  // Generate JWT token
  generateToken: (userId) => {
    console.log('🪪 Generating JWT for user:', userId);
    return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '24h' });
  },

  // Verify JWT token
  verifyToken: (token) => {
    try {
      console.log('🔍 Verifying JWT');
      return jwt.verify(token, JWT_SECRET);
    } catch (error) {
      console.error('❌ JWT verification failed:', error.message);
      return null;
    }
  },

  // Register new user
  registerUser: async (email, password, name) => {
    console.log('📝 Register user request received:', { email, name });

    try {
      console.log('🔎 Checking if user already exists');
      const userQuery = await db
        .collection('users')
        .where('email', '==', email)
        .get();

      if (!userQuery.empty) {
        console.warn('⚠️ User already exists:', email);
        throw new Error('User already exists');
      }

      console.log('📄 Creating new user document');
      const userRef = db.collection('users').doc();

      const user = {
        id: userRef.id,
        email,
        name,
        passwordHash: password, // ⚠️ Replace with bcrypt in production
        createdAt: new Date(),
        profile: {
          bio: '',
          avatar: '',
          learningStyle: 'visual',
          preferredLanguage: 'en',
        },
        stats: {
          totalMinutesLearned: 0,
          currentStreak: 0,
          longestStreak: 0,
          quizzesCompleted: 0,
          averageScore: 0,
        },
      };

      await userRef.set(user);
      console.log('✅ User saved to Firestore:', userRef.id);

      const token = authService.generateToken(userRef.id);
      console.log('🎉 Registration successful:', email);

      return { ...user, token };
    } catch (error) {
      console.error('❌ Registration failed:', error.message);
      throw error;
    }
  },

  // Login user
  loginUser: async (email, password) => {
    console.log('🔐 Login attempt:', email);

    try {
      const userQuery = await db
        .collection('users')
        .where('email', '==', email)
        .get();

      if (userQuery.empty) {
        console.warn('❌ User not found:', email);
        throw new Error('User not found');
      }

      const user = userQuery.docs[0].data();

      if (user.passwordHash !== password) {
        console.warn('❌ Invalid password for:', email);
        throw new Error('Invalid password');
      }

      console.log('✅ Login successful:', email);
      return { ...user, token: authService.generateToken(user.id) };
    } catch (error) {
      console.error('❌ Login failed:', error.message);
      throw error;
    }
  },

  // Get user by ID
  getUserById: async (userId) => {
    console.log('📥 Fetching user by ID:', userId);
    const doc = await db.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  },

  // Update user profile
  updateUserProfile: async (userId, updates) => {
    console.log('✏️ Updating user profile:', userId, updates);
    await db.collection('users').doc(userId).update(updates);
    return authService.getUserById(userId);
  },
};

module.exports = authService;

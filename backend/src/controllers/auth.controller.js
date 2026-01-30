const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const firestore = require('@google-cloud/firestore');
const { v4: uuidv4 } = require('uuid');
const googleAuthService = require('../services/google-auth.service');
const db = new firestore.Firestore();
const generateTokens = (userId) => {
  const accessToken = jwt.sign(
    { userId, type: 'access' },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
  const refreshToken = jwt.sign(
    { userId, type: 'refresh' },
    process.env.JWT_SECRET,
    { expiresIn: '30d' }
  );
  return { accessToken, refreshToken };
};
const findOrCreateGoogleUser = async (googleProfile) => {
  try {
    let userQuery = await db.collection('users').where('googleId', '==', googleProfile.googleId).get();
    if (!userQuery.empty) {
      const userDoc = userQuery.docs[0];
      const userData = userDoc.data();
      await db.collection('users').doc(userData.id).update({
        name: googleProfile.name,
        picture: googleProfile.picture,
        lastLoginAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });
      return userData;
    }
    userQuery = await db.collection('users').where('email', '==', googleProfile.email).get();
    if (!userQuery.empty) {
      const userDoc = userQuery.docs[0];
      const userData = userDoc.data();
      await db.collection('users').doc(userData.id).update({
        googleId: googleProfile.googleId,
        picture: googleProfile.picture,
        lastLoginAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });
      return { ...userData, googleId: googleProfile.googleId };
    }
    const userId = uuidv4();
    const userData = {
      id: userId,
      email: googleProfile.email,
      name: googleProfile.name,
      googleId: googleProfile.googleId,
      picture: googleProfile.picture,
      emailVerified: googleProfile.emailVerified,
      authProvider: 'google',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      lastLoginAt: new Date().toISOString(),
      isActive: true,
      preferences: {
        theme: 'light',
        notifications: true,
        language: googleProfile.locale || 'en'
      },
      profile: {
        avatar: googleProfile.picture,
        bio: '',
        learningGoals: [],
        subjects: []
      }
    };
    await db.collection('users').doc(userId).set(userData);
    return userData;
  } catch (error) {
    console.error('Error finding/creating Google user:', error);
    throw error;
  }
};
const register = async (req, res) => {
  try {
    const { email, password, name } = req.body;
    const existingUser = await db.collection('users').where('email', '==', email).get();
    if (!existingUser.empty) {
      return res.status(400).json({
        success: false,
        error: { message: 'User already exists with this email' }
      });
    }
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const userId = uuidv4();
    const userData = {
      id: userId,
      email,
      name,
      password: hashedPassword,
      authProvider: 'email',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      isActive: true,
      preferences: {
        theme: 'light',
        notifications: true,
        language: 'en'
      },
      profile: {
        avatar: null,
        bio: '',
        learningGoals: [],
        subjects: []
      }
    };
    await db.collection('users').doc(userId).set(userData);
    const { accessToken, refreshToken } = generateTokens(userId);
    await db.collection('refresh_tokens').doc(userId).set({
      token: refreshToken,
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
    });
    delete userData.password;
    res.status(201).json({
      success: true,
      data: {
        user: userData,
        tokens: { accessToken, refreshToken }
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Registration failed' }
    });
  }
};
const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const userQuery = await db.collection('users').where('email', '==', email).get();
    if (userQuery.empty) {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid credentials' }
      });
    }
    const userDoc = userQuery.docs[0];
    const userData = userDoc.data();
    if (!userData.isActive) {
      return res.status(401).json({
        success: false,
        error: { message: 'Account is deactivated' }
      });
    }
    if (!userData.password) {
      return res.status(401).json({
        success: false,
        error: { message: 'Please sign in with Google' }
      });
    }
    const isValidPassword = await bcrypt.compare(password, userData.password);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid credentials' }
      });
    }
    const { accessToken, refreshToken } = generateTokens(userData.id);
    await db.collection('refresh_tokens').doc(userData.id).set({
      token: refreshToken,
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
    });
    await db.collection('users').doc(userData.id).update({
      lastLoginAt: new Date().toISOString()
    });
    delete userData.password;
    res.json({
      success: true,
      data: {
        user: userData,
        tokens: { accessToken, refreshToken }
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Login failed' }
    });
  }
};
const googleSignIn = async (req, res) => {
  try {
    const { idToken, clientType = 'web' } = req.body;
    if (!idToken) {
      return res.status(400).json({
        success: false,
        error: { message: 'Google ID token is required' }
      });
    }
    if (!googleAuthService.isConfigured()) {
      return res.status(500).json({
        success: false,
        error: { message: 'Google OAuth not configured on server' }
      });
    }
    const googleProfile = await googleAuthService.verifyGoogleToken(idToken, clientType);
    const userData = await findOrCreateGoogleUser(googleProfile);
    const { accessToken, refreshToken } = generateTokens(userData.id);
    await db.collection('refresh_tokens').doc(userData.id).set({
      token: refreshToken,
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
    });
    delete userData.password;
    res.json({
      success: true,
      data: {
        user: userData,
        tokens: { accessToken, refreshToken }
      }
    });
  } catch (error) {
    console.error('Google sign-in error:', error);
    res.status(401).json({
      success: false,
      error: { message: error.message || 'Google sign-in failed' }
    });
  }
};
const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        error: { message: 'Refresh token required' }
      });
    }
    const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);
    if (decoded.type !== 'refresh') {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid token type' }
      });
    }
    const tokenDoc = await db.collection('refresh_tokens').doc(decoded.userId).get();
    if (!tokenDoc.exists || tokenDoc.data().token !== refreshToken) {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid refresh token' }
      });
    }
    const { accessToken, refreshToken: newRefreshToken } = generateTokens(decoded.userId);
    await db.collection('refresh_tokens').doc(decoded.userId).update({
      token: newRefreshToken,
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
    });
    res.json({
      success: true,
      data: {
        tokens: { accessToken, refreshToken: newRefreshToken }
      }
    });
  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(401).json({
      success: false,
      error: { message: 'Token refresh failed' }
    });
  }
};
const logout = async (req, res) => {
  try {
    const userId = req.user.userId;
    await db.collection('refresh_tokens').doc(userId).delete();
    res.json({
      success: true,
      data: { message: 'Logged out successfully' }
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Logout failed' }
    });
  }
};
const getProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: { message: 'User not found' }
      });
    }
    const userData = userDoc.data();
    delete userData.password;
    res.json({
      success: true,
      data: { user: userData }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Failed to get profile' }
    });
  }
};
module.exports = {
  register,
  login,
  googleSignIn,
  refreshToken,
  logout,
  getProfile
};
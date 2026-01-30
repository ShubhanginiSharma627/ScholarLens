const express = require('express');
const router = express.Router();
const { register, login, googleSignIn, logout, refreshToken, getProfile } = require('../controllers/auth.controller');
const { authValidation, validateRequest, authenticateToken, createRateLimit } = require('../middleware/auth.middleware');
const authRateLimit = createRateLimit(15 * 60 * 1000, 5); // 5 attempts per 15 minutes
const generalRateLimit = createRateLimit(15 * 60 * 1000, 20); // 20 requests per 15 minutes
router.post('/register', authRateLimit, authValidation.register, validateRequest, register);
router.post('/login', authRateLimit, authValidation.login, validateRequest, login);
router.post('/google', authRateLimit, googleSignIn); // Google Sign-In endpoint
router.post('/refresh', generalRateLimit, refreshToken);
router.post('/logout', authenticateToken, logout);
router.get('/profile', authenticateToken, getProfile);
module.exports = router;
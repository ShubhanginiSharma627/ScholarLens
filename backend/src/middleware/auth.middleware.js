const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const rateLimit = require('express-rate-limit');

// JWT Authentication Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ 
      success: false, 
      error: { message: 'Access token required' } 
    });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ 
        success: false, 
        error: { message: 'Invalid or expired token' } 
      });
    }
    req.user = user;
    next();
  });
};

// Optional authentication (for public endpoints that can benefit from user context)
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token) {
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
      if (!err) {
        req.user = user;
      }
    });
  }
  next();
};

// Rate limiting middleware
const createRateLimit = (windowMs = 15 * 60 * 1000, max = 100) => {
  return rateLimit({
    windowMs,
    max,
    message: {
      success: false,
      error: { message: 'Too many requests, please try again later' }
    },
    standardHeaders: true,
    legacyHeaders: false,
  });
};

// Validation middleware
const validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: { 
        message: 'Validation failed',
        details: errors.array()
      }
    });
  }
  next();
};

// Common validation rules
const authValidation = {
  register: [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters long'),
    body('name').trim().isLength({ min: 2, max: 50 }),
  ],
  login: [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty(),
  ]
};

const aiValidation = {
  generateText: [
    body('prompt').trim().isLength({ min: 1, max: 5000 }),
    body('taskType').optional().isIn([
      'quick_explanation', 'detailed_analysis', 'flashcard_generation',
      'quiz_creation', 'chat_response', 'study_plan', 'concept_explanation'
    ]),
    body('complexity').optional().isIn(['low', 'medium', 'high'])
  ],
  analyzeImage: [
    body('prompt').trim().isLength({ min: 1, max: 2000 }),
  ]
};

module.exports = {
  authenticateToken,
  optionalAuth,
  createRateLimit,
  validateRequest,
  authValidation,
  aiValidation
};
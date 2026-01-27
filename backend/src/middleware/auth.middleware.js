const authService = require('../services/auth.service');

// JWT authentication middleware
const authenticate = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decoded = authService.verifyToken(token);
    if (!decoded) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Authentication failed' });
  }
};

// Input validation middleware
const validateInput = (requiredFields) => {
  return (req, res, next) => {
    const missingFields = requiredFields.filter(field => !req.body[field]);
    if (missingFields.length > 0) {
      return res.status(400).json({ error: `Missing required fields: ${missingFields.join(', ')}` });
    }
    next();
  };
};

// Error handler middleware
const errorHandler = (err, req, res, next) => {
  console.error(err);
  const status = err.status || 500;
  const message = err.message || 'Internal server error';
  res.status(status).json({ success: false, error: message });
};

// Rate limiting middleware (basic implementation)
const rateLimit = (maxRequests = 100, windowMs = 60000) => {
  const requests = new Map();

  return (req, res, next) => {
    const ip = req.ip;
    const now = Date.now();

    if (!requests.has(ip)) {
      requests.set(ip, []);
    }

    const timestamps = requests.get(ip).filter(t => now - t < windowMs);
    if (timestamps.length >= maxRequests) {
      return res.status(429).json({ error: 'Too many requests, please try again later' });
    }

    timestamps.push(now);
    requests.set(ip, timestamps);
    next();
  };
};

module.exports = { authenticate, validateInput, errorHandler, rateLimit };
const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { authenticate, validateInput } = require('../middleware/auth.middleware');

// Public routes
router.post('/register', validateInput(['email', 'password', 'name']), authController.register);
router.post('/login', validateInput(['email', 'password']), authController.login);

// Protected routes
router.post('/logout', authenticate, authController.logout);
router.get('/profile', authenticate, authController.getProfile);
router.put('/profile', authenticate, authController.updateProfile);

module.exports = router;
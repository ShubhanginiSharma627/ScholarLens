const authService = require('../services/auth.service');

exports.register = async (req, res) => {
  try {
    const { email, password, name } = req.body;
    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Email, password, and name are required' });
    }

    const user = await authService.registerUser(email, password, name);
    res.status(201).json({ success: true, data: user });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const user = await authService.loginUser(email, password);
    res.status(200).json({ success: true, data: user });
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
};

exports.logout = async (req, res) => {
  // Logout is typically handled on the client side by removing the token
  res.status(200).json({ success: true, message: 'Logged out successfully' });
};

exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const user = await authService.getUserById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(200).json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const updates = req.body;
    const user = await authService.updateUserProfile(userId, updates);
    res.status(200).json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
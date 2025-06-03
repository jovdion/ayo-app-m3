const express = require('express');
const router = express.Router();
const db = require('../config/database');
const jwt = require('jsonwebtoken');

// Middleware to verify JWT token
const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ message: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'ayo_app_secret_key_2024');
    req.userId = decoded.id;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid token' });
  }
};

// Get all users except the current user
router.get('/', verifyToken, async (req, res) => {
  try {
    console.log('Getting users list for user ID:', req.userId);
    
    const [users] = await db.execute(
      'SELECT id, username, email FROM users WHERE id != ?',
      [req.userId]
    );
    
    console.log('Found users:', users.length);
    res.json(users);
  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ 
      message: 'Error getting users',
      error: error.message 
    });
  }
});

// Get user profile
router.get('/profile/:userId', verifyToken, async (req, res) => {
  try {
    console.log('Getting profile for user ID:', req.params.userId);
    
    const [users] = await db.execute(
      'SELECT id, username, email FROM users WHERE id = ?',
      [req.params.userId]
    );
    
    if (users.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(users[0]);
  } catch (error) {
    console.error('Error getting user profile:', error);
    res.status(500).json({ 
      message: 'Error getting user profile',
      error: error.message 
    });
  }
});

module.exports = router; 
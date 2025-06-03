const express = require('express');
const router = express.Router();
const mysql = require('mysql2/promise');
const { v4: uuidv4 } = require('uuid');
const { authenticateToken } = require('../middleware/auth');
const dbConfig = require('../config/database');

// Get all users
router.get('/', authenticateToken, async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [users] = await connection.execute(
      'SELECT id, username, email, latitude, longitude, created_at, updated_at FROM users'
    );
    await connection.end();
    res.json(users);
  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ message: 'Error getting users' });
  }
});

// Get user by ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [users] = await connection.execute(
      'SELECT id, username, email, latitude, longitude, created_at, updated_at FROM users WHERE id = ?',
      [req.params.id]
    );
    await connection.end();

    if (users.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(users[0]);
  } catch (error) {
    console.error('Error getting user:', error);
    res.status(500).json({ message: 'Error getting user' });
  }
});

// Update user location
router.put('/location', authenticateToken, async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    
    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({ message: 'Latitude and longitude are required' });
    }

    const connection = await mysql.createConnection(dbConfig);
    await connection.execute(
      'UPDATE users SET latitude = ?, longitude = ? WHERE id = ?',
      [latitude, longitude, req.user.id]
    );
    await connection.end();

    res.json({ message: 'Location updated successfully' });
  } catch (error) {
    console.error('Error updating location:', error);
    res.status(500).json({ message: 'Error updating location' });
  }
});

module.exports = router; 
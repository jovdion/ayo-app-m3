const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../config/database');
const firebase = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');
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

// Get messages between two users
router.get('/messages/:otherUserId', verifyToken, async (req, res) => {
  try {
    console.log('Getting messages between users:', req.userId, req.params.otherUserId);
    
    const [messages] = await db.execute(
      `SELECT * FROM messages 
       WHERE (sender_id = ? AND receiver_id = ?) 
       OR (sender_id = ? AND receiver_id = ?)
       ORDER BY created_at ASC`,
      [req.userId, req.params.otherUserId, req.params.otherUserId, req.userId]
    );
    
    // Transform the messages to match the client model
    const transformedMessages = messages.map(msg => ({
      id: msg.id.toString(),
      senderId: msg.sender_id.toString(),
      receiverId: msg.receiver_id.toString(),
      content: msg.content,
      createdAt: msg.created_at,
      updatedAt: msg.updated_at,
    }));
    
    res.json(transformedMessages);
  } catch (error) {
    console.error('Error getting messages:', error);
    res.status(500).json({ 
      message: 'Error getting messages',
      error: error.message 
    });
  }
});

// Send a message
router.post('/send', verifyToken, async (req, res) => {
  try {
    console.log('Received request body:', req.body);
    const { receiverId, content } = req.body;
    
    // Detailed validation logging
    console.log('Validation check:');
    console.log('receiverId:', receiverId, typeof receiverId);
    console.log('content:', content, typeof content);
    
    if (!content) {
      console.log('Content is missing or empty');
      return res.status(400).json({ 
        message: 'Missing required fields',
        detail: 'Content is required' 
      });
    }
    
    if (!receiverId) {
      console.log('ReceiverId is missing or empty');
      return res.status(400).json({ 
        message: 'Missing required fields',
        detail: 'ReceiverId is required'
      });
    }

    // Format timestamp for MySQL (YYYY-MM-DD HH:mm:ss)
    const now = new Date();
    const timestamp = now.toISOString().slice(0, 19).replace('T', ' ');
    
    console.log('Inserting message with values:', {
      senderId: req.userId,
      receiverId,
      content,
      timestamp
    });

    const [result] = await db.execute(
      'INSERT INTO messages (sender_id, receiver_id, content, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
      [req.userId, receiverId, content, timestamp, timestamp]
    );

    const message = {
      id: result.insertId.toString(),
      senderId: req.userId.toString(),
      receiverId: receiverId.toString(),
      content: content,
      createdAt: now.toISOString(),  // Send back ISO format for frontend
      updatedAt: now.toISOString(),  // Send back ISO format for frontend
    };

    console.log('Message saved successfully:', message);
    res.status(201).json(message);
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ 
      message: 'Error sending message',
      error: error.message 
    });
  }
});

// Get chat history
router.get('/history/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const currentUserId = req.user.id;

    const [messages] = await db.execute(
      `SELECT * FROM messages 
       WHERE (sender_id = ? AND receiver_id = ?)
       OR (sender_id = ? AND receiver_id = ?)
       ORDER BY created_at DESC
       LIMIT 50`,
      [currentUserId, userId, userId, currentUserId]
    );

    res.json(messages);
  } catch (error) {
    console.error('Error fetching chat history:', error);
    res.status(500).json({ message: 'Error fetching chat history' });
  }
});

// Update FCM token
router.put('/token', auth, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    const userId = req.user.id;

    await db.execute(
      'UPDATE users SET fcm_token = ? WHERE id = ?',
      [fcmToken, userId]
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Error updating FCM token:', error);
    res.status(500).json({ message: 'Error updating FCM token' });
  }
});

module.exports = router; 
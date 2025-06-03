const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../config/database');
const firebase = require('../config/firebase');

// Send message
router.post('/send', auth, async (req, res) => {
  try {
    const { receiverId, message } = req.body;
    const senderId = req.user.id;

    // Store message in MySQL
    const [result] = await db.execute(
      'INSERT INTO messages (sender_id, receiver_id, message, created_at) VALUES (?, ?, ?, NOW())',
      [senderId, receiverId, message]
    );

    // Get receiver's FCM token from database
    const [rows] = await db.execute(
      'SELECT fcm_token FROM users WHERE id = ?',
      [receiverId]
    );

    if (rows.length > 0 && rows[0].fcm_token) {
      // Send push notification
      await firebase.sendNotification(
        rows[0].fcm_token,
        'New Message',
        message,
        {
          messageId: result.insertId.toString(),
          senderId: senderId.toString(),
        }
      );
    }

    res.status(201).json({
      success: true,
      messageId: result.insertId
    });
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ message: 'Error sending message' });
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
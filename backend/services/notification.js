const { messaging } = require('../config/firebase');
const db = require('../config/database');

class NotificationService {
  static async sendMessageNotification(senderId, receiverId, message) {
    try {
      // Get receiver's FCM token
      const [rows] = await db.execute(
        'SELECT fcm_token, username FROM users WHERE id = ?',
        [receiverId]
      );

      if (rows.length === 0 || !rows[0].fcm_token) {
        console.log('No FCM token found for user:', receiverId);
        return;
      }

      // Get sender's username
      const [senderRows] = await db.execute(
        'SELECT username FROM users WHERE id = ?',
        [senderId]
      );

      if (senderRows.length === 0) {
        console.log('Sender not found:', senderId);
        return;
      }

      const notification = {
        notification: {
          title: `New message from ${senderRows[0].username}`,
          body: message,
        },
        data: {
          senderId: senderId.toString(),
          type: 'message',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        token: rows[0].fcm_token,
      };

      const response = await messaging.send(notification);
      console.log('Successfully sent notification:', response);
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  }

  static async sendLocationUpdateNotification(userId, nearbyUserIds) {
    try {
      // Get user's username
      const [userRows] = await db.execute(
        'SELECT username FROM users WHERE id = ?',
        [userId]
      );

      if (userRows.length === 0) {
        console.log('User not found:', userId);
        return;
      }

      // Get FCM tokens for nearby users
      const [tokenRows] = await db.execute(
        'SELECT fcm_token FROM users WHERE id IN (?) AND fcm_token IS NOT NULL',
        [nearbyUserIds]
      );

      const tokens = tokenRows.map(row => row.fcm_token).filter(Boolean);
      if (tokens.length === 0) {
        console.log('No valid FCM tokens found for nearby users');
        return;
      }

      const notification = {
        notification: {
          title: 'New User Nearby',
          body: `${userRows[0].username} is now in your area!`,
        },
        data: {
          userId: userId.toString(),
          type: 'location_update',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        tokens: tokens,
      };

      const response = await messaging.sendMulticast(notification);
      console.log('Successfully sent notifications:', response);
    } catch (error) {
      console.error('Error sending notifications:', error);
    }
  }
}

module.exports = NotificationService; 
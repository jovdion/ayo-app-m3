const crypto = require('crypto');

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || crypto.randomBytes(32); // 256 bit key
const IV_LENGTH = 16; // For AES, this is always 16

function encrypt(text) {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv('aes-256-gcm', Buffer.from(ENCRYPTION_KEY), iv);
  
  let encrypted = cipher.update(text);
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  const authTag = cipher.getAuthTag();
  
  return {
    iv: iv.toString('hex'),
    encrypted: Buffer.concat([encrypted, authTag]).toString('hex')
  };
}

function decrypt(encrypted, iv) {
  const decipher = crypto.createDecipheriv('aes-256-gcm', Buffer.from(ENCRYPTION_KEY), Buffer.from(iv, 'hex'));
  
  const encryptedText = Buffer.from(encrypted, 'hex');
  const authTag = encryptedText.slice(-16); // Last 16 bytes is auth tag
  const data = encryptedText.slice(0, -16); // Everything except last 16 bytes is data
  
  decipher.setAuthTag(authTag);
  
  let decrypted = decipher.update(data);
  decrypted = Buffer.concat([decrypted, decipher.final()]);
  return decrypted.toString();
}

function encryptLocation(latitude, longitude) {
  const locationData = JSON.stringify({ latitude, longitude });
  return encrypt(locationData);
}

function decryptLocation(encryptedData, iv) {
  if (!encryptedData || !iv) return null;
  
  try {
    const decrypted = decrypt(encryptedData, iv);
    return JSON.parse(decrypted);
  } catch (error) {
    console.error('Error decrypting location:', error);
    return null;
  }
}

module.exports = {
  encryptLocation,
  decryptLocation
}; 
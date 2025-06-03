const mysql = require('mysql2/promise');
require('dotenv').config();

async function setupDatabase() {
  try {
    // 1. Koneksi tanpa database
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      // Tambahkan database di sini:
      database: process.env.DB_NAME,
    });

    // 2. Buat database jika belum ada
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${process.env.DB_NAME}\`;`);
    await connection.end();

    // 3. Koneksi ulang dengan database
    const db = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      port: process.env.PORT,
      multipleStatements: true,
    });

    // 4. Lanjutkan setup tabel dsb di sini
    // await db.query('CREATE TABLE ...');
    await db.end();

    console.log('Database setup completed successfully');
    
  } catch (error) {
    console.error('Error setting up database:', error);
    process.exit(1);
  }
}

setupDatabase().catch(console.error);
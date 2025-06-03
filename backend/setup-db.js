const mysql = require('mysql2/promise');
const fs = require('fs').promises;
const path = require('path');
require('dotenv').config();

async function setupDatabase() {
  try {
    // 1. Koneksi tanpa database
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
    });

    console.log('Connected to MySQL server');

    // 2. Buat database jika belum ada
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${process.env.DB_NAME}\`;`);
    console.log(`Database ${process.env.DB_NAME} created or already exists`);
    await connection.end();

    // 3. Koneksi ulang dengan database
    const db = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      multipleStatements: true,
    });

    console.log(`Connected to database ${process.env.DB_NAME}`);

    // 4. Baca dan jalankan file database.sql
    const sqlPath = path.join(__dirname, 'database.sql');
    const sql = await fs.readFile(sqlPath, 'utf8');
    
    console.log('Executing database.sql...');
    await db.query(sql);
    console.log('Database tables created successfully');

    await db.end();
    console.log('Database setup completed successfully');
    
  } catch (error) {
    console.error('Error setting up database:', error);
    process.exit(1);
  }
}

setupDatabase().catch(console.error);
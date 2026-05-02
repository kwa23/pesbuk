const express = require('express');
const Database = require('better-sqlite3');
const argon2 = require('argon2');

const app = express();
const db = new Database('/app/data/database.db');

// Buat tabel users jika belum ada
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    firstname TEXT,
    lastname TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ============================================================
// FITUR XSS: Security Headers
// ============================================================
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Content-Security-Policy', "default-src 'self'; style-src 'self' 'unsafe-inline'");
  next();
});

app.use(express.static('public'));

// ============================================================
// HELPER: Sanitasi input — mencegah XSS
// ============================================================
function sanitize(str) {
  if (typeof str !== 'string') return '';
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .trim();
}

// ============================================================
// HELPER: Validasi format email atau nomor telepon
// ============================================================
function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  const phoneRegex = /^[0-9]{9,15}$/;
  return emailRegex.test(email) || phoneRegex.test(email);
}

// ============================================================
// POST /register.php
// Hash password menggunakan Argon2
// ============================================================
app.post('/register.php', async (req, res) => {
  const firstname = sanitize(req.body.firstname);
  const lastname  = sanitize(req.body.lastname);
  const email     = sanitize(req.body.email);
  const password  = req.body.newpassword;

  // Validasi input tidak boleh kosong
  if (!firstname || !lastname || !email || !password) {
    return res.status(400).send('<p>Semua field harus diisi. <a href="/register.html">Kembali</a></p>');
  }

  // Validasi format email/telepon
  if (!isValidEmail(email)) {
    return res.status(400).send('<p>Format email atau nomor telepon tidak valid. <a href="/register.html">Kembali</a></p>');
  }

  // Validasi panjang password minimal 6 karakter
  if (password.length < 6) {
    return res.status(400).send('<p>Password minimal 6 karakter. <a href="/register.html">Kembali</a></p>');
  }

  try {
    // ARGON2: Hash password 
    // - type argon2id : kombinasi argon2i + argon2d 
    // - timeCost      : jumlah iterasi
    // - memoryCost    : memori yang digunakan dalam KB (65536 = 64MB)
    // - parallelism   : jumlah thread
    const hashedPassword = await argon2.hash(password, {
      type: argon2.argon2id,
      timeCost: 3,
      memoryCost: 65536,
      parallelism: 1
    });

    // FITUR SQL INJECTION: Prepared statement
    db.prepare(`INSERT INTO users (email, password, firstname, lastname) VALUES (?, ?, ?, ?)`)
      .run(email, hashedPassword, firstname, lastname);

    res.send('<p>Registrasi berhasil! <a href="/login.html">Login di sini</a></p>');
  } catch (e) {
    res.status(400).send('<p>Email atau nomor HP sudah terdaftar. <a href="/register.html">Kembali</a></p>');
  }
});

// ============================================================
// POST /login.php
// Verifikasi password menggunakan Argon2
// ============================================================
app.post('/login.php', async (req, res) => {
  const username = sanitize(req.body.username);
  const password = req.body.password;

  // Validasi input tidak boleh kosong
  if (!username || !password) {
    return res.status(400).send('<p>Email dan password harus diisi. <a href="/login.html">Kembali</a></p>');
  }

  // FITUR SQL INJECTION: Prepared statement
  const user = db.prepare(`SELECT * FROM users WHERE email = ?`).get(username);

  // Pesan error dibuat sama agar tidak memberi petunjuk ke attacker
  if (!user) {
    return res.status(401).send('<p>Email atau password salah. <a href="/login.html">Coba lagi</a></p>');
  }

  try {
    // ARGON2: Verifikasi password input dengan hash di database
    const cocok = await argon2.verify(user.password, password);

    if (cocok) {
      res.send(`<p>Selamat datang, ${user.firstname}! Login berhasil.</p>`);
    } else {
      res.status(401).send('<p>Email atau password salah. <a href="/login.html">Coba lagi</a></p>');
    }
  } catch (e) {
    res.status(500).send('<p>Terjadi kesalahan server. <a href="/login.html">Coba lagi</a></p>');
  }
});

app.listen(3000, () => console.log('Server jalan di port 3000'));

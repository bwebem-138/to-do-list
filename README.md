# 🔒 Secure Todo List Application

A secure task management application built with Flask and MariaDB, featuring encrypted data storage, user authentication, and HTTPS support.

## ⚠️ Security Notice

**CRITICAL:** Before deploying this application:

1. Replace ALL default credentials:
   ```powershell
   # Generate new encryption key
   $key = "1;" + -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
   $key | Out-File -FilePath "config/mysql/encryption/keyfile" -Encoding ASCII -NoNewLine
   ```

2. Update these security-critical files:
   - `docker-compose.yml`: Database passwords
   - `config/mysql/encryption/keyfile`: Encryption key
   - `.env`: Environment variables
   - SSL certificates

## 🎯 Features

- ✅ Secure user authentication
- 🔐 Encrypted data storage
- 📝 Task management
- 👤 User account controls
- 🔒 HTTPS support
- 🐳 Docker deployment

## 🛠️ Technology Stack

| Component | Technology |
|-----------|------------|
| Backend | Python/Flask |
| Database | MariaDB (Encrypted) |
| Server | Gunicorn |
| SSL | Self-signed |
| Containerization | Docker |
| Frontend | HTML/CSS |

## 📦 Installation

```powershell
# Clone repository
git clone https://github.com/bwebem-138/to-do-list.git

# Navigate to project
cd to-do-list

# Generate new encryption key
$key = "1;" + -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$key | Out-File -FilePath "config/mysql/encryption/keyfile" -Encoding ASCII -NoNewLine

# Create .env file (optional but recommended)
@"
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_USER=your_db_user
MYSQL_PASSWORD=your_secure_password
MYSQL_DATABASE=todo_db
FLASK_SECRET_KEY=your_secure_secret_key
"@ | Out-File -FilePath ".env" -Encoding UTF8

# Update security credentials either in .env or directly in these files:
# 1. docker-compose.yml - Change these values:
#    - MYSQL_ROOT_PASSWORD
#    - MYSQL_PASSWORD
#    - MYSQL_USER (optional)
#
# 2. app.py - Replace the secret key:
#    app.secret_key = os.urandom(24)

# Add .env to .gitignore
.env

# Build and run
docker-compose up --build
```

## 🏗️ Project Structure

```
to-do-list/
├── app/
│   ├── static/
│   │   └── styles.css
│   ├── templates/
│   │   ├── base.html
│   │   ├── login.html
│   │   ├── register.html
│   │   └── tasks.html
│   ├── app.py
│   └── requirements.txt
├── config/
│   ├── mysql/
│   │   └── encryption/
│   │       └── keyfile
│   └── encryption.cnf
├── ssl/                    # SSL certificates
│   ├── cert.pem            # Public certificate
│   ├── certificate.pfx     # PKCS#12 bundle
│   └── key.pem             # Private key
├── database.sql
├── docker-compose.yml
├── Dockerfile
├── generate-certs.ps1      # Certificate generation script (make sure openssl is installed)
├── .env                    # Optional (recomended): Environment variables
├── .gitignore              # Git ignore rules
└── README.md
```

## 🚀 Quick Start

1. Clone the repository
2. Generate SSL certificates:
   ```powershell
   ./init-ssl.sh
   ```

3. Set up environment variables:
   ```powershell
   Copy-Item .env.example .env
   # Edit .env with your values
   ```

4. Start the application:
   ```powershell
   docker-compose up --build
   ```

## 🔒 SSL Configuration

- Development: Self-signed certificates
- Production: Let's Encrypt certificates via Certbot

## 🌐 Access

- HTTP: http://localhost:80
- HTTPS: https://localhost:443
- Domain: https://todolists.ch (if configured)

## ⚙️ Environment Variables

Required variables in `.env`:
- `MYSQL_ROOT_PASSWORD`
- `MYSQL_USER`
- `MYSQL_PASSWORD`
- `MYSQL_DATABASE`
- `FLASK_SECRET_KEY`

## ⚠️ Disclaimer

This code is provided as an educational example and should not be used in productive environments.

*Remember to replace all default credentials before deployment!*
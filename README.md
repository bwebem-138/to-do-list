# 🔒 Secure Todo List Application

A secure task management application built with Flask and MariaDB, featuring encrypted data storage, user authentication, and HTTPS support.

## 🎯 Features

- ✅ Secure user authentication
- 🔐 Encrypted database storage
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

## ⚙️ Prerequisites

### Windows
- Docker Desktop
- Git
- OpenSSL (`choco install openssl`)
- PowerShell 5.0+

### Linux
- Docker Engine & Compose
- Git
- OpenSSL
- Bash

## 📥 Installation

### Windows

```powershell
# Clone and enter directory
git clone https://github.com/yourusername/to-do-list.git
cd to-do-list

# Create required directories
mkdir -p config/mysql/encryption ssl

# Run installer (as Administrator)
Set-ExecutionPolicy Bypass -Scope Process
.\install.sh
```

### Linux

```bash
# Clone and enter directory
git clone https://github.com/yourusername/to-do-list.git
cd to-do-list

# Make script executable and run
chmod +x install.sh
sudo ./install.sh
```

## 🏗️ Project Structure

```
to-do-list/
```
to-do-list/
├── app/                    # Application code
│   ├── static/            # Static assets
│   │   ├── styles.css
│   │   └── js/           # JavaScript files
│   │       └── script.js
│   ├── templates/         # HTML templates
│   │   ├── base.html
│   │   ├── login.html
│   │   ├── register.html
│   │   └── tasks.html
│   ├── app.py            # Main application file
│   └── requirements.txt  # Python dependencies
├── config/               # Configuration directory
│   ├── mysql/           # MySQL specific config
│   │   └── encryption/  # Encryption settings
│   │       └── keyfile  # Database encryption key
│   └── encryption.cnf   # MariaDB encryption config
├── ssl/                 # SSL certificates
│   ├── cert.pem         # Public certificate
│   ├── key.pem          # Private key
├── database.sql         # Database schema
├── docker-compose.yml   # Docker configuration
├── Dockerfile          # Application container
├── generate-certs.ps1  # SSL certificate generator
├── install.sh         # Installation script
├── .env              # Environment variables (generated)
├── .gitignore       # Git ignore rules
└── README.md        # Project documentation
```
```

## 🔧 Troubleshooting

### Database Reset

Windows:
```powershell
docker compose down -v
Remove-Item -Recurse -Force mariadb_data, config/mysql/encryption
docker compose up -d
```

Linux:
```bash
docker compose down -v
sudo rm -rf mariadb_data config/mysql/encryption
docker compose up -d
```

### Web Access Issues
```bash
docker compose restart web
```

## ⚠️ Security Notes

- Replace default credentials before deployment
- Never commit sensitive files (.env, keyfile, certificates)
- This is an educational example - review security before production use

## ⚠️ Disclaimer

This code is provided as an educational example and should not be used in production environments without proper security review.

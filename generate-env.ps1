# Generate secure random values
$rootPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$userPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$flaskKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})
$encKey = "1;" + -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$certPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$domainName = "yourdomain.com"  # Replace with your actual domain name

# Create .env file
@"
# Database Configuration
MYSQL_HOST=db
MYSQL_ROOT_PASSWORD=$rootPassword
MYSQL_USER=todo_user
MYSQL_PASSWORD=$userPassword
MYSQL_DATABASE=todo_db

# Flask Configuration
FLASK_APP=app.py
FLASK_SECRET_KEY=$flaskKey
FLASK_DEBUG=0
FLASK_HOST=0.0.0.0
FLASK_PORT=443

# SSL Configuration
SSL_CERT_PATH=/ssl/cert.pem
SSL_KEY_PATH=/ssl/key.pem
SSL_PFX_PATH=/ssl/certificate.pfx
CERT_PASSWORD=$certPassword
CERT_DOMAIN=$domainName
CERT_FRIENDLY_NAME=$domainName SSL Certificate

# Encryption Configuration
DB_ENCRYPTION_KEY=$encKey

# Domain Configuration
DOMAIN_NAME=$domainName
"@ | Out-File -FilePath ".env" -Encoding UTF8

Write-Host "Environment file created successfully!"
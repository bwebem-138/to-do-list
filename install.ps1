# Todo List Application Setup Script
$ErrorActionPreference = "Stop"

function Test-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    $prerequisites = @{
        "Docker" = "docker --version";
        "Git" = "git --version";
        "OpenSSL" = "openssl version"
    }

    $missingPrereqs = @()
    foreach ($prereq in $prerequisites.Keys) {
        Write-Host "   Checking $prereq..." -NoNewline
        if ([bool](Get-Command -Name ($prerequisites[$prereq].Split()[0]) -ErrorAction SilentlyContinue)) {
            Write-Host "Ok" -ForegroundColor Green
        } else {
            Write-Host "Error" -ForegroundColor Red
            $missingPrereqs += $prereq
        }
    }

    if ($missingPrereqs.Count -gt 0) {
        throw "Missing prerequisites: $($missingPrereqs -join ', ')"
    }
}

function New-EnvironmentFile {
    Write-Host "Generating secure credentials..." -ForegroundColor Yellow
    
    # Generate secure random values
    $rootPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    $userPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    $flaskKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})
    $encKey = "1;" + -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    $domainName = Read-Host "Enter your domain name (e.g., example.com)"
    $emailAddress = Read-Host "Enter your email address for SSL certificates"

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
FLASK_PORT=8000

# Encryption Configuration
DB_ENCRYPTION_KEY=$encKey

# Domain Configuration
DOMAIN_NAME=$domainName
TRAEFIK_ACME_EMAIL=$emailAddress
"@ | Out-File -FilePath ".env" -Encoding UTF8

    Write-Host "   Environment file created successfully" -ForegroundColor Green
}

function New-SSLCertificates {
    Write-Host "Generating SSL certificates..." -ForegroundColor Yellow
    
    # Create SSL directory if it doesn't exist
    if (-not (Test-Path ssl)) {
        New-Item -ItemType Directory -Path ssl | Out-Null
    }

    # Generate self-signed certificate using openssl
    $domainName = $env:DOMAIN_NAME
    if (-not $domainName) {
        $domainName = "localhost"
    }

    # Generate SSL certificate and key
    openssl req -x509 -newkey rsa:2048 -keyout ssl/key.pem -out ssl/cert.pem -days 365 -nodes `
        -subj "/CN=$domainName" `
        -addext "subjectAltName=DNS:$domainName" `
        -addext "keyUsage=digitalSignature,keyEncipherment" `
        -addext "extendedKeyUsage=serverAuth"

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to generate SSL certificates"
    }

    Write-Host "   SSL certificates generated successfully" -ForegroundColor Green
}

function Start-Containers {
    Write-Host "Starting Docker containers..." -ForegroundColor Yellow
    
    docker compose down --remove-orphans
    docker compose up --build -d

    Write-Host "   Docker containers started successfully" -ForegroundColor Green
}

function New-DatabaseEncryption {
    Write-Host "Setting up database encryption..." -ForegroundColor Yellow
    
    # Create encryption directory
    $encryptionPath = "config\mysql\encryption"
    New-Item -ItemType Directory -Path $encryptionPath -Force | Out-Null

    # Generate encryption key if not in environment
    $encKey = $env:DB_ENCRYPTION_KEY
    if (-not $encKey) {
        $encKey = "1;" + (New-Guid).ToString().Replace("-", "")
        [Environment]::SetEnvironmentVariable("DB_ENCRYPTION_KEY", $encKey)
    }

    # Write encryption key to keyfile
    $encKey | Out-File -FilePath "$encryptionPath\keyfile" -Encoding utf8 -NoNewline
    
    # Create encryption configuration
    @"
[mysqld]
plugin_load_add=file_key_management
file_key_management_filename=/etc/mysql/encryption/keyfile
file_key_management_encryption_algorithm=AES_CTR
file_key_management_filekey=FILE:/etc/mysql/encryption/keyfile
innodb_encrypt_tables=ON
innodb_encrypt_log=ON
innodb_encryption_threads=4
innodb_encryption_rotate_key_age=1
"@ | Out-File -FilePath "config\encryption.cnf" -Encoding utf8

    Write-Host "   Database encryption configured successfully" -ForegroundColor Green
}

# Main setup process
try {
    Write-Host "Starting Todo List Application Setup..." -ForegroundColor Cyan

    # Check administrator privileges
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        throw "Please run this script as Administrator!"
    }

    Test-Prerequisites
    New-EnvironmentFile
    New-DatabaseEncryption
    New-SSLCertificates
    Start-Containers

    Write-Host "Setup completed successfully!" -ForegroundColor Green
    Write-Host "Next steps:"
    Write-Host "1. Access the application at https://$($env:DOMAIN_NAME)"
    Write-Host "2. Review the generated .env file for your credentials"
    Write-Host "Important Notes:"
    Write-Host "- SSL certificates are in the ./ssl directory"
    Write-Host "- The database may take a few minutes to initialize"
    Write-Host "- If you see connection errors, wait and then run:"
    Write-Host "  docker compose up -d web"

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Exit 1
}
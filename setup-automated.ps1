# Setup script for Todo List Application
Write-Host "Starting Todo List Application Setup..." -ForegroundColor Cyan

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator!" -ForegroundColor Red
    Exit
}

# Function to check if a command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
$prerequisites = @{
    "Docker" = "docker --version";
    "Git" = "git --version";
    "OpenSSL" = "openssl version"
}

$missingPrereqs = @()
foreach ($prereq in $prerequisites.Keys) {
    Write-Host "   Checking $prereq..." -NoNewline
    if (Test-Command ($prerequisites[$prereq].Split()[0])) {
        Write-Host "OK" -ForegroundColor Green
    } else {
        Write-Host "Error" -ForegroundColor Red
        $missingPrereqs += $prereq
    }
}

if ($missingPrereqs.Count -gt 0) {
    Write-Host "Missing prerequisites: $($missingPrereqs -join ', ')" -ForegroundColor Red
    Write-Host "Please install the missing prerequisites and try again."
    Exit
}

# Create required directories
Write-Host "Creating required directories..." -ForegroundColor Yellow
$directories = @("ssl", "config/mysql/encryption")
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Write-Host "   Created $dir directory" -ForegroundColor Green
    }
}

# Generate environment variables
Write-Host "Generating environment variables..." -ForegroundColor Yellow
try {
    & .\generate-env.ps1
    Write-Host "   Environment variables generated successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to generate environment variables: $_" -ForegroundColor Red
    Exit
}

# Generate SSL certificates
Write-Host "Generating SSL certificates..." -ForegroundColor Yellow
try {
    # Read the certificate password before generating certs
    $envContent = Get-Content .env
    $certPassword = ""
    foreach ($line in $envContent) {
        if ($line -match '^CERT_PASSWORD=(.+)$') {
            $certPassword = $matches[1]
        }
    }

    Write-Host "Certificate Password (save this): $certPassword" -ForegroundColor Cyan
    Write-Host "You will need this password when prompted for the 'Import Password'`n" -ForegroundColor Yellow
    
    & .\generate-certs.ps1
    Write-Host "   SSL certificates generated successfully" -ForegroundColor Green
    
    # Remind the password again after generation
    Write-Host "Remember: The certificate password is: $certPassword" -ForegroundColor Cyan
    
} catch {
    Write-Host "Failed to generate SSL certificates: $_" -ForegroundColor Red
    Exit
}

# Start Docker containers
Write-Host "Starting Docker containers..." -ForegroundColor Yellow
try {
    docker compose down --remove-orphans
    docker compose up --build -d
    Write-Host "   Docker containers started successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to start Docker containers: $_" -ForegroundColor Red
    Exit
}

# Final setup verification
Write-Host "Setup completed successfully!" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "1. Access the application at https://localhost:443"
Write-Host "2. Review the generated .env file for your credentials"
Write-Host "3. Make sure to backup your SSL certificates in the ssl/ directory"
Write-Host "   - certificate.pfx (Certificate with private key)"
Write-Host "   - cert.pem (Public certificate)"
Write-Host "   - key.pem (Private key)"
Write-Host "Important: Keep your .env file and SSL certificates secure!"
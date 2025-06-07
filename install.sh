#!/bin/bash

set -e

# Colors for output
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m' # No color

function check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    local missing=()

    for cmd in docker git openssl; do
        echo -n "   Checking $cmd... "
        if command -v "$cmd" >/dev/null 2>&1; then
            echo -e "${GREEN}Ok${NC}"
        else
            echo -e "${RED}Missing${NC}"
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Missing prerequisites: ${missing[*]}${NC}"
        exit 1
    fi
}

function generate_password() {
    local length=$1
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length"
}

function create_env_file() {
    echo -e "${YELLOW}Generating secure credentials...${NC}"

    ROOT_PASSWORD=$(generate_password 32)
    USER_PASSWORD=$(generate_password 32)
    FLASK_KEY=$(generate_password 64)
    ENC_KEY="1;$(generate_password 32)"

    read -rp "Enter your domain name (e.g., example.com): " DOMAIN_NAME
    read -rp "Enter your email address for SSL certificates: " EMAIL_ADDRESS

    cat > .env <<EOF
# Database Configuration
MYSQL_HOST=db
MYSQL_ROOT_PASSWORD=$ROOT_PASSWORD
MYSQL_USER=todo_user
MYSQL_PASSWORD=$USER_PASSWORD
MYSQL_DATABASE=todo_db

# Flask Configuration
FLASK_APP=app.py
FLASK_SECRET_KEY=$FLASK_KEY
FLASK_DEBUG=0
FLASK_HOST=0.0.0.0
FLASK_PORT=8000

# Encryption Configuration
DB_ENCRYPTION_KEY=$ENC_KEY

# Domain Configuration
DOMAIN_NAME=$DOMAIN_NAME
TRAEFIK_ACME_EMAIL=$EMAIL_ADDRESS
EOF

    echo -e "   ${GREEN}.env file created successfully${NC}"
}

function create_ssl_certificates() {
    echo -e "${YELLOW}Generating SSL certificates...${NC}"

    # Ensure SSL directory exists and is clean
    rm -rf ssl
    mkdir -p ssl
    local CN="${DOMAIN_NAME:-localhost}"

    # Generate SSL certificates
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout ssl/key.pem -out ssl/cert.pem \
        -days 365 \
        -subj "/CN=$CN" \
        -addext "subjectAltName=DNS:$CN" \
        -addext "keyUsage=digitalSignature,keyEncipherment" \
        -addext "extendedKeyUsage=serverAuth"

    # Set proper permissions for container
    chmod 644 ssl/*.pem

    echo -e "   ${GREEN}SSL certificates generated successfully${NC}"
}

function setup_database_encryption() {
    echo -e "${YELLOW}Setting up database encryption...${NC}"
    
    # Clean up existing encryption files
    rm -rf config/mysql/encryption
    rm -f config/encryption.cnf
    
    # Create encryption directory
    mkdir -p config/mysql/encryption
    
    # Generate encryption key file
    KEY1=$(openssl rand -hex 32)
    echo "1;${KEY1}" > config/mysql/encryption/keyfile
    
    # Create encryption configuration file with proper settings
    cat > config/encryption.cnf << 'EOF'
[mysqld]
plugin_load_add=file_key_management
file_key_management
file_key_management_filename=/etc/mysql/encryption/keyfile
file_key_management_filekey=FILE:/etc/mysql/encryption/keyfile
innodb_file_per_table=ON
innodb_encrypt_tables=ON
innodb_encrypt_log=ON
innodb_encryption_threads=4
innodb_encryption_rotate_key_age=1
innodb_tablespace_encryption=ON
EOF

    # Set proper permissions
    chmod 644 config/mysql/encryption/keyfile
    chmod 644 config/encryption.cnf
    chmod 755 config/mysql/encryption

    echo -e "   ${GREEN}Database encryption configured successfully${NC}"
}

function start_containers() {
    echo -e "${YELLOW}Starting Docker containers...${NC}"

    docker compose down --remove-orphans
    docker compose up --build -d

    echo -e "   ${GREEN}Docker containers started successfully${NC}"
}

# Main script logic
echo -e "${CYAN}Starting Todo List Application Setup...${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script as root (sudo).${NC}"
    exit 1
fi

check_prerequisites
create_env_file
setup_database_encryption
create_ssl_certificates
start_containers

echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "Next steps:"
echo -e "1. Access the application at https://${DOMAIN_NAME}"
echo -e "2. Review the generated .env file for your credentials"
echo -e "${YELLOW}Important Notes:${NC}"
echo -e "- SSL certificates are in the ./ssl directory"
echo -e "- The database may take a few minutes to initialize"
echo -e "- If you see connection errors, wait and then run:"
echo -e "  docker compose up -d web"

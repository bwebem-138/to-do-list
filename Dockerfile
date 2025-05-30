FROM python:3.11-slim

WORKDIR /app

# Install necessary system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libmariadb-dev \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and app files
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application files
COPY app/ .

# Create SSL directory
RUN mkdir -p /app/ssl

# Use Gunicorn with SSL
CMD ["gunicorn", \
     "--bind", "0.0.0.0:80", \
     "--bind", "0.0.0.0:443", \
     "--certfile", "/app/ssl/cert.pem", \
     "--keyfile", "/app/ssl/key.pem", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "app:app"]

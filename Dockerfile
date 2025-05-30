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

# Set Flask environment variables
ENV FLASK_APP=app.py
ENV FLASK_ENV=development
ENV FLASK_DEBUG=1

# Run the Flask application
CMD ["python", "app.py"]

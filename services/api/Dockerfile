# Use official Python image as base
FROM python:3.13-slim

# Set working directory inside container
WORKDIR /app

# Copy dependency file first (for better layer caching)
COPY requirements.txt .

# Install dependencies
RUN apt-get update && apt-get install -y curl
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app

# Expose internal application port
EXPOSE 8000

# Command to start the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

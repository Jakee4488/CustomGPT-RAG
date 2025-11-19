# Multi-stage build for CustomGPT-RAG
FROM python:3.10-slim as base

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p /app/SOURCE_DOCUMENTS /app/DB /app/models

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DEVICE_TYPE=cpu
ENV MODEL_DIRECTORY=/app/models
ENV SOURCE_DIRECTORY=/app/SOURCE_DOCUMENTS
ENV PERSIST_DIRECTORY=/app/DB

# Expose ports
# 5110 for API, 5111 for UI
EXPOSE 5110 5111

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:5110/health || exit 1

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Start API server in background\n\
echo "Starting API server..."\n\
python run_localGPT_API.py --device_type ${DEVICE_TYPE} &\n\
API_PID=$!\n\
\n\
# Wait for API to be ready\n\
echo "Waiting for API server to be ready..."\n\
for i in {1..30}; do\n\
    if curl -s http://localhost:5110/health > /dev/null 2>&1; then\n\
        echo "API server is ready"\n\
        break\n\
    fi\n\
    echo "Waiting... ($i/30)"\n\
    sleep 2\n\
done\n\
\n\
# Start UI server\n\
echo "Starting UI server..."\n\
python localGPTUI/localGPTUI.py --host 0.0.0.0 --port 5111 &\n\
UI_PID=$!\n\
\n\
# Wait for both processes\n\
wait $API_PID $UI_PID\n\
' > /app/start.sh && chmod +x /app/start.sh

# Default command
CMD ["/app/start.sh"]

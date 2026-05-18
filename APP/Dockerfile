# Stage 4A SwiftDeploy - API Service Dockerfile
# Builds a lightweight Python image with the Flask API

FROM python:3.11-slim

# Create a non-root user (security best practice)
RUN groupadd -g 1001 appuser && \
    useradd -u 1001 -g appuser -m appuser

# Set working directory
WORKDIR /app

# Copy requirements first (better layer caching)
COPY app/requirements.txt ./requirements.txt

# Install Python dependencies 
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app/

# Create writable log directory for OpenTelemetry logs
RUN mkdir -p /var/log/app && chown appuser:appuser /var/log/app

# Switch to non-root user
USER appuser

# Drop unnecessary Linux capabilities (security)
# Default Docker run already drops most; this Dockerfile relies on
# `cap_drop` in docker-compose.yml for fine-grained control

# Expose the port the app runs on (documentation only)
EXPOSE 3000

# Healthcheck for Docker
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen(''http://localhost:3000/healthz')" || exit 1

# Start the application
CMD ["python", "app/main.py"]

#!/bin/bash

# Nginx Reverse Proxy Setup Script

echo "Setting up Nginx Reverse Proxy..."

# Create SSL directory
mkdir -p ssl

# Generate self-signed SSL certificate for development
echo "Generating self-signed SSL certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem \
  -out ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

echo "SSL certificate generated successfully!"

# Set appropriate permissions
chmod 600 ssl/key.pem
chmod 644 ssl/cert.pem

# Check if test-backend.html exists
if [ ! -f "test-backend.html" ]; then
  echo "⚠️  test-backend.html not found. Please create it or the test backend won't work."
fi

echo "Directory structure:"
echo "."
echo "├── docker-compose.yml"
echo "├── nginx.conf"
echo "├── test-backend.html (for testing)"
echo "├── ssl/"
echo "│   ├── cert.pem"
echo "│   └── key.pem"
echo "└── setup.sh"

echo ""
echo "Setup complete! To start the reverse proxy:"
echo "docker-compose up -d"
echo ""
echo "Access your proxy at:"
echo "HTTP:  http://localhost:5080"
echo "HTTPS: https://localhost:5443 (accept SSL warning for self-signed cert)"
echo ""
echo "Health check:"
echo "curl http://localhost:5080/health"
echo "curl -k https://localhost:5443/health"
echo ""
echo "📝 To use with your own backend:"
echo "1. Remove or comment out the 'test-backend' service in docker-compose.yml"
echo "2. Update the 'upstream backend' section in nginx.conf"
echo "3. Restart with: docker-compose restart nginx-proxy"

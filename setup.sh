#!/bin/bash

echo "🔧 Setting up Nginx Reverse Proxy..."

# Create SSL directory
mkdir -p ssl

# Generate self-signed SSL certificate
echo "📜 Generating SSL certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem \
  -out ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Set permissions
chmod 600 ssl/key.pem
chmod 644 ssl/cert.pem

echo "✅ Setup complete!"
echo ""
echo "📁 Files created:"
echo "├── docker-compose.yml"
echo "├── nginx.conf"
echo "├── index.html"
echo "├── setup.sh"
echo "└── ssl/"
echo "    ├── cert.pem"
echo "    └── key.pem"
echo ""
echo "🚀 To start:"
echo "   docker compose up -d"
echo ""
echo "🌐 Access URLs:"
echo "   HTTP:  http://localhost:8080"
echo "   HTTPS: https://localhost:8443 (accept SSL warning)"
echo "   Health: http://localhost:8080/health"

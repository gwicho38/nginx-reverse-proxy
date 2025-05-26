#!/bin/bash

echo "🧪 Testing Nginx Reverse Proxy..."
echo ""

# Test HTTP
echo "🔍 Testing HTTP (port 8080)..."
if curl -s http://localhost:8080 | grep -q "Nginx Reverse Proxy Working"; then
  echo "✅ HTTP test passed"
else
  echo "❌ HTTP test failed"
fi

# Test HTTPS
echo "🔍 Testing HTTPS (port 8443)..."
if curl -k -s https://localhost:8443 | grep -q "Nginx Reverse Proxy Working"; then
  echo "✅ HTTPS test passed"
else
  echo "❌ HTTPS test failed"
fi

# Test Health endpoint
echo "🔍 Testing health endpoint..."
if curl -s http://localhost:8080/health | grep -q "OK"; then
  echo "✅ Health check passed"
else
  echo "❌ Health check failed"
fi

echo ""
echo "🏁 Test complete!"

#!/bin/bash

echo "🧪 Testing Nginx Reverse Proxy..."
echo ""

# Test main domain HTTP
echo "🔍 Testing main domain HTTP (localhost:8080)..."
if curl -s http://localhost:8080 | grep -q "Nginx Reverse Proxy Working"; then
  echo "✅ Main HTTP test passed"
else
  echo "❌ Main HTTP test failed"
fi

# Test main domain HTTPS
echo "🔍 Testing main domain HTTPS (localhost:8443)..."
if curl -k -s https://localhost:8443 | grep -q "Nginx Reverse Proxy Working"; then
  echo "✅ Main HTTPS test passed"
else
  echo "❌ Main HTTPS test failed"
fi

# Test Reposlite HTTP
echo "🔍 Testing Reposlite HTTP (reposlite.lefv.ddns.net:8080)..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://reposlite.lefv.ddns.net:8080)
if [ "$response" = "200" ]; then
  echo "✅ Reposlite HTTP routing works (got Reposlite page)"
elif [ "$response" = "502" ]; then
  echo "⚠️  Reposlite HTTP routing works (502 - Reposlite service not running on localhost:9156)"
else
  echo "❌ Reposlite HTTP test failed (HTTP $response)"
fi

# Test Reposlite HTTPS
echo "🔍 Testing Reposlite HTTPS (reposlite.lefv.ddns.net:8443)..."
response=$(curl -k -s -o /dev/null -w "%{http_code}" https://reposlite.lefv.ddns.net:8443)
if [ "$response" = "200" ]; then
  echo "✅ Reposlite HTTPS routing works (got Reposlite page)"
elif [ "$response" = "502" ]; then
  echo "⚠️  Reposlite HTTPS routing works (502 - Reposlite service not running on localhost:9156)"
else
  echo "❌ Reposlite HTTPS test failed (HTTP $response)"
fi

# Test Health endpoints
echo "🔍 Testing health endpoints..."
if curl -s http://localhost:8080/health | grep -q "OK"; then
  echo "✅ Main health check passed"
else
  echo "❌ Main health check failed"
fi

if curl -s http://reposlite.lefv.ddns.net:8080/health | grep -q "Reposlite OK"; then
  echo "✅ Reposlite health check passed"
else
  echo "❌ Reposlite health check failed"
fi

echo ""
echo "🏁 Test complete!"
echo ""
echo "📝 Expected routing:"
echo "   localhost:8080/8443 → Test page"
echo "   reposlite.lefv.ddns.net:8080/8443 → Reposlite (localhost:9156)"

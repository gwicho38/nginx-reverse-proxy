#!/bin/bash

# Test HTTPS subdomain routing specifically

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[PASS]${NC} $1"
}

print_error() {
  echo -e "${RED}[FAIL]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "======================================================"
echo "🔒 HTTPS Subdomain Routing Diagnostic"
echo "======================================================"
echo ""

# Test 1: Check certificate validity
print_status "Test 1: Checking SSL certificate for subdomain support"
echo ""

# Extract certificate info
cert_info=$(openssl x509 -in ssl/cert.pem -text -noout 2>/dev/null || echo "Certificate not found")

if echo "$cert_info" | grep -q "DNS:.*localhost"; then
  print_success "Certificate contains localhost DNS entries"

  # Show all DNS entries
  echo "Certificate DNS entries:"
  echo "$cert_info" | grep -A 10 "Subject Alternative Name" | grep "DNS:" | sed 's/^/  /'
else
  print_error "Certificate missing subdomain support"
  echo "Current certificate subject:"
  echo "$cert_info" | grep "Subject:" | sed 's/^/  /'
  echo ""
  echo "You need to regenerate the certificate with SAN support."
  echo "Run: ./fix-ssl.sh"
  exit 1
fi
echo ""

# Test 2: Check /etc/hosts
print_status "Test 2: Checking /etc/hosts configuration"
if grep -q "reposlite.localhost" /etc/hosts 2>/dev/null; then
  print_success "/etc/hosts contains reposlite.localhost entry"
else
  print_error "Missing /etc/hosts entry for reposlite.localhost"
  echo "Add this line to /etc/hosts:"
  echo "  127.0.0.1 reposlite.localhost"
  echo ""
  echo "Command: sudo echo '127.0.0.1 reposlite.localhost' >> /etc/hosts"
fi
echo ""

# Test 3: Test HTTPS connection to main domain
print_status "Test 3: Testing HTTPS connection to main domain"
if curl -k -s --connect-timeout 5 https://localhost:5443 >/dev/null 2>&1; then
  print_success "HTTPS works for localhost:5443"
else
  print_error "HTTPS connection failed for localhost:5443"
  echo "Check if nginx proxy is running: docker compose ps"
  exit 1
fi
echo ""

# Test 4: Test HTTPS connection to subdomain
print_status "Test 4: Testing HTTPS connection to subdomain"
response=$(curl -k -s -w "%{http_code}" -o /tmp/subdomain_response.txt --connect-timeout 10 \
  https://reposlite.localhost:5443 2>/dev/null || echo "failed")

if [ "$response" = "502" ] || [ "$response" = "503" ] || [ "$response" = "504" ]; then
  print_success "HTTPS subdomain routing works (backend unavailable: HTTP $response)"
  echo "This means nginx is correctly routing the request, but your target service isn't running."
  echo "Make sure your service is running on localhost:9156"
elif [ "$response" = "200" ]; then
  print_success "HTTPS subdomain routing works perfectly (HTTP $response)"
elif [ "$response" = "failed" ]; then
  print_error "HTTPS connection to subdomain completely failed"
  echo "Possible causes:"
  echo "  1. Certificate hostname mismatch"
  echo "  2. Missing /etc/hosts entry"
  echo "  3. nginx configuration issue"
  echo ""
  echo "Debug steps:"
  echo "  1. Check certificate: openssl x509 -in ssl/cert.pem -text -noout | grep -A 5 'Subject Alternative Name'"
  echo "  2. Check nginx logs: docker compose logs nginx-proxy"
  echo "  3. Verify container is running: docker compose ps"
else
  print_warning "Unexpected response: HTTP $response"
  echo "Response content:"
  head -5 /tmp/subdomain_response.txt 2>/dev/null || echo "No response content"
fi
echo ""

# Test 5: Compare HTTP vs HTTPS behavior
print_status "Test 5: Comparing HTTP vs HTTPS behavior"

# HTTP test
http_response=$(curl -s -w "%{http_code}" -o /tmp/http_test.txt --connect-timeout 5 \
  http://reposlite.localhost:5080 2>/dev/null || echo "failed")

# HTTPS test
https_response=$(curl -k -s -w "%{http_code}" -o /tmp/https_test.txt --connect-timeout 5 \
  https://reposlite.localhost:5443 2>/dev/null || echo "failed")

echo "HTTP response:  $http_response"
echo "HTTPS response: $https_response"

if [ "$http_response" = "$https_response" ]; then
  print_success "HTTP and HTTPS responses match - routing is consistent"
elif [ "$http_response" != "failed" ] && [ "$https_response" = "failed" ]; then
  print_error "HTTP works but HTTPS fails - certificate or SSL configuration issue"
else
  print_warning "HTTP and HTTPS responses differ - may be normal depending on backend"
fi
echo ""

# Test 6: SSL handshake test
print_status "Test 6: Testing SSL handshake"
if echo | openssl s_client -connect reposlite.localhost:5443 -servername reposlite.localhost 2>/dev/null | grep -q "CONNECTED"; then
  print_success "SSL handshake successful"
else
  print_error "SSL handshake failed"
  echo "This suggests a certificate or SSL configuration problem"
fi
echo ""

# Cleanup
rm -f /tmp/subdomain_response.txt /tmp/http_test.txt /tmp/https_test.txt

echo "======================================================"
echo "🔍 Summary & Next Steps"
echo "======================================================"
echo ""
echo "If HTTPS subdomain routing is still not working:"
echo ""
echo "1. Regenerate certificate with subdomain support:"
echo "   ./fix-ssl.sh"
echo ""
echo "2. Restart nginx proxy:"
echo "   docker compose restart nginx-proxy"
echo ""
echo "3. Ensure /etc/hosts entry exists:"
echo "   sudo echo '127.0.0.1 reposlite.localhost' >> /etc/hosts"
echo ""
echo "4. Test again:"
echo "   curl -k -I https://reposlite.localhost:5443"
echo ""
echo "5. Check nginx configuration includes HTTPS server block for subdomain"
echo ""
echo "For debugging, check nginx logs:"
echo "   docker compose logs nginx-proxy | tail -20"

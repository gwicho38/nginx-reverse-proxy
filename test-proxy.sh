#!/bin/bash

# Nginx Reverse Proxy Test Script
# Tests HTTP, HTTPS, and health endpoints

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
HTTP_PORT=5080
HTTPS_PORT=5443
TIMEOUT=10
RETRY_COUNT=3
RETRY_DELAY=2

# Print colored output
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

# Function to test HTTP endpoint
test_http() {
  local url=$1
  local expected_code=${2:-200}
  local description=$3

  print_status "Testing: $description"
  print_status "URL: $url"

  for i in $(seq 1 $RETRY_COUNT); do
    if response=$(curl -s -w "%{http_code}" -o /tmp/response.txt --connect-timeout $TIMEOUT "$url" 2>/dev/null); then
      if [ "$response" = "$expected_code" ]; then
        print_success "$description - HTTP $response"
        return 0
      else
        print_error "$description - Expected HTTP $expected_code, got HTTP $response"
        if [ -f /tmp/response.txt ]; then
          echo "Response body:"
          head -5 /tmp/response.txt
        fi
        return 1
      fi
    else
      if [ $i -lt $RETRY_COUNT ]; then
        print_warning "$description - Attempt $i failed, retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
      else
        print_error "$description - Connection failed after $RETRY_COUNT attempts"
        return 1
      fi
    fi
  done
}

# Function to test HTTPS endpoint (with SSL verification disabled)
test_https() {
  local url=$1
  local expected_code=${2:-200}
  local description=$3

  print_status "Testing: $description"
  print_status "URL: $url"

  for i in $(seq 1 $RETRY_COUNT); do
    if response=$(curl -k -s -w "%{http_code}" -o /tmp/response.txt --connect-timeout $TIMEOUT "$url" 2>/dev/null); then
      if [ "$response" = "$expected_code" ]; then
        print_success "$description - HTTP $response"
        return 0
      else
        print_error "$description - Expected HTTP $expected_code, got HTTP $response"
        if [ -f /tmp/response.txt ]; then
          echo "Response body:"
          head -5 /tmp/response.txt
        fi
        return 1
      fi
    else
      if [ $i -lt $RETRY_COUNT ]; then
        print_warning "$description - Attempt $i failed, retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
      else
        print_error "$description - Connection failed after $RETRY_COUNT attempts"
        return 1
      fi
    fi
  done
}

# Function to check container status
check_containers() {
  print_status "Checking container status..."

  if ! docker compose ps >/dev/null 2>&1; then
    print_error "Docker compose not found or not running"
    return 1
  fi

  # Check if containers are running
  local nginx_status=$(docker compose ps -q nginx-proxy | xargs docker inspect -f '{{.State.Status}}' 2>/dev/null || echo "not found")
  local backend_status=$(docker compose ps -q test-backend | xargs docker inspect -f '{{.State.Status}}' 2>/dev/null || echo "not found")

  if [ "$nginx_status" = "running" ]; then
    print_success "nginx-proxy container is running"
  else
    print_error "nginx-proxy container is not running (status: $nginx_status)"
    return 1
  fi

  if [ "$backend_status" = "running" ]; then
    print_success "test-backend container is running"
  else
    print_error "test-backend container is not running (status: $backend_status)"
    return 1
  fi

  return 0
}

# Function to check port availability
check_ports() {
  print_status "Checking if ports are accessible..."

  if nc -z localhost $HTTP_PORT 2>/dev/null; then
    print_success "Port $HTTP_PORT (HTTP) is accessible"
  else
    print_error "Port $HTTP_PORT (HTTP) is not accessible"
    return 1
  fi

  if nc -z localhost $HTTPS_PORT 2>/dev/null; then
    print_success "Port $HTTPS_PORT (HTTPS) is accessible"
  else
    print_error "Port $HTTPS_PORT (HTTPS) is not accessible"
    return 1
  fi

  return 0
}

# Function to display logs on failure
show_logs() {
  print_status "Recent nginx-proxy logs:"
  docker compose logs --tail=20 nginx-proxy

  print_status "Recent test-backend logs:"
  docker compose logs --tail=10 test-backend
}

# Main test function
run_tests() {
  local test_count=0
  local passed_count=0
  local failed_tests=()

  echo "======================================================"
  echo "🧪 Nginx Reverse Proxy Test Suite"
  echo "======================================================"
  echo ""

  # Test 1: Container Status
  print_status "Test 1/7: Container Status"
  test_count=$((test_count + 1))
  if check_containers; then
    passed_count=$((passed_count + 1))
  else
    failed_tests+=("Container Status")
  fi
  echo ""

  # Test 2: Port Accessibility
  print_status "Test 2/7: Port Accessibility"
  test_count=$((test_count + 1))
  if check_ports; then
    passed_count=$((passed_count + 1))
  else
    failed_tests+=("Port Accessibility")
  fi
  echo ""

  # Test 3: HTTP Main Page
  print_status "Test 3/7: HTTP Main Page"
  test_count=$((test_count + 1))
  if test_http "http://localhost:$HTTP_PORT" 200 "HTTP main page"; then
    passed_count=$((passed_count + 1))
  else
    failed_tests+=("HTTP Main Page")
  fi
  echo ""

  # Test 4: HTTPS Main Page
  print_status "Test 4/7: HTTPS Main Page"
  test_count=$((test_count + 1))
  if test_https "https://localhost:$HTTPS_PORT" 200 "HTTPS main page"; then
    passed_count=$((passed_count + 1))
  else
    failed_tests+=("HTTPS Main Page")
  fi
  echo ""

  # Test 5: HTTP Health Check
  print_status "Test 5/7: HTTP Health Check"
  test_count=$((test_count + 1))
  if test_http "http://localhost:$HTTP_PORT/health" 200 "HTTP health endpoint"; then
    passed_count=$((passed_count + 1))
  else
    failed_tests+=("HTTP Health Check")
  fi
  echo ""

  # Test 6: HTTPS Health Check
  print_status "Test 6/7: HTTPS Health Check"
  test_count=$((test_count + 1))
  if test_https "https://localhost:$HTTPS_PORT/health" 200 "HTTPS health endpoint"; then
    passed_count=$((passed_count + 1))
  else
    failed_tests+=("HTTPS Health Check")
  fi
  echo ""

  # Test 7: Response Content Validation
  print_status "Test 7/7: Response Content Validation"
  test_count=$((test_count + 1))
  if curl -s "http://localhost:$HTTP_PORT" | grep -q "Nginx Reverse Proxy Working"; then
    print_success "Response contains expected content"
    passed_count=$((passed_count + 1))
  else
    print_error "Response does not contain expected content"
    failed_tests+=("Response Content Validation")
  fi
  echo ""

  # Summary
  echo "======================================================"
  echo "📊 Test Results Summary"
  echo "======================================================"
  echo "Total Tests: $test_count"
  echo "Passed: $passed_count"
  echo "Failed: $((test_count - passed_count))"
  echo ""

  if [ $passed_count -eq $test_count ]; then
    print_success "🎉 ALL TESTS PASSED! Reverse proxy is working correctly."
    echo ""
    echo "Your reverse proxy is accessible at:"
    echo "  HTTP:  http://localhost:$HTTP_PORT"
    echo "  HTTPS: https://localhost:$HTTPS_PORT"
    echo ""
    return 0
  else
    print_error "❌ Some tests failed:"
    printf '%s\n' "${failed_tests[@]}" | sed 's/^/  - /'
    echo ""
    print_status "Showing recent logs for debugging:"
    show_logs
    return 1
  fi
}

# Check dependencies
check_dependencies() {
  local missing_deps=()

  if ! command -v docker >/dev/null 2>&1; then
    missing_deps+=("docker")
  fi

  if ! command -v curl >/dev/null 2>&1; then
    missing_deps+=("curl")
  fi

  if ! command -v nc >/dev/null 2>&1; then
    missing_deps+=("nc (netcat)")
  fi

  if [ ${#missing_deps[@]} -gt 0 ]; then
    print_error "Missing required dependencies:"
    printf '%s\n' "${missing_deps[@]}" | sed 's/^/  - /'
    exit 1
  fi
}

# Cleanup function
cleanup() {
  rm -f /tmp/response.txt
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
  case "${1:-test}" in
  "test" | "")
    check_dependencies
    run_tests
    ;;
  "logs")
    show_logs
    ;;
  "status")
    check_containers
    ;;
  "help" | "-h" | "--help")
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  test     Run all tests (default)"
    echo "  logs     Show recent container logs"
    echo "  status   Check container status only"
    echo "  help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0           # Run all tests"
    echo "  $0 test      # Run all tests"
    echo "  $0 logs      # Show logs"
    echo "  $0 status    # Check status"
    ;;
  *)
    print_error "Unknown command: $1"
    echo "Use '$0 help' for usage information"
    exit 1
    ;;
  esac
}

main "$@"

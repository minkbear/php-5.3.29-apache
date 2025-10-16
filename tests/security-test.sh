#!/bin/bash

# Security Test Script for Apache OWASP Configuration
# Tests for sensitive file access and path traversal vulnerabilities

set +e  # Don't exit on error

BASE_URL="${BASE_URL:-http://localhost:8080}"
PASSED=0
FAILED=0
VERBOSE="${VERBOSE:-0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "Security Test Suite for Apache"
echo "Testing URL: $BASE_URL"
echo "========================================"
echo ""

# Test function
test_blocked() {
    local url=$1
    local description=$2

    echo -n "Testing: $description ... "

    if [ "$VERBOSE" == "1" ]; then
        echo ""
        echo "  → curl --max-time 5 --connect-timeout 3 $BASE_URL$url"
    fi

    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 --connect-timeout 3 "$BASE_URL$url" 2>&1)
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}✗ TIMEOUT/ERROR${NC} (curl exit code: $exit_code)"
        ((FAILED++))
    elif [ "$response" == "403" ] || [ "$response" == "404" ] || [ "$response" == "400" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $response)"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC} (HTTP $response - Expected 400/403/404)"
        ((FAILED++))
    fi
}

test_allowed() {
    local url=$1
    local description=$2

    echo -n "Testing: $description ... "

    if [ "$VERBOSE" == "1" ]; then
        echo ""
        echo "  → curl --max-time 5 --connect-timeout 3 $BASE_URL$url"
    fi

    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 --connect-timeout 3 "$BASE_URL$url" 2>&1)
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}✗ TIMEOUT/ERROR${NC} (curl exit code: $exit_code)"
        ((FAILED++))
    elif [ "$response" == "200" ] || [ "$response" == "302" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $response)"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ WARNING${NC} (HTTP $response - Expected 200 or 302)"
        ((FAILED++))
    fi
}

echo "=== Test 1: .env File Protection ==="
test_blocked "/.env" ".env file access"
test_blocked "/config/.env" "Nested .env file access"
test_blocked "/.env.local" ".env.local file access"
test_blocked "/.env.production" ".env.production file access"
echo ""

echo "=== Test 2: .git Directory Protection ==="
test_blocked "/.git/config" ".git/config file access"
test_blocked "/.git/HEAD" ".git/HEAD file access"
test_blocked "/.git/" ".git directory listing"
test_blocked "/.gitignore" ".gitignore file access"
echo ""

echo "=== Test 3: Composer Files Protection ==="
test_blocked "/composer.json" "composer.json access"
test_blocked "/composer.lock" "composer.lock access"
test_blocked "/package.json" "package.json access"
test_blocked "/package-lock.json" "package-lock.json access"
echo ""

echo "=== Test 4: Backup Files Protection ==="
test_blocked "/index.php.bak" ".bak file access"
test_blocked "/config.php.backup" ".backup file access"
test_blocked "/database.sql" ".sql file access"
test_blocked "/backup.old" ".old file access"
test_blocked "/temp.tmp" ".tmp file access"
echo ""

echo "=== Test 5: Config Files Protection ==="
test_blocked "/config.ini" ".ini file access"
test_blocked "/app.config" ".config file access"
test_blocked "/settings.yml" ".yml file access"
test_blocked "/docker-compose.yaml" ".yaml file access"
test_blocked "/apache.conf" ".conf file access"
echo ""

echo "=== Test 6: Log Files Protection ==="
test_blocked "/error.log" ".log file access"
test_blocked "/access.log" "access.log file access"
test_blocked "/debug.log" "debug.log file access"
echo ""

echo "=== Test 7: Apache Hidden Files Protection ==="
test_blocked "/.htaccess" ".htaccess file access"
test_blocked "/.htpasswd" ".htpasswd file access"
echo ""

echo "=== Test 8: Path Traversal Attacks ==="
test_blocked "/../etc/passwd" "Path traversal to /etc/passwd"
test_blocked "/../../etc/shadow" "Path traversal to /etc/shadow"
test_blocked "/../../../etc/hosts" "Path traversal to /etc/hosts"
test_blocked "/uploads/../../../etc/passwd" "Complex path traversal"
test_blocked "/./../../etc/passwd" "Encoded path traversal"
echo ""

echo "=== Test 9: URL Encoding Bypass Attempts ==="
test_blocked "/%2e%2e/etc/passwd" "URL encoded path traversal"
test_blocked "/.%2e/.%2e/etc/passwd" "Mixed encoding path traversal"
test_blocked "/..%252f..%252fetc/passwd" "Double encoded path traversal"
echo ""

echo "=== Test 10: Normal Access (Should Work) ==="
test_allowed "/" "Root access"
test_allowed "/index.php" "PHP file access (if exists)"
echo ""

echo "========================================"
echo "Test Results Summary"
echo "========================================"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "Total:  $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All security tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some security tests failed!${NC}"
    exit 1
fi

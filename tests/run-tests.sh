#!/bin/bash

# Security Test Runner
# This script builds, starts containers, runs tests, and cleans up

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root directory
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================"
echo "Security Test Runner"
echo "Project: $PROJECT_ROOT"
echo -e "========================================${NC}"
echo ""

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: docker-compose is not installed${NC}"
    exit 1
fi

# Step 1: Build
echo -e "${YELLOW}[1/5] Building Docker image...${NC}"
docker-compose build --no-cache
echo -e "${GREEN}✓ Build completed${NC}"
echo ""

# Step 2: Start containers
echo -e "${YELLOW}[2/5] Starting containers...${NC}"
docker-compose up -d
echo -e "${GREEN}✓ Containers started${NC}"
echo ""

# Step 3: Wait for Apache to be ready
echo -e "${YELLOW}[3/5] Waiting for Apache to be ready...${NC}"
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:8080/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Apache is ready${NC}"
        break
    fi

    attempt=$((attempt + 1))
    echo -n "."
    sleep 1
done

if [ $attempt -eq $max_attempts ]; then
    echo -e "${RED}✗ Apache failed to start in time${NC}"
    docker-compose logs app
    docker-compose down
    exit 1
fi
echo ""

# Step 4: Run security tests
echo -e "${YELLOW}[4/5] Running security tests...${NC}"
echo ""

BASE_URL=http://localhost:8080 ./tests/security-test.sh
test_result=$?

echo ""

# Step 5: Show container logs if tests failed
if [ $test_result -ne 0 ]; then
    echo -e "${YELLOW}[DEBUG] Container logs:${NC}"
    docker-compose logs app | tail -50
    echo ""
fi

# Optional: Keep containers running or cleanup
read -p "Do you want to keep containers running? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}[5/5] Cleaning up...${NC}"
    docker-compose down
    echo -e "${GREEN}✓ Cleanup completed${NC}"
else
    echo -e "${GREEN}Containers are still running. Access at: http://localhost:8080${NC}"
    echo -e "To stop: ${YELLOW}docker-compose down${NC}"
fi

echo ""
echo -e "${BLUE}========================================"
echo "Test Runner Completed"
echo -e "========================================${NC}"

exit $test_result

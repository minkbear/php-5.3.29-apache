#!/bin/bash

# Advanced Docker Build and Push Script with Multi-arch Support
# Builds PHP 5.3.29 Apache image and pushes to Docker Hub

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load configuration from .env.docker if exists
if [ -f ".env.docker.local" ]; then
    source .env.docker.local
    echo -e "${BLUE}Loaded config from .env.docker.local${NC}"
elif [ -f ".env.docker" ]; then
    source .env.docker
    echo -e "${BLUE}Loaded config from .env.docker${NC}"
fi

# Configuration with defaults
DOCKER_USERNAME="${DOCKER_USERNAME:-minkbear}"
IMAGE_NAME="${IMAGE_NAME:-php-5.3.29-apache}"
VERSION_TAG="${VERSION_TAG:-$(date +%Y%m%d)}"
BUILD_NO_CACHE="${BUILD_NO_CACHE:-false}"
BUILD_QUIET="${BUILD_QUIET:-false}"
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}"

# Additional tags (comma-separated)
ADDITIONAL_TAGS="${ADDITIONAL_TAGS:-}"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            DOCKER_USERNAME="$2"
            FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}"
            shift 2
            ;;
        -v|--version)
            VERSION_TAG="$2"
            shift 2
            ;;
        --no-cache)
            BUILD_NO_CACHE=true
            shift
            ;;
        --quiet)
            BUILD_QUIET=true
            shift
            ;;
        --no-push)
            NO_PUSH=true
            shift
            ;;
        --tags)
            ADDITIONAL_TAGS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -u, --username USERNAME    Docker Hub username (default: minkbear)"
            echo "  -v, --version VERSION      Version tag (default: YYYYMMDD)"
            echo "  --no-cache                 Build without cache"
            echo "  --quiet                    Quiet build output"
            echo "  --no-push                  Build only, don't push to Docker Hub"
            echo "  --tags TAGS                Additional tags (comma-separated)"
            echo "  -h, --help                 Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0"
            echo "  $0 --version 20251016"
            echo "  $0 --username myuser --version v1.0.0"
            echo "  $0 --tags stable,production --no-cache"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================"
echo "Docker Build and Push to Docker Hub"
echo -e "========================================${NC}"
echo ""
echo "Configuration:"
echo "  Username: ${DOCKER_USERNAME}"
echo "  Image: ${IMAGE_NAME}"
echo "  Version: ${VERSION_TAG}"
echo "  Full Name: ${FULL_IMAGE_NAME}"
echo "  No Cache: ${BUILD_NO_CACHE}"
echo ""

# Prepare tags
TAGS=("${VERSION_TAG}" "latest")
if [ -n "$ADDITIONAL_TAGS" ]; then
    IFS=',' read -ra EXTRA_TAGS <<< "$ADDITIONAL_TAGS"
    TAGS+=("${EXTRA_TAGS[@]}")
fi

echo "Tags to create:"
for tag in "${TAGS[@]}"; do
    echo "  • ${tag}"
done
echo ""

# Step 1: Check if docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Step 2: Check Docker login status (skip if --no-push)
if [ "$NO_PUSH" != "true" ]; then
    echo -e "${YELLOW}[1/6] Checking Docker Hub authentication...${NC}"
    if ! docker info 2>/dev/null | grep -q "Username"; then
        echo -e "${YELLOW}Not logged in to Docker Hub. Please login:${NC}"
        docker login
    else
        current_user=$(docker info 2>/dev/null | grep Username | awk '{print $2}')
        echo -e "${GREEN}✓ Logged in as ${current_user}${NC}"

        if [ "$current_user" != "$DOCKER_USERNAME" ]; then
            echo -e "${YELLOW}⚠ Warning: Logged in as '${current_user}' but pushing as '${DOCKER_USERNAME}'${NC}"
            read -p "Continue anyway? (y/n) " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
    echo ""
fi

# Step 3: Build the image
echo -e "${YELLOW}[2/6] Building Docker image...${NC}"

BUILD_ARGS=""
if [ "$BUILD_NO_CACHE" = "true" ]; then
    BUILD_ARGS="$BUILD_ARGS --no-cache"
fi
if [ "$BUILD_QUIET" = "true" ]; then
    BUILD_ARGS="$BUILD_ARGS --quiet"
fi

docker build $BUILD_ARGS -t "${FULL_IMAGE_NAME}:${VERSION_TAG}" .
echo -e "${GREEN}✓ Build completed${NC}"
echo ""

# Step 4: Create additional tags
echo -e "${YELLOW}[3/6] Creating image tags...${NC}"
for tag in "${TAGS[@]}"; do
    if [ "$tag" != "$VERSION_TAG" ]; then
        docker tag "${FULL_IMAGE_NAME}:${VERSION_TAG}" "${FULL_IMAGE_NAME}:${tag}"
        echo "  ✓ Tagged as ${tag}"
    fi
done
echo -e "${GREEN}✓ All tags created${NC}"
echo ""

# Step 5: Show image info
echo -e "${YELLOW}[4/6] Image information...${NC}"
docker images "${FULL_IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
echo ""

# Step 6: Push to Docker Hub (skip if --no-push)
if [ "$NO_PUSH" != "true" ]; then
    echo -e "${YELLOW}[5/6] Pushing images to Docker Hub...${NC}"
    for tag in "${TAGS[@]}"; do
        echo "Pushing ${FULL_IMAGE_NAME}:${tag}..."
        docker push "${FULL_IMAGE_NAME}:${tag}"
        echo -e "  ${GREEN}✓ Pushed ${tag}${NC}"
    done
    echo -e "${GREEN}✓ All images pushed${NC}"
    echo ""
else
    echo -e "${YELLOW}[5/6] Skipping push (--no-push flag set)${NC}"
    echo ""
fi

# Step 7: Test the image (optional)
echo -e "${YELLOW}[6/6] Quick test...${NC}"
echo "Testing image startup..."
CONTAINER_ID=$(docker run -d --rm "${FULL_IMAGE_NAME}:${VERSION_TAG}")
sleep 3

if docker ps | grep -q "$CONTAINER_ID"; then
    echo -e "${GREEN}✓ Container started successfully${NC}"
    docker stop "$CONTAINER_ID" > /dev/null 2>&1
else
    echo -e "${RED}✗ Container failed to start${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}========================================"
echo "Build and Push Completed Successfully!"
echo -e "========================================${NC}"
echo ""

if [ "$NO_PUSH" != "true" ]; then
    echo "Images pushed to Docker Hub:"
    for tag in "${TAGS[@]}"; do
        echo "  • ${FULL_IMAGE_NAME}:${tag}"
    done
    echo ""
    echo "To pull this image:"
    echo -e "  ${GREEN}docker pull ${FULL_IMAGE_NAME}:${VERSION_TAG}${NC}"
    echo ""
    echo "Docker Hub URL:"
    echo "  https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_NAME}"
else
    echo "Image built locally:"
    for tag in "${TAGS[@]}"; do
        echo "  • ${FULL_IMAGE_NAME}:${tag}"
    done
    echo ""
    echo "To push manually:"
    echo -e "  ${YELLOW}docker push ${FULL_IMAGE_NAME}:${VERSION_TAG}${NC}"
fi
echo ""

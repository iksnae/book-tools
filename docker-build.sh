#!/bin/bash

# docker-build.sh - Builds books using Docker container
# Usage: docker-build.sh [directory] [options]

set -e  # Exit on error

# Default values
DOCKER_IMAGE="iksnae/book-builder:latest"
PROJECT_ROOT=$(pwd)
BUILD_ARGS=""
LOCAL_IMAGE_NAME="book-tools-arm64"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "❌ Error: Docker is not installed. Please install Docker before continuing."
  exit 1
fi

# Check for ARM64 architecture (Apple Silicon)
if [[ "$(uname -m)" == "arm64" ]]; then
  echo "⚠️ Detected ARM64 architecture (Apple Silicon)."
  echo "The iksnae/book-builder image might not support ARM64 natively."
  echo ""
  echo "Options:"
  echo "1. Use pandoc/core image (basic support, limited features)"
  echo "2. Build a custom ARM64-compatible image (full support, takes time)"
  echo "3. Cancel"
  echo ""
  
  read -p "Choose an option (1/2/3): " -n 1 -r
  echo ""
  
  case $REPLY in
    1)
      DOCKER_IMAGE="pandoc/core:latest"
      echo "Using pandoc/core image instead, which supports ARM64..."
      echo "Note: Some features may be limited with this image."
      ;;
    2)
      echo "Building custom ARM64-compatible image..."
      if [ -f "$PROJECT_ROOT/Dockerfile.arm64" ]; then
        docker build -t "$LOCAL_IMAGE_NAME" -f "$PROJECT_ROOT/Dockerfile.arm64" "$PROJECT_ROOT"
        DOCKER_IMAGE="$LOCAL_IMAGE_NAME"
        echo "✅ Custom image built successfully: $DOCKER_IMAGE"
      else
        echo "❌ Error: Dockerfile.arm64 not found in $PROJECT_ROOT."
        exit 1
      fi
      ;;
    *)
      echo "Build canceled."
      exit 1
      ;;
  esac
fi

# Parse command line arguments
for arg in "$@"; do
  case $arg in
    --image=*)
      DOCKER_IMAGE="${arg#*=}"
      ;;
    --pull)
      PULL_IMAGE=true
      ;;
    --build-arm64)
      if [ -f "$PROJECT_ROOT/Dockerfile.arm64" ]; then
        docker build -t "$LOCAL_IMAGE_NAME" -f "$PROJECT_ROOT/Dockerfile.arm64" "$PROJECT_ROOT"
        DOCKER_IMAGE="$LOCAL_IMAGE_NAME"
        echo "✅ ARM64 image built successfully: $DOCKER_IMAGE"
      else
        echo "❌ Error: Dockerfile.arm64 not found in $PROJECT_ROOT."
        exit 1
      fi
      ;;
    *)
      # Pass other arguments to the build script
      BUILD_ARGS="$BUILD_ARGS $arg"
      ;;
  esac
done

echo "📚 Starting Docker-based book build process..."
echo "🐳 Using Docker image: $DOCKER_IMAGE"
echo "📁 Project root: $PROJECT_ROOT"

# Pull latest image if requested or by default (only for remote images)
if [[ "$DOCKER_IMAGE" != "$LOCAL_IMAGE_NAME" ]] && { [ "$PULL_IMAGE" = true ] || [ -z "$PULL_IMAGE" ]; }; then
  echo "🔄 Pulling latest Docker image..."
  docker pull "$DOCKER_IMAGE"
fi

# Run the build in Docker container
echo "🚀 Running build in Docker container..."
echo "Build arguments: $BUILD_ARGS"

# Use a different command based on the image
if [[ "$DOCKER_IMAGE" == "pandoc/core"* ]]; then
  # For pandoc/core image, we need to modify the command slightly
  docker run --rm \
    -v "$PROJECT_ROOT:/book" \
    -w "/book" \
    "$DOCKER_IMAGE" \
    "bash /book/src/scripts/build.sh $BUILD_ARGS"
else
  # For iksnae/book-builder image or custom image
  docker run --rm \
    -v "$PROJECT_ROOT:/book" \
    "$DOCKER_IMAGE" \
    "/book/src/scripts/build.sh $BUILD_ARGS"
fi

echo ""
echo "✅ Docker-based build process complete!"
echo "📂 Generated files are in the $PROJECT_ROOT/build/ directory" 
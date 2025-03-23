#!/bin/bash

# docker-build.sh - Builds books using Docker container with iksnae/book-builder
# Usage: docker-build.sh [options]

set -e  # Exit on error

# Default values
DOCKER_IMAGE="iksnae/book-builder:latest"
PROJECT_ROOT=$(pwd)
BUILD_ARGS=""
PLATFORM_FLAG=""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "❌ Error: Docker is not installed. Please install Docker before continuing."
  exit 1
fi

# Check for ARM64 architecture (Apple Silicon)
if [[ "$(uname -m)" == "arm64" ]]; then
  echo "⚠️ Detected ARM64 architecture (Apple Silicon)."
  echo "The iksnae/book-builder image may require platform emulation."
  
  # Try running with platform flag
  PLATFORM_FLAG="--platform linux/amd64"
  echo "Running with platform emulation: $PLATFORM_FLAG"
  echo "Note: This may be slower but ensures compatibility."
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
    --no-platform-emulation)
      PLATFORM_FLAG=""
      echo "Platform emulation disabled as requested."
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

# Pull latest image if requested or by default
if [ "$PULL_IMAGE" = true ] || [ -z "$PULL_IMAGE" ]; then
  echo "🔄 Pulling latest Docker image..."
  docker pull "$DOCKER_IMAGE"
fi

# Run the build in Docker container
echo "🚀 Running build in Docker container..."
echo "Build arguments: $BUILD_ARGS"

# Run with platform flag if on ARM64
docker run --rm $PLATFORM_FLAG \
  -v "$PROJECT_ROOT:/book" \
  "$DOCKER_IMAGE" \
  "/book/src/scripts/build.sh $BUILD_ARGS"

echo ""
echo "✅ Docker-based build process complete!"
echo "📂 Generated files are in the $PROJECT_ROOT/build/ directory" 
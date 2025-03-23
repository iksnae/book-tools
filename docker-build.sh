#!/bin/bash

# docker-build.sh - Builds books using iksnae/book-builder Docker container
# Usage: docker-build.sh [options]
#
# This script is primarily designed for CI/CD pipelines and GitHub Actions,
# supporting the iksnae/book-template project as its primary role.

set -e  # Exit on error

# Default values
DOCKER_IMAGE="iksnae/book-builder:latest"
PROJECT_ROOT=$(pwd)
BUILD_ARGS=""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "❌ Error: Docker is not installed. Please install Docker before continuing."
  exit 1
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
    *)
      # Pass other arguments to the build script
      BUILD_ARGS="$BUILD_ARGS $arg"
      ;;
  esac
done

echo "📚 Starting Docker-based book build process..."
echo "🐳 Using Docker image: $DOCKER_IMAGE"
echo "📁 Project root: $PROJECT_ROOT"

# Pull latest image if requested
if [ "$PULL_IMAGE" = true ]; then
  echo "🔄 Pulling latest Docker image..."
  docker pull "$DOCKER_IMAGE"
fi

# Check for ARM64 architecture (Apple Silicon)
if [[ "$(uname -m)" == "arm64" ]]; then
  echo "⚠️ Warning: Running on ARM64 architecture (Apple Silicon)."
  echo "The iksnae/book-builder image may not be compatible with ARM64 natively."
  echo "For production builds, please use GitHub Actions or a Linux/Windows environment."
  echo "Attempting to build locally using emulation, which may fail..."
  echo ""
  
  # Try to run with platform emulation
  PLATFORM_FLAG="--platform linux/amd64"
else
  PLATFORM_FLAG=""
fi

# Run the build in Docker container
echo "🚀 Running build in Docker container..."
echo "Build arguments: $BUILD_ARGS"

docker run --rm $PLATFORM_FLAG \
  -v "$PROJECT_ROOT:/book" \
  "$DOCKER_IMAGE" \
  "/book/src/scripts/build.sh $BUILD_ARGS"

# Check if build was successful
if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Docker-based build process complete!"
  echo "📂 Generated files are in the $PROJECT_ROOT/build/ directory"
else
  echo ""
  echo "❌ Build process failed."
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo "This might be due to ARM64 compatibility issues."
    echo "For reliable builds, please push to GitHub and use GitHub Actions,"
    echo "or use a Linux/Windows environment."
  fi
  exit 1
fi 
#!/bin/bash

# build.sh - Main build script for book project
# Usage: build.sh [--languages=lang1,lang2] [--skip=pdf,epub] [--only=en]

set -e  # Exit on error

# Default values
CONFIG_FILE="book.yaml"
SUPPORTED_LANGUAGES=""
TARGET_LANGUAGES=""
SKIP_FORMATS=""
SCRIPTS_DIR="$(dirname "$0")"

# Parse command line arguments
for arg in "$@"; do
  case $arg in
    --languages=*)
      TARGET_LANGUAGES="${arg#*=}"
      ;;
    --skip=*)
      SKIP_FORMATS="${arg#*=}"
      ;;
    --config=*)
      CONFIG_FILE="${arg#*=}"
      ;;
    --help)
      echo "Usage: build.sh [options]"
      echo "Options:"
      echo "  --languages=lang1,lang2   Only build these languages (comma-separated)"
      echo "  --skip=pdf,epub,mobi,html Skip specified output formats (comma-separated)"
      echo "  --config=path             Use alternative config file (default: book.yaml)"
      echo "  --help                    Show this help message"
      exit 0
      ;;
  esac
done

echo "📚 Starting book build process..."

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Config file not found: $CONFIG_FILE"
  exit 1
fi

# Get supported languages from config or book directory
if grep -q "^languages:" "$CONFIG_FILE"; then
  # Extract languages from config file
  SUPPORTED_LANGUAGES=$(grep "^languages:" "$CONFIG_FILE" | cut -d ':' -f 2- | sed 's/^[ \t]*//' | tr -d '[]' | tr ',' ' ')
else
  # Discover languages from book directory structure
  SUPPORTED_LANGUAGES=$(find "book" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
fi

# Clean existing languages for clarity
SUPPORTED_LANGUAGES=$(echo "$SUPPORTED_LANGUAGES" | tr ',' ' ' | xargs)

echo "📋 Supported languages: $SUPPORTED_LANGUAGES"

# Determine which languages to build
if [ -z "$TARGET_LANGUAGES" ]; then
  LANGUAGES_TO_BUILD="$SUPPORTED_LANGUAGES"
else
  # Convert comma-separated list to space-separated
  LANGUAGES_TO_BUILD=$(echo "$TARGET_LANGUAGES" | tr ',' ' ')
  
  # Validate that specified languages are supported
  for lang in $LANGUAGES_TO_BUILD; do
    if ! echo "$SUPPORTED_LANGUAGES" | grep -wq "$lang"; then
      echo "⚠️ Warning: Language '$lang' is not in the supported languages list"
    fi
  done
fi

echo "🔨 Building languages: $LANGUAGES_TO_BUILD"

# Create clean build directory
mkdir -p build
echo "🧹 Cleaning build directory..."

# Prepare build arguments based on what to skip
BUILD_ARGS=""
if [ -n "$SKIP_FORMATS" ]; then
  IFS=',' read -ra SKIP_ARRAY <<< "$SKIP_FORMATS"
  for format in "${SKIP_ARRAY[@]}"; do
    BUILD_ARGS+=" --skip-$format"
  done
fi

# Start the build for each language
for language in $LANGUAGES_TO_BUILD; do
  echo ""
  echo "🔄 Starting build for language: $language"
  
  # Check if language directory exists
  if [ ! -d "book/$language" ]; then
    echo "⚠️ Warning: Directory book/$language does not exist, skipping..."
    continue
  fi
  
  # Build this language
  "$SCRIPTS_DIR/build-language.sh" "$language" "$CONFIG_FILE"
  
  # Check the result
  if [ $? -eq 0 ]; then
    echo "✅ Successfully built $language version"
  else
    echo "❌ Failed to build $language version"
  fi
done

echo ""
echo "📦 Build process complete!"
echo "📂 Generated files are in the build/ directory"
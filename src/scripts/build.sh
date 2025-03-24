#!/bin/bash

# build.sh - Main build script for book project
# Usage: build.sh [--languages=lang1,lang2] [--skip=pdf,epub] [--only=en]

set -e  # Exit on error

# Default values
SCRIPTS_DIR="$(dirname "$(realpath "$0")")"
PROJECT_ROOT="$(dirname "$SCRIPTS_DIR")"

# If first argument is a path and exists, use that as the project root
if [ $# -gt 0 ] && [ -d "$1" ]; then
  PROJECT_ROOT="$(realpath "$1")"
  shift # Remove the first argument
fi

CONFIG_FILE="$PROJECT_ROOT/book.yaml"  # Look for config in project root
SUPPORTED_LANGUAGES=""
TARGET_LANGUAGES=""
SKIP_FORMATS=""

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
      echo "Usage: build.sh [directory] [options]"
      echo "Options:"
      echo "  [directory]               Path to the book project (default: current working directory)"
      echo "  --languages=lang1,lang2   Only build these languages (comma-separated)"
      echo "  --skip=pdf,epub,mobi,html,docx Skip specified output formats (comma-separated)"
      echo "  --config=path             Use alternative config file (default: book.yaml)"
      echo "  --help                    Show this help message"
      exit 0
      ;;
  esac
done

echo "📚 Starting book build process..."
echo "📄 Using config file: $CONFIG_FILE"
echo "📁 Project root: $PROJECT_ROOT"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Config file not found: $CONFIG_FILE"
  exit 1
fi

# Check if pandoc is installed, suggest Docker if not
if ! command -v pandoc &> /dev/null; then
  echo "❌ Error: pandoc is not installed."
  echo "📦 For best results, consider using our Docker-based build:"
  echo ""
  echo "   $ ./docker-build.sh"
  echo ""
  echo "This will use a Docker container with all required dependencies."
  echo "To install dependencies locally instead, install pandoc and other required tools."
  exit 1
fi

# Get supported languages from config or book directory
if grep -q "^languages:" "$CONFIG_FILE"; then
  # Extract languages from config file
  SUPPORTED_LANGUAGES=$(grep "^languages:" "$CONFIG_FILE" | cut -d ':' -f 2- | sed 's/^[ \t]*//' | tr -d '[]' | tr ',' ' ')
else
  # Discover languages from book directory structure
  SUPPORTED_LANGUAGES=$(find "$PROJECT_ROOT/book" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
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
mkdir -p "$PROJECT_ROOT/build"
echo "🧹 Creating build directory..."

# Parse skip formats
SKIP_PDF=false
SKIP_EPUB=false
SKIP_HTML=false
SKIP_MOBI=false
SKIP_DOCX=false

if [ -n "$SKIP_FORMATS" ]; then
  IFS=',' read -ra SKIP_ARRAY <<< "$SKIP_FORMATS"
  for format in "${SKIP_ARRAY[@]}"; do
    case "$format" in
      pdf) SKIP_PDF=true ;;
      epub) SKIP_EPUB=true ;;
      html) SKIP_HTML=true ;;
      mobi) SKIP_MOBI=true ;;
      docx) SKIP_DOCX=true ;;
      *) echo "⚠️ Warning: Unknown format to skip: $format" ;;
    esac
  done
fi

# Start the build for each language
for language in $LANGUAGES_TO_BUILD; do
  echo ""
  echo "🔄 Starting build for language: $language"
  
  # Check if language directory exists
  if [ ! -d "$PROJECT_ROOT/book/$language" ]; then
    echo "⚠️ Warning: Directory $PROJECT_ROOT/book/$language does not exist, skipping..."
    continue
  fi
  
  # Build this language
  "$SCRIPTS_DIR/build-language.sh" "$language" "$CONFIG_FILE" "$PROJECT_ROOT" "$SKIP_PDF" "$SKIP_EPUB" "$SKIP_HTML" "$SKIP_MOBI" "$SKIP_DOCX"
  
  # Check the result
  if [ $? -eq 0 ]; then
    echo "✅ Successfully built $language version"
  else
    echo "❌ Failed to build $language version"
  fi
done

echo ""
echo "📦 Build process complete!"
echo "📂 Generated files are in the $PROJECT_ROOT/build/ directory"

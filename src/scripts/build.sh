#!/bin/bash

# build.sh - Main entry point for book-tools build system
# This script handles the entire build process for the book

set -e  # Exit on error

# Parse command line arguments
ALL_LANGUAGES=false
SKIP_PDF=false
SKIP_EPUB=false
SKIP_MOBI=false
SKIP_HTML=false
SKIP_DOCX=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --all-languages)
      ALL_LANGUAGES=true
      shift
      ;;
    --skip-pdf)
      SKIP_PDF=true
      shift
      ;;
    --skip-epub)
      SKIP_EPUB=true
      shift
      ;;
    --skip-mobi)
      SKIP_MOBI=true
      shift
      ;;
    --skip-html)
      SKIP_HTML=true
      shift
      ;;
    --skip-docx)
      SKIP_DOCX=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Export options as environment variables
export SKIP_PDF
export SKIP_EPUB
export SKIP_MOBI
export SKIP_HTML
export SKIP_DOCX
export VERBOSE

# Ensure we're in the book directory
if [ -f "book.yaml" ]; then
  echo "✅ Found book.yaml in current directory"
else
  echo "⚠️ No book.yaml found in current directory"
fi

# Create build directory
mkdir -p build

# First, handle image copying with our robust solution
echo "🖼️ Setting up images..."
source "$(dirname "$0")/copy-images.sh"

# Load configuration
echo "📚 Loading configuration..."
source "$(dirname "$0")/load-config.sh"

# Build English version
echo "🔨 Building English version..."
source "$(dirname "$0")/build-language.sh" "en"

# Build Spanish version if requested
if [ "$ALL_LANGUAGES" = true ]; then
  if [ -d "book/es" ]; then
    echo "🔨 Building Spanish version..."
    source "$(dirname "$0")/build-language.sh" "es"
  else
    echo "⚠️ Spanish content directory not found, skipping"
  fi
fi

# Print final status
echo "✅ Build process completed"
echo "Generated files:"
find build/ -type f \( -name "*.pdf" -o -name "*.epub" -o -name "*.mobi" -o -name "*.html" -o -name "*.docx" \) -exec du -h {} \; 2>/dev/null || true
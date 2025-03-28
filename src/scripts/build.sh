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

# Determine project root - handle both Docker and local environments
if [ -d "/book" ]; then
    PROJECT_ROOT="/book"
else
    PROJECT_ROOT="$(pwd)"
fi

# Export project root for other scripts
export PROJECT_ROOT

# Ensure we're in the book directory
if [ -f "$PROJECT_ROOT/book.yaml" ]; then
  echo "✅ Found book.yaml in project root"
else
  echo "⚠️ No book.yaml found in project root"
fi

# Create build directory
mkdir -p "$PROJECT_ROOT/build"

# First, handle image copying with our robust solution
echo "🖼️ Setting up images..."
source "$(dirname "$0")/copy-images.sh"

# Load configuration
echo "📚 Loading configuration..."
source "$(dirname "$0")/load-config.sh"

# Build English version first (always)
echo "🔨 Building English version..."
source "$(dirname "$0")/build-language.sh" "en"

# Build all other language versions if requested
if [ "$ALL_LANGUAGES" = true ]; then
  # Find all language directories
  for lang_dir in "$PROJECT_ROOT/book"/*/ ; do
    # Extract language code from directory path
    lang_code=$(basename "$lang_dir")
    
    # Skip English (already built) and non-language directories
    if [ "$lang_code" != "en" ] && [ "$lang_code" != "images" ]; then
      if [ -d "$lang_dir" ]; then
        echo "🔨 Building $lang_code version..."
        source "$(dirname "$0")/build-language.sh" "$lang_code"
      fi
    fi
  done
fi

# Print final status
echo "✅ Build process completed"
echo "Generated files:"
find "$PROJECT_ROOT/build/" -type f \( -name "*.pdf" -o -name "*.epub" -o -name "*.mobi" -o -name "*.html" -o -name "*.docx" \) -exec du -h {} \; 2>/dev/null || true
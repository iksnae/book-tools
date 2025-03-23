#!/bin/bash

# generate-mobi.sh - Generates MOBI version of the book
# Usage: generate-mobi.sh [language] [input_epub] [output_file] [book_title]

set -e  # Exit on error

# Get arguments
LANGUAGE=${1:-en}
INPUT_EPUB=${2:-build/book.epub}
OUTPUT_FILE=${3:-build/book.mobi}
BOOK_TITLE=${4:-"My Book"}

echo "📚 Generating MOBI for $LANGUAGE..."

# Safety check to ensure input file exists
if [ ! -f "$INPUT_EPUB" ]; then
  echo "❌ Error: Input EPUB file $INPUT_EPUB does not exist"
  exit 1
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# First check if kindlegen is available
if command -v kindlegen &> /dev/null; then
  echo "Found kindlegen, using it for MOBI conversion..."
  kindlegen "$INPUT_EPUB" -o "$(basename "$OUTPUT_FILE")" || true
  
  # kindlegen outputs to the same directory as the input file
  # So we need to move it to the desired output location if it's different
  KINDLEGEN_OUTPUT="$(dirname "$INPUT_EPUB")/$(basename "$OUTPUT_FILE")"
  if [ "$KINDLEGEN_OUTPUT" != "$OUTPUT_FILE" ]; then
    if [ -f "$KINDLEGEN_OUTPUT" ]; then
      mv "$KINDLEGEN_OUTPUT" "$OUTPUT_FILE"
    fi
  fi
  
  # Check if the conversion was successful
  if [ -f "$OUTPUT_FILE" ]; then
    echo "✅ MOBI created successfully with kindlegen"
  else
    echo "⚠️ kindlegen failed, trying alternative method..."
  fi
fi

# If kindlegen didn't work, check for Calibre's ebook-convert
if [ ! -f "$OUTPUT_FILE" ] && command -v ebook-convert &> /dev/null; then
  echo "Using ebook-convert (Calibre) for MOBI conversion..."
  ebook-convert "$INPUT_EPUB" "$OUTPUT_FILE" \
    --title="$BOOK_TITLE" \
    --language="$LANGUAGE" \
    --output-profile=kindle \
    --mobi-file-type=both \
    --no-inline-toc || true
  
  # Check if the conversion was successful
  if [ -f "$OUTPUT_FILE" ]; then
    echo "✅ MOBI created successfully with ebook-convert"
  else
    echo "⚠️ ebook-convert failed, trying last resort method..."
  fi
fi

# If both kindlegen and ebook-convert failed, try using pandoc
if [ ! -f "$OUTPUT_FILE" ] && command -v pandoc &> /dev/null; then
  echo "Attempting MOBI conversion with pandoc..."
  pandoc "$INPUT_EPUB" -o "$OUTPUT_FILE" || true
  
  if [ -f "$OUTPUT_FILE" ]; then
    echo "✅ MOBI created successfully with pandoc"
  else
    echo "❌ All MOBI conversion methods failed"
    # Create an empty file to prevent further failures in the pipeline
    touch "$OUTPUT_FILE"
  fi
fi

# Check final result
if [ -s "$OUTPUT_FILE" ]; then
  # Get the file size to give some feedback
  FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
  echo "📊 MOBI file size: $FILE_SIZE"
else
  echo "⚠️ Warning: MOBI file was created but is empty. This may indicate a conversion error."
  touch "$OUTPUT_FILE" # Ensure the file exists, even if empty
fi
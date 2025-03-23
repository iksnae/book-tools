#!/bin/bash

# generate-mobi.sh - Generates a MOBI from an EPUB file using Kindlegen
# Usage: generate-mobi.sh [language] [input_file] [output_file] [book_title]

set -e  # Exit on error

# Get parameters
LANGUAGE=${1:-en}
INPUT_FILE=${2:-build/book.epub}
OUTPUT_FILE=${3:-build/book.mobi}
BOOK_TITLE=${4:-"My Book"}

echo "📚 Generating MOBI for language: $LANGUAGE"
echo "  Input file: $INPUT_FILE"
echo "  Output file: $OUTPUT_FILE"
echo "  Book title: $BOOK_TITLE"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "⚠️ Error: Input file $INPUT_FILE doesn't exist!"
  exit 1
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Check if kindlegen is installed
if ! command -v kindlegen &> /dev/null; then
  echo "⚠️ Warning: kindlegen is not installed. Cannot create MOBI file."
  echo "You can install kindlegen from https://www.amazon.com/gp/feature.html?ie=UTF8&docId=1000765211"
  exit 1
fi

# Run kindlegen
echo "Running kindlegen to convert EPUB to MOBI..."
kindlegen "$INPUT_FILE" -o "$(basename "$OUTPUT_FILE")" 

# Check if the MOBI was created successfully
# Kindlegen outputs to the same directory as the input file, so we need to move it
GENERATED_MOBI="$(dirname "$INPUT_FILE")/$(basename "$OUTPUT_FILE")"
if [ -f "$GENERATED_MOBI" ]; then
  # If the output file is in a different location than what kindlegen produced, move it
  if [ "$GENERATED_MOBI" != "$OUTPUT_FILE" ]; then
    mv "$GENERATED_MOBI" "$OUTPUT_FILE"
  fi
  
  file_size=$(du -h "$OUTPUT_FILE" | cut -f1)
  echo "✅ Successfully created MOBI: $OUTPUT_FILE ($file_size)"
else
  echo "⚠️ Error: Failed to create MOBI!"
  exit 1
fi

# Alternatively, try using Calibre's ebook-convert if kindlegen fails
if [ $? -ne 0 ]; then
  if command -v ebook-convert &> /dev/null; then
    echo "Kindlegen failed. Trying with Calibre's ebook-convert..."
    ebook-convert "$INPUT_FILE" "$OUTPUT_FILE"
    
    if [ $? -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
      file_size=$(du -h "$OUTPUT_FILE" | cut -f1)
      echo "✅ Successfully created MOBI using Calibre: $OUTPUT_FILE ($file_size)"
    else
      echo "⚠️ Error: Failed to create MOBI with Calibre!"
      exit 1
    fi
  else
    echo "⚠️ Error: Both kindlegen and Calibre's ebook-convert are not available."
    echo "You can install Calibre from https://calibre-ebook.com/download"
    exit 1
  fi
fi
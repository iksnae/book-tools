#!/bin/bash

# generate-mobi.sh - Generates MOBI version of the book
# Usage: generate-mobi.sh [language] [epub_file] [output_file] [project_root]

set -e  # Exit on error

# Set defaults
LANGUAGE=${1:-en}
EPUB_FILE=${2:-"book.epub"}
OUTPUT_FILE=${3:-"book.mobi"}
PROJECT_ROOT=${4:-$(pwd)}

echo "📚 Generating MOBI for $LANGUAGE..."

# Check if input EPUB file exists
if [ ! -f "$EPUB_FILE" ]; then
    echo "❌ Error: EPUB file '$EPUB_FILE' not found!"
    exit 1
fi

# Check if kindlegen is available
KINDLEGEN_PATH=""
if command -v kindlegen &> /dev/null; then
    KINDLEGEN_PATH="kindlegen"
elif [ -f "$PROJECT_ROOT/bin/kindlegen" ]; then
    KINDLEGEN_PATH="$PROJECT_ROOT/bin/kindlegen"
elif [ -f "/usr/local/bin/kindlegen" ]; then
    KINDLEGEN_PATH="/usr/local/bin/kindlegen"
elif [ -f "$HOME/bin/kindlegen" ]; then
    KINDLEGEN_PATH="$HOME/bin/kindlegen"
else
    echo "⚠️ Warning: kindlegen not found. Checking for ebook-convert (Calibre)..."
    
    # Check if calibre's ebook-convert is available as alternative
    if command -v ebook-convert &> /dev/null; then
        echo "Using Calibre's ebook-convert instead of kindlegen."
        ebook-convert "$EPUB_FILE" "$OUTPUT_FILE"
        
        # Check if conversion was successful
        if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
            echo "✅ MOBI generated successfully: $OUTPUT_FILE"
            FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
            echo "File size: $FILE_SIZE"
            exit 0
        else
            echo "❌ Error: MOBI generation with Calibre failed."
            exit 1
        fi
    else
        echo "❌ Error: Neither kindlegen nor ebook-convert (Calibre) found."
        echo "Please install one of them to generate MOBI files."
        echo "- kindlegen: Download from Amazon KDP website"
        echo "- Calibre: https://calibre-ebook.com/download"
        exit 1
    fi
fi

# Generate MOBI with kindlegen
echo "Generating MOBI file: $OUTPUT_FILE"
echo "Using kindlegen at: $KINDLEGEN_PATH"

"$KINDLEGEN_PATH" "$EPUB_FILE" -o "$(basename "$OUTPUT_FILE")"

# Check if MOBI was generated successfully
MOBI_DIR=$(dirname "$EPUB_FILE")
MOBI_FILENAME=$(basename "$OUTPUT_FILE")
if [ -f "$MOBI_DIR/$MOBI_FILENAME" ]; then
    # Move the file to the correct location if needed
    if [ "$MOBI_DIR/$MOBI_FILENAME" != "$OUTPUT_FILE" ]; then
        mv "$MOBI_DIR/$MOBI_FILENAME" "$OUTPUT_FILE"
    fi
    
    echo "✅ MOBI generated successfully: $OUTPUT_FILE"
    # Get file size
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "File size: $FILE_SIZE"
else
    echo "❌ Error: Something went wrong during MOBI generation."
    exit 1
fi
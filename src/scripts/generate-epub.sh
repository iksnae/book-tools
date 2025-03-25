#!/bin/bash

# generate-epub.sh - Generates EPUB version of the book
# Usage: generate-epub.sh [language] [input_file] [output_file] [book_title] [book_subtitle] [resources_dir] [project_root]

set -e  # Exit on error

# Get arguments
LANGUAGE=${1:-en}
INPUT_FILE=${2:-"output.md"}
OUTPUT_FILE=${3:-"book.epub"}
BOOK_TITLE=${4:-"Book Title"}
BOOK_SUBTITLE=${5:-"Book Subtitle"}
RESOURCES_DIR=${6:-"resources"}
PROJECT_ROOT=${7:-$(pwd)}

echo "📱 Generating EPUB for $LANGUAGE..."

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Error: Input file '$INPUT_FILE' not found!"
    exit 1
fi

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
    echo "❌ Error: pandoc is not installed. Please install it before continuing."
    exit 1
fi

# Path to the configuration file
CONFIG_FILE="$PROJECT_ROOT/book.yaml"

# Extract author and publisher from book.yaml if available
AUTHOR="Unknown Author"
PUBLISHER="Self-Published"

if [ -f "$CONFIG_FILE" ]; then
    YAML_AUTHOR=$(grep 'author:' "$CONFIG_FILE" | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/\"//g')
    if [ -n "$YAML_AUTHOR" ]; then
        AUTHOR="$YAML_AUTHOR"
    fi
    
    YAML_PUBLISHER=$(grep 'publisher:' "$CONFIG_FILE" | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/\"//g')
    if [ -n "$YAML_PUBLISHER" ]; then
        PUBLISHER="$YAML_PUBLISHER"
    fi
fi

# Check for custom EPUB template
EPUB_TEMPLATE=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/templates/epub/template.html" ]; then
    EPUB_TEMPLATE="--template=$PROJECT_ROOT/$RESOURCES_DIR/templates/epub/template.html"
fi

# Check for custom CSS
EPUB_STYLE=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/css/epub.css" ]; then
    EPUB_STYLE="--css=$PROJECT_ROOT/$RESOURCES_DIR/css/epub.css"
fi

# Check for cover image
COVER_IMAGE=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/images/cover.jpg" ]; then
    COVER_IMAGE="--epub-cover-image=$PROJECT_ROOT/$RESOURCES_DIR/images/cover.jpg"
elif [ -f "$PROJECT_ROOT/$RESOURCES_DIR/images/cover.png" ]; then
    COVER_IMAGE="--epub-cover-image=$PROJECT_ROOT/$RESOURCES_DIR/images/cover.png"
fi

# Create extract media directory for ensuring images are included
MEDIA_DIR=$(dirname "$OUTPUT_FILE")/media
mkdir -p "$MEDIA_DIR"

# Define all image search paths
IMAGE_PATHS=(
    "$PROJECT_ROOT/$RESOURCES_DIR/images"
    "$PROJECT_ROOT/book/images"
    "$PROJECT_ROOT/book/$LANGUAGE/images"
    "$PROJECT_ROOT/build/images"
    "$PROJECT_ROOT/build/$LANGUAGE/images"
)

# Build the resource path string
RESOURCE_PATH=$(IFS=:; echo "${IMAGE_PATHS[*]}")

echo "Generating EPUB file: $OUTPUT_FILE"
echo "Using EPUB template: ${EPUB_TEMPLATE:-None}"
echo "Using EPUB style: ${EPUB_STYLE:-None}"
echo "Using cover image: ${COVER_IMAGE:-None}"
echo "Using resource paths: $RESOURCE_PATH"
echo "Author: $AUTHOR"
echo "Publisher: $PUBLISHER"

# Generate EPUB
pandoc "$INPUT_FILE" \
    -o "$OUTPUT_FILE" \
    -f markdown \
    -t epub \
    --metadata title="$BOOK_TITLE" \
    --metadata subtitle="$BOOK_SUBTITLE" \
    --metadata author="$AUTHOR" \
    --metadata publisher="$PUBLISHER" \
    --metadata lang="$LANGUAGE" \
    --toc \
    --toc-depth=3 \
    --epub-chapter-level=2 \
    --highlight-style=tango \
    --extract-media="$MEDIA_DIR" \
    --resource-path="$RESOURCE_PATH" \
    $EPUB_TEMPLATE \
    $EPUB_STYLE \
    $COVER_IMAGE

# Check if EPUB was generated successfully
if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    echo "✅ EPUB generated successfully: $OUTPUT_FILE"
    # Get file size
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "File size: $FILE_SIZE"
else
    echo "❌ Error: Something went wrong during EPUB generation."
    exit 1
fi
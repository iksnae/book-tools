#!/bin/bash

# generate-epub.sh - Generates an EPUB from a markdown file
# Usage: generate-epub.sh [language] [input_file] [output_file] [book_title] [book_subtitle] [resource_paths]

set -e  # Exit on error

# Get parameters
LANGUAGE=${1:-en}
INPUT_FILE=${2:-build/book.md}
OUTPUT_FILE=${3:-build/book.epub}
BOOK_TITLE=${4:-"My Book"}
BOOK_SUBTITLE=${5:-"A Book Built with the Template System"}
RESOURCE_PATHS=${6:-".:book:book/$LANGUAGE:build"}

echo "📱 Generating EPUB for language: $LANGUAGE"
echo "  Input file: $INPUT_FILE"
echo "  Output file: $OUTPUT_FILE"
echo "  Book title: $BOOK_TITLE"
echo "  Book subtitle: $BOOK_SUBTITLE"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "⚠️ Error: Input file $INPUT_FILE doesn't exist!"
  exit 1
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Check if custom EPUB template exists
EPUB_TEMPLATE=""
if [ -f "templates/epub/template.html" ]; then
  EPUB_TEMPLATE="--template=templates/epub/template.html"
  echo "Using custom EPUB template: templates/epub/template.html"
elif [ -f "templates/epub/$LANGUAGE-template.html" ]; then
  EPUB_TEMPLATE="--template=templates/epub/$LANGUAGE-template.html"
  echo "Using language-specific EPUB template: templates/epub/$LANGUAGE-template.html"
fi

# Check for EPUB style
EPUB_STYLE=""
if [ -f "templates/epub/style.css" ]; then
  EPUB_STYLE="--css=templates/epub/style.css"
  echo "Using custom EPUB style: templates/epub/style.css"
elif [ -f "templates/epub/$LANGUAGE-style.css" ]; then
  EPUB_STYLE="--css=templates/epub/$LANGUAGE-style.css"
  echo "Using language-specific EPUB style: templates/epub/$LANGUAGE-style.css"
fi

# Check for cover image
COVER_IMAGE=""
if [ -f "book/images/cover.jpg" ]; then
  COVER_IMAGE="--epub-cover-image=book/images/cover.jpg"
  echo "Using cover image: book/images/cover.jpg"
elif [ -f "book/images/cover.png" ]; then
  COVER_IMAGE="--epub-cover-image=book/images/cover.png"
  echo "Using cover image: book/images/cover.png"
elif [ -f "book/$LANGUAGE/images/cover.jpg" ]; then
  COVER_IMAGE="--epub-cover-image=book/$LANGUAGE/images/cover.jpg"
  echo "Using language-specific cover image: book/$LANGUAGE/images/cover.jpg"
elif [ -f "book/$LANGUAGE/images/cover.png" ]; then
  COVER_IMAGE="--epub-cover-image=book/$LANGUAGE/images/cover.png"
  echo "Using language-specific cover image: book/$LANGUAGE/images/cover.png"
else
  echo "No cover image found, EPUB will not have a cover."
fi

# Define EPUB metadata
EPUB_METADATA=(
  "--metadata=title:$BOOK_TITLE"
  "--metadata=lang:$LANGUAGE"
)

# Add subtitle if present
if [ -n "$BOOK_SUBTITLE" ]; then
  EPUB_METADATA+=("--metadata=subtitle:$BOOK_SUBTITLE")
fi

# Check if book.yaml contains author for metadata
if [ -n "$BOOK_AUTHOR" ]; then
  EPUB_METADATA+=("--metadata=author:$BOOK_AUTHOR")
fi

# Ensure image paths are correctly handled
IMAGE_PATHS="--resource-path=$RESOURCE_PATHS"

# Set EPUB-specific options
EPUB_OPTIONS=(
  "--toc"
  "--toc-depth=3"
  "--epub-chapter-level=1"
  "--number-sections"
  "--standalone"
  "--highlight-style=tango"
)

# Build the pandoc command
PANDOC_CMD=(
  "pandoc"
  "$INPUT_FILE"
  "-o" "$OUTPUT_FILE"
  "${EPUB_METADATA[@]}"
  "$IMAGE_PATHS"
  "${EPUB_OPTIONS[@]}"
)

# Add conditional options if they're set
if [ -n "$EPUB_TEMPLATE" ]; then
  PANDOC_CMD+=("$EPUB_TEMPLATE")
fi

if [ -n "$EPUB_STYLE" ]; then
  PANDOC_CMD+=("$EPUB_STYLE")
fi

if [ -n "$COVER_IMAGE" ]; then
  PANDOC_CMD+=("$COVER_IMAGE")
fi

# Run the pandoc command
echo "Executing pandoc command to generate EPUB..."
echo "${PANDOC_CMD[@]}"
"${PANDOC_CMD[@]}"

# Check if the EPUB was created successfully
if [ -f "$OUTPUT_FILE" ]; then
  file_size=$(du -h "$OUTPUT_FILE" | cut -f1)
  echo "✅ Successfully created EPUB: $OUTPUT_FILE ($file_size)"
else
  echo "⚠️ Error: Failed to create EPUB!"
  exit 1
fi
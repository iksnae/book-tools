#!/bin/bash

# generate-html.sh - Generates HTML from a markdown file
# Usage: generate-html.sh [language] [input_file] [output_file] [book_title] [book_subtitle] [resources_dir] [project_root]

set -e  # Exit on error

# Get parameters
LANGUAGE=${1:-en}
INPUT_FILE=${2:-"output.md"}
OUTPUT_FILE=${3:-"book.html"}
BOOK_TITLE=${4:-"Book Title"}
BOOK_SUBTITLE=${5:-"Book Subtitle"}
RESOURCES_DIR=${6:-"resources"}
PROJECT_ROOT=${7:-$(pwd)}

echo "🌐 Generating HTML for language: $LANGUAGE"
echo "  Input file: $INPUT_FILE"
echo "  Output file: $OUTPUT_FILE"
echo "  Book title: $BOOK_TITLE"
echo "  Book subtitle: $BOOK_SUBTITLE"
echo "  Resources directory: $RESOURCES_DIR"
echo "  Project root: $PROJECT_ROOT"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "❌ Error: Input file $INPUT_FILE does not exist"
  exit 1
fi

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
  echo "❌ Error: pandoc is not installed. Please install it before continuing."
  exit 1
fi

# Check for custom HTML template
HTML_TEMPLATE=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/templates/html/template.html" ]; then
  HTML_TEMPLATE="--template=$PROJECT_ROOT/$RESOURCES_DIR/templates/html/template.html"
  echo "Using custom HTML template: $PROJECT_ROOT/$RESOURCES_DIR/templates/html/template.html"
elif [ -f "$PROJECT_ROOT/$RESOURCES_DIR/templates/html/default.html" ]; then
  HTML_TEMPLATE="--template=$PROJECT_ROOT/$RESOURCES_DIR/templates/html/default.html"
  echo "Using default HTML template: $PROJECT_ROOT/$RESOURCES_DIR/templates/html/default.html"
fi

# Check for custom CSS
HTML_STYLE=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/css/html.css" ]; then
  HTML_STYLE="--css=$PROJECT_ROOT/$RESOURCES_DIR/css/html.css"
  echo "Using custom HTML style: $PROJECT_ROOT/$RESOURCES_DIR/css/html.css"
fi

# Create a variable for image path
IMAGE_PATH="$PROJECT_ROOT/$RESOURCES_DIR/images"

# Make sure the output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Prepare HTML metadata and options
HTML_METADATA=(
  "--metadata=title:$BOOK_TITLE"
  "--metadata=subtitle:$BOOK_SUBTITLE"
  "--metadata=lang:$LANGUAGE"
)

# Define HTML options
HTML_OPTIONS=(
  "--toc"
  "--toc-depth=3"
  "--number-sections"
  "--standalone"
  "--highlight-style=tango"
)

# Ensure images are embedded in the HTML
if pandoc --version | grep -q "pandoc 3"; then
  # For pandoc 3.x, use --embed-resources
  HTML_OPTIONS+=("--embed-resources")
else
  # For older pandoc versions, use --self-contained
  HTML_OPTIONS+=("--self-contained")
fi

# Add template and style if available
if [ -n "$HTML_TEMPLATE" ]; then
  HTML_OPTIONS+=("$HTML_TEMPLATE")
fi

if [ -n "$HTML_STYLE" ]; then
  HTML_OPTIONS+=("$HTML_STYLE")
fi

# Build the command
PANDOC_CMD=(
  "pandoc"
  "$INPUT_FILE"
  "-o" "$OUTPUT_FILE"
  "${HTML_METADATA[@]}"
  "--resource-path=$IMAGE_PATH"
  "${HTML_OPTIONS[@]}"
)

# Execute the command
echo "Executing pandoc command to generate HTML..."
echo "${PANDOC_CMD[@]}"
"${PANDOC_CMD[@]}"

# Check if HTML was generated
if [ -f "$OUTPUT_FILE" ]; then
  echo "✅ HTML generated successfully: $OUTPUT_FILE"
  
  # Get file size
  FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
  echo "File size: $FILE_SIZE"
else
  echo "❌ Error: HTML generation failed."
  exit 1
fi
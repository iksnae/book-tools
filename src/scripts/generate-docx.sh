#!/bin/bash

# generate-docx.sh - Generates DOCX from markdown
# Usage: generate-docx.sh [language] [input_file] [output_file] [book_title] [book_subtitle] [resources_path] [project_root]

set -e  # Exit on error

# Get arguments
LANGUAGE=${1:-en}
INPUT_PATH=${2:-build/en/book.md}
OUTPUT_PATH=${3:-build/en/book.docx}
BOOK_TITLE=${4:-"Test Book"}
BOOK_SUBTITLE=${5:-"A Test Book"}
RESOURCES_PATH=${6:-resources}
PROJECT_ROOT=${7:-$(pwd)}

echo "📄 Generating DOCX for $LANGUAGE..."
echo "  - Input: $INPUT_PATH"
echo "  - Output: $OUTPUT_PATH"
echo "  - Title: $BOOK_TITLE"

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Look for a reference document
REFERENCE_DOC=""
if [ -f "$PROJECT_ROOT/templates/docx/reference.docx" ]; then
  REFERENCE_DOC="--reference-doc=$PROJECT_ROOT/templates/docx/reference.docx"
  echo "Using reference document: $PROJECT_ROOT/templates/docx/reference.docx"
elif [ -f "$PROJECT_ROOT/resources/templates/docx/reference.docx" ]; then
  REFERENCE_DOC="--reference-doc=$PROJECT_ROOT/resources/templates/docx/reference.docx"
  echo "Using reference document: $PROJECT_ROOT/resources/templates/docx/reference.docx" 
fi

# Base arguments
PANDOC_ARGS="-s -f markdown -t docx"
PANDOC_ARGS="$PANDOC_ARGS --table-of-contents"
PANDOC_ARGS="$PANDOC_ARGS --toc-depth=3"
PANDOC_ARGS="$PANDOC_ARGS --metadata=title:\"$BOOK_TITLE\""
PANDOC_ARGS="$PANDOC_ARGS --metadata=author:\"Author\""
PANDOC_ARGS="$PANDOC_ARGS --metadata=lang:\"$LANGUAGE\""

# Add reference document if present
if [ -n "$REFERENCE_DOC" ]; then
  PANDOC_ARGS="$PANDOC_ARGS $REFERENCE_DOC"
fi

# Add resource paths
RESOURCE_DIRS=(
  "$PROJECT_ROOT/book/images"
  "$PROJECT_ROOT/book/$LANGUAGE/images"
  "$PROJECT_ROOT/resources/images"
)

RESOURCE_PATH_ARG=""
for dir in "${RESOURCE_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    if [ -z "$RESOURCE_PATH_ARG" ]; then
      RESOURCE_PATH_ARG="--resource-path=\"$dir\""
    else
      RESOURCE_PATH_ARG="$RESOURCE_PATH_ARG --resource-path=\"$dir\""
    fi
  fi
done

if [ -n "$RESOURCE_PATH_ARG" ]; then
  PANDOC_ARGS="$PANDOC_ARGS $RESOURCE_PATH_ARG"
fi

# Build the full command
PANDOC_CMD="pandoc $PANDOC_ARGS -o \"$OUTPUT_PATH\" \"$INPUT_PATH\""

# Execute pandoc
echo "Running pandoc command:"
echo "$PANDOC_CMD"

eval "$PANDOC_CMD"

# Check if the file was created
if [ -f "$OUTPUT_PATH" ]; then
  echo "✅ DOCX file generated: $OUTPUT_PATH"
  if command -v ls &> /dev/null; then
    ls -lh "$OUTPUT_PATH"
  fi
else
  echo "❌ Failed to create DOCX file"
  exit 1
fi

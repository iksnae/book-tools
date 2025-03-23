#!/bin/bash

# generate-pdf.sh - Generates a PDF from a markdown file
# Usage: generate-pdf.sh [language] [input_file] [output_file] [book_title] [resource_paths]

set -e  # Exit on error

# Get parameters
LANGUAGE=${1:-en}
INPUT_FILE=${2:-build/book.md}
OUTPUT_FILE=${3:-build/book.pdf}
BOOK_TITLE=${4:-"My Book"}
RESOURCE_PATHS=${5:-".:book:book/$LANGUAGE:build"}

echo "📄 Generating PDF for language: $LANGUAGE"
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

# Check if custom PDF template exists
PDF_TEMPLATE=""
if [ -f "templates/pdf/template.tex" ]; then
  PDF_TEMPLATE="--template=templates/pdf/template.tex"
  echo "Using custom PDF template: templates/pdf/template.tex"
elif [ -f "templates/pdf/$LANGUAGE-template.tex" ]; then
  PDF_TEMPLATE="--template=templates/pdf/$LANGUAGE-template.tex"
  echo "Using language-specific PDF template: templates/pdf/$LANGUAGE-template.tex"
fi

# Check for PDF style
PDF_STYLE=""
if [ -f "templates/pdf/style.css" ]; then
  PDF_STYLE="--css=templates/pdf/style.css"
  echo "Using custom PDF style: templates/pdf/style.css"
elif [ -f "templates/pdf/$LANGUAGE-style.css" ]; then
  PDF_STYLE="--css=templates/pdf/$LANGUAGE-style.css"
  echo "Using language-specific PDF style: templates/pdf/$LANGUAGE-style.css"
fi

# Configure margins, font size, etc.
MARGIN_TOP="1in"
MARGIN_RIGHT="1in"
MARGIN_BOTTOM="1in"
MARGIN_LEFT="1.25in"  # Extra for binding
FONT_SIZE="11pt"
PAPER_SIZE="letter"

# Check if book.yaml contains PDF settings
if [ -f "book.yaml" ]; then
  # Extract PDF settings if they exist
  if grep -q "pdf_margin_top:" book.yaml; then
    MARGIN_TOP=$(grep "pdf_margin_top:" book.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/"//g')
  fi
  
  if grep -q "pdf_margin_right:" book.yaml; then
    MARGIN_RIGHT=$(grep "pdf_margin_right:" book.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/"//g')
  fi
  
  if grep -q "pdf_margin_bottom:" book.yaml; then
    MARGIN_BOTTOM=$(grep "pdf_margin_bottom:" book.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/"//g')
  fi
  
  if grep -q "pdf_margin_left:" book.yaml; then
    MARGIN_LEFT=$(grep "pdf_margin_left:" book.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/"//g')
  fi
  
  if grep -q "pdf_font_size:" book.yaml; then
    FONT_SIZE=$(grep "pdf_font_size:" book.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/"//g')
  fi
  
  if grep -q "pdf_paper_size:" book.yaml; then
    PAPER_SIZE=$(grep "pdf_paper_size:" book.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/"//g')
  fi
fi

echo "PDF settings:"
echo "  Margins: $MARGIN_TOP (top), $MARGIN_RIGHT (right), $MARGIN_BOTTOM (bottom), $MARGIN_LEFT (left)"
echo "  Font size: $FONT_SIZE"
echo "  Paper size: $PAPER_SIZE"

# Use XeLaTeX engine to support more fonts and Unicode
PDF_ENGINE="--pdf-engine=xelatex"

# Define PDF metadata
PDF_METADATA=(
  "--metadata=title:$BOOK_TITLE"
  "--metadata=lang:$LANGUAGE"
)

# Check if book.yaml contains author for metadata
if [ -n "$BOOK_AUTHOR" ]; then
  PDF_METADATA+=("--metadata=author:$BOOK_AUTHOR")
fi

# Ensure image paths are correctly handled
IMAGE_PATHS="--resource-path=$RESOURCE_PATHS"

# Set margin and other formatting variables
VARIABLES=(
  "--variable=geometry:margin=$MARGIN_TOP $MARGIN_RIGHT $MARGIN_BOTTOM $MARGIN_LEFT"
  "--variable=fontsize:$FONT_SIZE"
  "--variable=papersize:$PAPER_SIZE"
  "--variable=documentclass:book"
  "--variable=toc-depth:3"
  "--variable=mainfont:DejaVu Serif"
  "--variable=sansfont:DejaVu Sans"
  "--variable=monofont:DejaVu Sans Mono"
  "--variable=colorlinks:true"
  "--variable=linkcolor:blue"
  "--variable=urlcolor:red"
)

# Additional options for better PDF output
OPTIONS=(
  "--toc"
  "--toc-depth=3"
  "--number-sections"
  "--standalone"
  "--highlight-style=tango"
)

# Build the pandoc command
PANDOC_CMD=(
  "pandoc"
  "$INPUT_FILE"
  "-o" "$OUTPUT_FILE"
  "$PDF_ENGINE"
  "${PDF_METADATA[@]}"
  "$IMAGE_PATHS"
  "${VARIABLES[@]}"
  "${OPTIONS[@]}"
)

# Add conditional options if they're set
if [ -n "$PDF_TEMPLATE" ]; then
  PANDOC_CMD+=("$PDF_TEMPLATE")
fi

if [ -n "$PDF_STYLE" ]; then
  PANDOC_CMD+=("$PDF_STYLE")
fi

# Run the pandoc command
echo "Executing pandoc command to generate PDF..."
echo "${PANDOC_CMD[@]}"
"${PANDOC_CMD[@]}"

# Check if the PDF was created successfully
if [ -f "$OUTPUT_FILE" ]; then
  file_size=$(du -h "$OUTPUT_FILE" | cut -f1)
  echo "✅ Successfully created PDF: $OUTPUT_FILE ($file_size)"
else
  echo "⚠️ Error: Failed to create PDF!"
  exit 1
fi
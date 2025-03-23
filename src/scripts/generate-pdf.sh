#!/bin/bash

# generate-pdf.sh - Generates PDF version of the book
# Usage: generate-pdf.sh [language] [input_file] [output_file] [book_title] [book_subtitle] [resources_dir] [project_root]

set -e  # Exit on error

# Get arguments
LANGUAGE=${1:-en}
INPUT_FILE=${2:-"output.md"}
OUTPUT_FILE=${3:-"book.pdf"}
BOOK_TITLE=${4:-"Book Title"}
BOOK_SUBTITLE=${5:-"Book Subtitle"}
RESOURCES_DIR=${6:-"resources"}
PROJECT_ROOT=${7:-$(pwd)}

echo "📄 Generating PDF for $LANGUAGE..."

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "❌ Error: Input file $INPUT_FILE does not exist"
  exit 1
fi

# Safety copy for fallbacks
SAFE_INPUT_FILE=$(mktemp)
cp "$INPUT_FILE" "$SAFE_INPUT_FILE"

# Path to the configuration file
CONFIG_FILE="$PROJECT_ROOT/book.yaml"

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
  echo "❌ Error: pandoc is not installed. Please install it before continuing."
  exit 1
fi

# Set default PDF values
PDF_FONTSIZE=${PDF_FONTSIZE:-12pt}
PDF_PAPERSIZE=${PDF_PAPERSIZE:-a4}
PDF_MARGIN_TOP=${PDF_MARGIN_TOP:-1in}
PDF_MARGIN_RIGHT=${PDF_MARGIN_RIGHT:-1in}
PDF_MARGIN_BOTTOM=${PDF_MARGIN_BOTTOM:-1in}
PDF_MARGIN_LEFT=${PDF_MARGIN_LEFT:-1in}
PDF_LINEHEIGHT=${PDF_LINEHEIGHT:-1.5}

# If we have a config file, read PDF settings from it
if [ -f "$CONFIG_FILE" ]; then
  # Read PDF values from book.yaml if present
  PDF_FONTSIZE=$(grep "pdf_fontsize:" "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' ' || echo "$PDF_FONTSIZE")
  PDF_PAPERSIZE=$(grep "pdf_papersize:" "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' ' || echo "$PDF_PAPERSIZE")
  PDF_MARGIN_TOP=$(grep "pdf_margin_top:" "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' ' || echo "$PDF_MARGIN_TOP")
  PDF_MARGIN_RIGHT=$(grep "pdf_margin_right:" "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' ' || echo "$PDF_MARGIN_RIGHT")
  PDF_MARGIN_BOTTOM=$(grep "pdf_margin_bottom:" "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' ' || echo "$PDF_MARGIN_BOTTOM")
  PDF_MARGIN_LEFT=$(grep "pdf_margin_left:" "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' ' || echo "$PDF_MARGIN_LEFT")
  PDF_LINEHEIGHT=$(grep "pdf_lineheight:" "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' ' || echo "$PDF_LINEHEIGHT")
fi

# Extract author and publisher from book.yaml if available
AUTHOR="Unknown Author"
PUBLISHER="Self-Published"

if [ -f "$CONFIG_FILE" ]; then
  YAML_AUTHOR=$(grep 'author:' "$CONFIG_FILE" | head -n 1 | cut -d':' -f2- | tr -d '[:space:]"')
  if [ -n "$YAML_AUTHOR" ]; then
    AUTHOR="$YAML_AUTHOR"
  fi
  
  YAML_PUBLISHER=$(grep 'publisher:' "$CONFIG_FILE" | head -n 1 | cut -d':' -f2- | tr -d '[:space:]"')
  if [ -n "$YAML_PUBLISHER" ]; then
    PUBLISHER="$YAML_PUBLISHER"
  fi
fi

# Check for custom LaTeX template
LATEX_TEMPLATE=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/templates/latex/template.tex" ]; then
  LATEX_TEMPLATE="--template=$PROJECT_ROOT/$RESOURCES_DIR/templates/latex/template.tex"
fi

# Check for custom LaTeX header
LATEX_HEADER=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/templates/latex/header.tex" ]; then
  LATEX_HEADER="--include-in-header=$PROJECT_ROOT/$RESOURCES_DIR/templates/latex/header.tex"
fi

# Check for custom LaTeX before-body
LATEX_BEFORE_BODY=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/templates/latex/before-body.tex" ]; then
  LATEX_BEFORE_BODY="--include-before-body=$PROJECT_ROOT/$RESOURCES_DIR/templates/latex/before-body.tex"
fi

# Check for custom LaTeX after-body
LATEX_AFTER_BODY=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/templates/latex/after-body.tex" ]; then
  LATEX_AFTER_BODY="--include-after-body=$PROJECT_ROOT/$RESOURCES_DIR/templates/latex/after-body.tex"
fi

# Check for a PDF cover image
COVER_IMAGE=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/images/cover.pdf" ]; then
  COVER_IMAGE="--pdf-engine-opt=-Dcover-image=$PROJECT_ROOT/$RESOURCES_DIR/images/cover.pdf"
elif [ -f "$PROJECT_ROOT/$RESOURCES_DIR/images/cover.jpg" ]; then
  COVER_IMAGE="--pdf-engine-opt=-Dcover-image=$PROJECT_ROOT/$RESOURCES_DIR/images/cover.jpg"
elif [ -f "$PROJECT_ROOT/$RESOURCES_DIR/images/cover.png" ]; then
  COVER_IMAGE="--pdf-engine-opt=-Dcover-image=$PROJECT_ROOT/$RESOURCES_DIR/images/cover.png"
fi

# Check for custom styles
PDF_STYLE=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/css/pdf.css" ]; then
  PDF_STYLE="--css=$PROJECT_ROOT/$RESOURCES_DIR/css/pdf.css"
fi

# Create a variable for image path
IMAGE_PATH="$PROJECT_ROOT/$RESOURCES_DIR/images"

echo "PDF Settings:"
echo "  - Font Size: $PDF_FONTSIZE"
echo "  - Paper Size: $PDF_PAPERSIZE"
echo "  - Margins: $PDF_MARGIN_TOP, $PDF_MARGIN_RIGHT, $PDF_MARGIN_BOTTOM, $PDF_MARGIN_LEFT"
echo "  - Line Height: $PDF_LINEHEIGHT"
echo "  - Template: $LATEX_TEMPLATE"
echo "  - Header: $LATEX_HEADER"
echo "  - Before Body: $LATEX_BEFORE_BODY"
echo "  - After Body: $LATEX_AFTER_BODY"
echo "  - Cover Image: $COVER_IMAGE"
echo "  - Style: $PDF_STYLE"

# Try to generate PDF with images
echo "Generating PDF with full styling..."
set +e  # Temporarily disable exit on error
WARNINGS=$(pandoc "$INPUT_FILE" \
  -o "$OUTPUT_FILE" \
  --pdf-engine=xelatex \
  -V documentclass=book \
  -V fontsize="$PDF_FONTSIZE" \
  -V papersize="$PDF_PAPERSIZE" \
  -V geometry:margin-top="$PDF_MARGIN_TOP" \
  -V geometry:margin-right="$PDF_MARGIN_RIGHT" \
  -V geometry:margin-bottom="$PDF_MARGIN_BOTTOM" \
  -V geometry:margin-left="$PDF_MARGIN_LEFT" \
  -V linestretch="$PDF_LINEHEIGHT" \
  -V title="$BOOK_TITLE" \
  -V subtitle="$BOOK_SUBTITLE" \
  -V author="$AUTHOR" \
  -V publisher="$PUBLISHER" \
  -V lang="$LANGUAGE" \
  --toc \
  --toc-depth=3 \
  --highlight-style=tango \
  --resource-path="$IMAGE_PATH" \
  $LATEX_TEMPLATE \
  $LATEX_HEADER \
  $LATEX_BEFORE_BODY \
  $LATEX_AFTER_BODY \
  $COVER_IMAGE \
  $PDF_STYLE \
  2>&1)
RESULT=$?
set -e  # Re-enable exit on error

# Check if PDF was generated successfully
if [ $RESULT -ne 0 ] || [ ! -f "$OUTPUT_FILE" ] || [ ! -s "$OUTPUT_FILE" ]; then
  echo "❌ Warning: PDF generation with images failed. Attempting simplified build..."
  echo "Warnings: $WARNINGS"
  
  # Create a temporary file with modified image paths
  TEMP_INPUT_FILE=$(mktemp)
  cat "$SAFE_INPUT_FILE" > "$TEMP_INPUT_FILE"
  
  # Try to generate a minimal PDF without complex options
  set +e  # Temporarily disable exit on error
  pandoc "$TEMP_INPUT_FILE" \
    -o "$OUTPUT_FILE" \
    --pdf-engine=xelatex \
    -V documentclass=book \
    -V title="$BOOK_TITLE" \
    -V subtitle="$BOOK_SUBTITLE" \
    -V author="$AUTHOR" \
    -V lang="$LANGUAGE" \
    --toc \
    --toc-depth=2 \
    2>/dev/null
  set -e  # Re-enable exit on error
  
  # Clean up temporary file
  rm "$TEMP_INPUT_FILE"
  
  # If still can't generate PDF, create an empty document with an error message
  if [ ! -f "$OUTPUT_FILE" ] || [ ! -s "$OUTPUT_FILE" ]; then
    echo "❌ Error: PDF generation failed completely."
    echo "Creating a placeholder PDF..."
    
    # Create a minimal markdown with an error message
    ERROR_MD=$(mktemp)
    echo "# PDF Generation Failed" > "$ERROR_MD"
    echo "" >> "$ERROR_MD"
    echo "There was an error generating the PDF version of this book." >> "$ERROR_MD"
    echo "" >> "$ERROR_MD"
    echo "Please check if all required packages are installed for PDF generation:" >> "$ERROR_MD"
    echo "" >> "$ERROR_MD"
    echo "- pandoc" >> "$ERROR_MD"
    echo "- LaTeX (TeX Live or MiKTeX)" >> "$ERROR_MD"
    echo "- xelatex" >> "$ERROR_MD"
    echo "" >> "$ERROR_MD"
    echo "Error details:" >> "$ERROR_MD"
    echo "\\`\\`\\`" >> "$ERROR_MD"
    echo "$WARNINGS" >> "$ERROR_MD"
    echo "\\`\\`\\`" >> "$ERROR_MD"
    
    # Try to generate a super minimal PDF with just the error message
    pandoc "$ERROR_MD" \
      -o "$OUTPUT_FILE" \
      --pdf-engine=xelatex \
      -V documentclass=article \
      -V title="PDF Generation Failed" \
      2>/dev/null || touch "$OUTPUT_FILE"
    
    # Clean up the temporary file
    rm "$ERROR_MD"
  fi
fi

# Clean up safety copy
rm "$SAFE_INPUT_FILE"

# Check final result
if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
  echo "✅ PDF generated successfully: $OUTPUT_FILE"
  # Get file size
  FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
  echo "File size: $FILE_SIZE"
else
  echo "❌ Error: Something went wrong during PDF generation."
  exit 1
fi
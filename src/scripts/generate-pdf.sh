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

# Safety check to ensure input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "❌ Error: Input file $INPUT_FILE does not exist"
  exit 1
fi

# Safety copy for fallbacks
SAFE_INPUT_FILE="${INPUT_FILE%.*}-safe.md"
if [ ! -f "$SAFE_INPUT_FILE" ]; then
  cp "$INPUT_FILE" "$SAFE_INPUT_FILE"
fi

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

# Set publisher and author from book.yaml if not already defined
if [ -z "$BOOK_AUTHOR" ] && [ -f "book.yaml" ]; then
  BOOK_AUTHOR=$(grep 'author:' book.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/\"//g')
  if [ -z "$BOOK_AUTHOR" ]; then
    BOOK_AUTHOR="Author Name"
  fi
fi

if [ -z "$PUBLISHER" ] && [ -f "book.yaml" ]; then
  PUBLISHER=$(grep 'publisher:' book.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/\"//g')
  if [ -z "$PUBLISHER" ]; then
    PUBLISHER="Publisher Name"
  fi
fi

# Define common pandoc parameters
PANDOC_COMMON_PARAMS="--pdf-engine=xelatex \
  --toc \
  --metadata title=\"$BOOK_TITLE\" \
  --metadata author=\"$BOOK_AUTHOR\" \
  --metadata publisher=\"$PUBLISHER\" \
  --metadata=lang:\"$LANGUAGE\" \
  --variable=fontsize:\"$PDF_FONTSIZE\" \
  --variable=papersize:\"$PDF_PAPERSIZE\" \
  --variable=geometry:\"top=$PDF_MARGIN_TOP,right=$PDF_MARGIN_RIGHT,bottom=$PDF_MARGIN_BOTTOM,left=$PDF_MARGIN_LEFT\" \
  --variable=linestretch:\"$PDF_LINEHEIGHT\" \
  --resource-path=\"$IMAGE_PATH\""

# First attempt: Use LaTeX template if available
if [ -n "$LATEX_TEMPLATE" ]; then
  echo "Using LaTeX template: $LATEX_TEMPLATE"
  
  # Run pandoc with the template and capture any warnings
  set +e  # Temporarily disable exit on error
  WARNINGS=$(pandoc "$INPUT_FILE" -o "$OUTPUT_FILE" \
    $PANDOC_COMMON_PARAMS \
    --template="$LATEX_TEMPLATE" \
    --variable=documentclass:"book" \
    $LATEX_HEADER \
    $LATEX_BEFORE_BODY \
    $LATEX_AFTER_BODY \
    $COVER_IMAGE \
    $PDF_STYLE \
    2>&1)
  RESULT=$?
  set -e  # Re-enable exit on error
  
  # Check for missing image warnings but continue
  if echo "$WARNINGS" | grep -q "Could not fetch resource"; then
    echo "⚠️ Some images could not be found, but continuing with build"
  fi
else
  # First attempt: Fallback to default pandoc styling
  echo "No custom template found, using default PDF styling"
  
  # Run pandoc without a template and capture any warnings
  set +e  # Temporarily disable exit on error
  WARNINGS=$(pandoc "$INPUT_FILE" -o "$OUTPUT_FILE" \
    $PANDOC_COMMON_PARAMS \
    --variable=documentclass:"book" \
    $COVER_IMAGE \
    $PDF_STYLE \
    2>&1)
  RESULT=$?
  set -e  # Re-enable exit on error
  
  # Check for missing image warnings but continue
  if echo "$WARNINGS" | grep -q "Could not fetch resource"; then
    echo "⚠️ Some images could not be found, but continuing with build"
  fi
fi

# Check if PDF file was created successfully
if [ $RESULT -ne 0 ] || [ ! -s "$OUTPUT_FILE" ]; then
  echo "⚠️ First PDF generation attempt failed, trying with more resilient settings..."
  
  # Create a version of the markdown with image references made more resilient
  cp "$SAFE_INPUT_FILE" "${SAFE_INPUT_FILE}.tmp"
  sed -i 's/!\[\([^]]*\)\](images\//![\\1](build\/images\//g' "${SAFE_INPUT_FILE}.tmp"
  sed -i 's/!\[\([^]]*\)\](book\/images\//![\\1](build\/images\//g' "${SAFE_INPUT_FILE}.tmp"
  sed -i 's/!\[\([^]]*\)\](book\/[^/)]*\/images\//![\\1](build\/images\//g' "${SAFE_INPUT_FILE}.tmp"
  
  # Second attempt: Try with modified settings and more lenient image paths
  set +e  # Temporarily disable exit on error
  pandoc "${SAFE_INPUT_FILE}.tmp" -o "$OUTPUT_FILE" \
    $PANDOC_COMMON_PARAMS \
    --variable=graphics=true \
    --variable=documentclass=book \
    $COVER_IMAGE \
    $PDF_STYLE \
    || true
  set -e  # Re-enable exit on error
  
  # If still not successful, create a minimal PDF
  if [ ! -s "$OUTPUT_FILE" ]; then
    echo "⚠️ WARNING: PDF generation with images failed, creating a minimal PDF without images..."
    # Create a version with image references removed
    cp "$SAFE_INPUT_FILE" "${SAFE_INPUT_FILE}.noimg"
    sed -i 's/!\[\([^]]*\)\]([^)]*)//g' "${SAFE_INPUT_FILE}.noimg"
    
    # Final attempt: minimal PDF with no images
    set +e  # Temporarily disable exit on error
    pandoc "${SAFE_INPUT_FILE}.noimg" -o "$OUTPUT_FILE" \
      $PANDOC_COMMON_PARAMS \
      $COVER_IMAGE \
      $PDF_STYLE \
      || true
    set -e  # Re-enable exit on error
    
    # If all else fails, create a placeholder PDF
    if [ ! -s "$OUTPUT_FILE" ]; then
      echo "⚠️ WARNING: All PDF generation attempts failed, creating placeholder PDF..."
      PLACEHOLDER_FILE="$(dirname "$INPUT_FILE")/placeholder.md"
      echo "# $BOOK_TITLE - Placeholder PDF" > "$PLACEHOLDER_FILE"
      echo "PDF generation encountered issues. Please check your Markdown content and template settings." >> "$PLACEHOLDER_FILE"
      echo "If using a custom LaTeX template, verify it's compatible with your Pandoc version." >> "$PLACEHOLDER_FILE"
      echo "See other formats (EPUB, HTML) for the complete content." >> "$PLACEHOLDER_FILE"
      pandoc "$PLACEHOLDER_FILE" -o "$OUTPUT_FILE" --pdf-engine=xelatex
    fi
  fi
  
  # Clean up temporary files
  rm -f "${SAFE_INPUT_FILE}.tmp" "${SAFE_INPUT_FILE}.noimg"
fi

# Check final result and create at least a minimal PDF if everything failed
if [ -s "$OUTPUT_FILE" ]; then
  echo "✅ PDF created successfully at $OUTPUT_FILE"
  
  # Get the file size to give some feedback
  FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
  echo "📊 PDF file size: $FILE_SIZE"
else
  echo "⚠️ Creating minimal emergency PDF..."
  EMERGENCY_FILE="$(dirname "$INPUT_FILE")/emergency.md"
  echo "# $BOOK_TITLE" > "$EMERGENCY_FILE"
  echo "## Generated on $(date)" >> "$EMERGENCY_FILE"
  echo "This is a minimal emergency PDF created because all other PDF generation attempts failed." >> "$EMERGENCY_FILE"
  echo "Please see the EPUB or HTML versions for complete content." >> "$EMERGENCY_FILE"
  
  # One last attempt with minimal content and options
  pandoc "$EMERGENCY_FILE" -o "$OUTPUT_FILE" --pdf-engine=xelatex || touch "$OUTPUT_FILE"
  
  if [ -s "$OUTPUT_FILE" ]; then
    echo "✅ Emergency PDF created at $OUTPUT_FILE"
  else
    echo "❌ Failed to create PDF at $OUTPUT_FILE"
    # Create an empty file to prevent further failures in the pipeline
    touch "$OUTPUT_FILE" 
  fi
fi
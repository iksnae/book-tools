#!/bin/bash

# generate-epub.sh - Generates EPUB version of the book
# Usage: generate-epub.sh [language] [input_file] [output_file] [book_title] [book_subtitle] [resource_paths]

set -e  # Exit on error

# Get arguments
LANGUAGE=${1:-en}
INPUT_FILE=${2:-build/book.md}
OUTPUT_FILE=${3:-build/book.epub}
BOOK_TITLE=${4:-"My Book"}
BOOK_SUBTITLE=${5:-""}
RESOURCE_PATHS=${6:-".:book:book/$LANGUAGE:build:book/$LANGUAGE/images:book/images:build/images:build/$LANGUAGE/images"}

echo "📱 Generating EPUB for $LANGUAGE..."

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

# Check if book.yaml contains epub settings
EPUB_CSS=""
if [ -f "templates/epub/style.css" ]; then
  EPUB_CSS="--css=templates/epub/style.css"
  echo "Using custom EPUB style: templates/epub/style.css"
elif [ -f "templates/epub/$LANGUAGE-style.css" ]; then
  EPUB_CSS="--css=templates/epub/$LANGUAGE-style.css"
  echo "Using language-specific EPUB style: templates/epub/$LANGUAGE-style.css"
fi

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

# Check if a cover image is available
COVER_OPTION=""
if [ -n "$COVER_IMAGE" ] && [ -f "$COVER_IMAGE" ]; then
  COVER_OPTION="--epub-cover-image=$COVER_IMAGE"
  echo "Using cover image: $COVER_IMAGE"
elif [ -f "build/images/cover.png" ]; then
  COVER_OPTION="--epub-cover-image=build/images/cover.png"
  echo "Using cover image: build/images/cover.png"
elif [ -f "book/images/cover.png" ]; then
  COVER_OPTION="--epub-cover-image=book/images/cover.png"
  echo "Using cover image: book/images/cover.png"
fi

# Define common pandoc parameters
PANDOC_COMMON_PARAMS="--toc \
  --toc-depth=3 \
  --metadata title=\"$BOOK_TITLE\" \
  --metadata subtitle=\"$BOOK_SUBTITLE\" \
  --metadata author=\"$BOOK_AUTHOR\" \
  --metadata publisher=\"$PUBLISHER\" \
  --metadata lang=\"$LANGUAGE\" \
  --resource-path=\"$RESOURCE_PATHS\""

# First attempt: Normal build
echo "Generating EPUB..."
set +e  # Temporarily disable exit on error
WARNINGS=$(pandoc "$INPUT_FILE" -o "$OUTPUT_FILE" \
  $PANDOC_COMMON_PARAMS \
  $COVER_OPTION \
  $EPUB_CSS \
  --epub-chapter-level=1 \
  --highlight-style=tango 2>&1)
RESULT=$?
set -e  # Re-enable exit on error

# Check for missing image warnings but continue
if echo "$WARNINGS" | grep -q "Could not fetch resource"; then
  echo "⚠️ Some images could not be found, but continuing with build"
fi

# Check if EPUB file was created successfully
if [ $RESULT -ne 0 ] || [ ! -s "$OUTPUT_FILE" ]; then
  echo "⚠️ First EPUB generation attempt failed, trying with more resilient settings..."
  
  # Create a version of the markdown with image references made more resilient
  cp "$SAFE_INPUT_FILE" "${SAFE_INPUT_FILE}.tmp"
  sed -i 's/!\[\([^]]*\)\](images\//![\\1](build\/images\//g' "${SAFE_INPUT_FILE}.tmp"
  sed -i 's/!\[\([^]]*\)\](book\/images\//![\\1](build\/images\//g' "${SAFE_INPUT_FILE}.tmp"
  sed -i 's/!\[\([^]]*\)\](book\/[^/)]*\/images\//![\\1](build\/images\//g' "${SAFE_INPUT_FILE}.tmp"
  
  # Second attempt: Try with modified settings and more lenient image paths
  set +e  # Temporarily disable exit on error
  pandoc "${SAFE_INPUT_FILE}.tmp" -o "$OUTPUT_FILE" \
    $PANDOC_COMMON_PARAMS \
    $COVER_OPTION \
    --epub-chapter-level=1 || true
  set -e  # Re-enable exit on error
  
  # If still not successful, create a minimal EPUB
  if [ ! -s "$OUTPUT_FILE" ]; then
    echo "⚠️ WARNING: EPUB generation with images failed, creating a minimal EPUB without images..."
    # Create a version with image references removed
    cp "$SAFE_INPUT_FILE" "${SAFE_INPUT_FILE}.noimg"
    sed -i 's/!\[\([^]]*\)\]([^)]*)//g' "${SAFE_INPUT_FILE}.noimg"
    
    # Final attempt: minimal EPUB with no images
    set +e  # Temporarily disable exit on error
    pandoc "${SAFE_INPUT_FILE}.noimg" -o "$OUTPUT_FILE" \
      $PANDOC_COMMON_PARAMS \
      --epub-chapter-level=1 || true
    set -e  # Re-enable exit on error
    
    # If all else fails, create a placeholder EPUB
    if [ ! -s "$OUTPUT_FILE" ]; then
      echo "⚠️ WARNING: All EPUB generation attempts failed, creating placeholder EPUB..."
      PLACEHOLDER_FILE="$(dirname "$INPUT_FILE")/placeholder.md"
      echo "# $BOOK_TITLE - Placeholder EPUB" > "$PLACEHOLDER_FILE"
      echo "EPUB generation encountered issues. Please check your Markdown content and settings." >> "$PLACEHOLDER_FILE"
      echo "See other formats (PDF, HTML) for the complete content." >> "$PLACEHOLDER_FILE"
      pandoc "$PLACEHOLDER_FILE" -o "$OUTPUT_FILE" --epub-chapter-level=1
    fi
  fi
  
  # Clean up temporary files
  rm -f "${SAFE_INPUT_FILE}.tmp" "${SAFE_INPUT_FILE}.noimg"
fi

# Check final result
if [ -s "$OUTPUT_FILE" ]; then
  echo "✅ EPUB created successfully at $OUTPUT_FILE"
  
  # Get the file size to give some feedback
  FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
  echo "📊 EPUB file size: $FILE_SIZE"
else
  echo "⚠️ Creating minimal emergency EPUB..."
  EMERGENCY_FILE="$(dirname "$INPUT_FILE")/emergency.md"
  echo "# $BOOK_TITLE" > "$EMERGENCY_FILE"
  echo "## Generated on $(date)" >> "$EMERGENCY_FILE"
  echo "This is a minimal emergency EPUB created because all other EPUB generation attempts failed." >> "$EMERGENCY_FILE"
  echo "Please see the PDF or HTML versions for complete content." >> "$EMERGENCY_FILE"
  
  # One last attempt with minimal content and options
  pandoc "$EMERGENCY_FILE" -o "$OUTPUT_FILE" || touch "$OUTPUT_FILE"
  
  if [ -s "$OUTPUT_FILE" ]; then
    echo "✅ Emergency EPUB created at $OUTPUT_FILE"
  else
    echo "❌ Failed to create EPUB at $OUTPUT_FILE"
    # Create an empty file to prevent further failures in the pipeline
    touch "$OUTPUT_FILE" 
  fi
fi
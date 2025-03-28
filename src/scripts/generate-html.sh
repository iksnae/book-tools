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

# Check for cover image
COVER_IMAGE=""
COVER_IMAGE_PATH=""

# Check for language-specific cover in book.yaml
if [ -f "$PROJECT_ROOT/book.yaml" ]; then
  # Check for language-specific cover in social.language_covers section
  if grep -q "language_covers:" "$PROJECT_ROOT/book.yaml"; then
    # Look for a specific language entry (indented under language_covers)
    LANG_COVER=$(grep -A20 "language_covers:" "$PROJECT_ROOT/book.yaml" | grep -E "^[[:space:]]+$LANGUAGE:" | sed "s/.*$LANGUAGE:[[:space:]]*//g" | sed 's/"//g' | sed "s/'//g" | head -1)
    
    if [ -n "$LANG_COVER" ]; then
      # Convert relative path to absolute
      if [[ "$LANG_COVER" != /* ]] && [[ "$LANG_COVER" != http* ]]; then
        LANG_COVER="$PROJECT_ROOT/$LANG_COVER"
      fi
      
      # Check if the file exists
      if [ -f "$LANG_COVER" ]; then
        COVER_IMAGE_PATH="$LANG_COVER"
        
        # Format for Open Graph
        if [[ "$LANG_COVER" != http* ]]; then
          COVER_IMAGE="--metadata=cover-image:file://$LANG_COVER"
        else
          COVER_IMAGE="--metadata=cover-image:$LANG_COVER"
        fi
        
        echo "Found language-specific cover image in book.yaml: $LANG_COVER"
      fi
    fi
  fi
fi

# If no language-specific cover was found in book.yaml, check the filesystem
if [ -z "$COVER_IMAGE" ]; then
  # Check for cover image in different possible locations
  possible_cover_locations=(
    # Language-specific covers (highest priority)
    "$PROJECT_ROOT/book/$LANGUAGE/images/cover.png"
    "$PROJECT_ROOT/book/$LANGUAGE/images/cover.jpg"
    "$PROJECT_ROOT/$RESOURCES_DIR/$LANGUAGE/images/cover.png"
    "$PROJECT_ROOT/$RESOURCES_DIR/$LANGUAGE/images/cover.jpg"
    # General covers (fallback)
    "$PROJECT_ROOT/book/images/cover.png"
    "$PROJECT_ROOT/book/images/cover.jpg"
    "$PROJECT_ROOT/$RESOURCES_DIR/images/cover.png"
    "$PROJECT_ROOT/$RESOURCES_DIR/images/cover.jpg"
  )
  
  for img_path in "${possible_cover_locations[@]}"; do
    if [ -f "$img_path" ]; then
      COVER_IMAGE_PATH="$img_path"
      
      # For Open Graph, we need to use "file://" prefix for local files
      # This will be embedded properly in the HTML
      if [[ "$img_path" != http* ]]; then
        COVER_IMAGE="--metadata=cover-image:file://$img_path"
      else
        COVER_IMAGE="--metadata=cover-image:$img_path"
      fi
      
      echo "Found cover image: $img_path"
      break
    fi
  done
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

# Add cover image metadata if found
if [ -n "$COVER_IMAGE" ]; then
  HTML_METADATA+=("$COVER_IMAGE")
  
  # Also add description metadata if not provided
  if ! grep -q "description-meta" <<< "${HTML_METADATA[*]}"; then
    HTML_METADATA+=("--metadata=description-meta:$BOOK_TITLE - $BOOK_SUBTITLE")
  fi
fi

# Extract social media metadata from book.yaml if it exists
if [ -f "$PROJECT_ROOT/book.yaml" ]; then
  # Check for description in metadata or social sections
  if ! grep -q "description-meta" <<< "${HTML_METADATA[*]}"; then
    DESCRIPTION=$(grep -A1 "description:" "$PROJECT_ROOT/book.yaml" | tail -n 1 | sed 's/^[[:space:]]*//' | sed 's/"//g')
    if [ -n "$DESCRIPTION" ]; then
      HTML_METADATA+=("--metadata=description-meta:$DESCRIPTION")
    fi
  fi
  
  # Check for social media specific metadata
  if grep -q "social:" "$PROJECT_ROOT/book.yaml"; then
    # Twitter handle
    TWITTER=$(grep -A10 "social:" "$PROJECT_ROOT/book.yaml" | grep "twitter_handle:" | sed 's/.*twitter_handle:[[:space:]]*//g' | sed 's/"//g')
    if [ -n "$TWITTER" ]; then
      HTML_METADATA+=("--metadata=twitter-handle:$TWITTER")
    fi
    
    # Site name
    SITE_NAME=$(grep -A10 "social:" "$PROJECT_ROOT/book.yaml" | grep "site_name:" | sed 's/.*site_name:[[:space:]]*//g' | sed 's/"//g')
    if [ -n "$SITE_NAME" ]; then
      HTML_METADATA+=("--metadata=site-name:$SITE_NAME")
    fi
  fi

  # Try to extract a base URL from the book.yaml file
  BASE_URL=$(grep -A10 "html:" "$PROJECT_ROOT/book.yaml" | grep "base_url:" | sed 's/.*base_url:[[:space:]]*//g' | sed 's/"//g' | sed "s/'//g" | head -1)
  
  if [ -n "$BASE_URL" ]; then
    # Remove trailing slash if present
    BASE_URL=${BASE_URL%/}
    
    # Create canonical URL
    OUTPUT_FILE_NAME=$(basename "$OUTPUT_FILE")
    CANONICAL_URL="$BASE_URL/$LANGUAGE/$OUTPUT_FILE_NAME"
    
    HTML_METADATA+=("--metadata=canonical-url:$CANONICAL_URL")
    echo "Added canonical URL: $CANONICAL_URL"

    # Add alternate language links if multiple languages are available
    if [ -f "$PROJECT_ROOT/book.yaml" ] && [ -n "$BASE_URL" ]; then
      # Get all languages from book.yaml
      LANGUAGES=$(grep -A10 "languages:" "$PROJECT_ROOT/book.yaml" | grep -E "^[[:space:]]*-" | sed 's/[[:space:]]*-[[:space:]]*//g' | sed 's/"//g' | sed "s/'//g")
      
      if [ -n "$LANGUAGES" ]; then
        # For each language, add an alternate link
        for lang in $LANGUAGES; do
          # Skip current language
          if [ "$lang" != "$LANGUAGE" ]; then
            OUTPUT_FILE_NAME=$(basename "$OUTPUT_FILE")
            ALT_URL="$BASE_URL/$lang/$OUTPUT_FILE_NAME"
            HTML_METADATA+=("--metadata=alternate-$lang:$ALT_URL")
            echo "Added alternate language link for $lang: $ALT_URL"
          fi
        done
      fi
    fi
  fi
fi

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
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

# Check for cover image (look in multiple locations)
COVER_IMAGE=""
COVER_PATHS=(
    "$PROJECT_ROOT/$RESOURCES_DIR/images/cover.jpg"
    "$PROJECT_ROOT/$RESOURCES_DIR/images/cover.png"
    "$PROJECT_ROOT/art/cover.png"
    "$PROJECT_ROOT/art/cover.jpg"
    "$PROJECT_ROOT/book/images/cover.png"
    "$PROJECT_ROOT/book/images/cover.jpg"
    "$PROJECT_ROOT/book/$LANGUAGE/images/cover.png"
    "$PROJECT_ROOT/book/$LANGUAGE/images/cover.jpg"
    "$PROJECT_ROOT/build/images/cover.png"
    "$PROJECT_ROOT/build/images/cover.jpg"
    "$PROJECT_ROOT/build/$LANGUAGE/images/cover.png"
    "$PROJECT_ROOT/build/$LANGUAGE/images/cover.jpg"
)

for cover_path in "${COVER_PATHS[@]}"; do
    if [ -f "$cover_path" ]; then
        COVER_IMAGE="--epub-cover-image=$cover_path"
        echo "Found cover image: $cover_path"
        break
    fi
done

# Create extract media directory for ensuring images are included
MEDIA_DIR=$(dirname "$OUTPUT_FILE")/media
mkdir -p "$MEDIA_DIR"

# Enhanced implementation for image copying to ensure all images are found
echo "Ensuring all images are available for EPUB..."

# Find all image references in the markdown
REFERENCES=$(grep -o -E '!\[.*?\]\((.*?)\)' "$INPUT_FILE" | sed -E 's/!\[.*?\]\((.*?)\)/\1/g' | sort -u)

# Copy all referenced images to the media directory to ensure they're included
echo "Referenced images:"
for img_ref in $REFERENCES; do
    # Get the basename of the image
    img_name=$(basename "$img_ref")
    echo "- $img_name (from reference: $img_ref)"
    
    # Search for the image in various possible locations
    found=0
    
    # List of potential image locations, from most specific to most general
    img_locations=(
        "$(dirname "$INPUT_FILE")/$img_ref"
        "$PROJECT_ROOT/book/$LANGUAGE/chapter-*/images/$img_name"
        "$PROJECT_ROOT/book/$LANGUAGE/images/$img_name"
        "$PROJECT_ROOT/book/images/$img_name"
        "$PROJECT_ROOT/art/$img_name"
        "$PROJECT_ROOT/build/images/$img_name"
        "$PROJECT_ROOT/build/$LANGUAGE/images/$img_name"
        "$PROJECT_ROOT/$RESOURCES_DIR/images/$img_name"
    )
    
    for img_path in "${img_locations[@]}"; do
        # Use globbing to expand wildcards if present
        for resolved_path in $img_path; do
            if [ -f "$resolved_path" ]; then
                echo "  Found at: $resolved_path"
                # Create the directory structure in media dir
                mkdir -p "$MEDIA_DIR/$(dirname "$img_ref")"
                # Copy the image to the media directory
                cp "$resolved_path" "$MEDIA_DIR/$img_ref"
                found=1
                break
            fi
        done
        [ $found -eq 1 ] && break
    done
    
    if [ $found -eq 0 ]; then
        echo "  ⚠️ Warning: Image $img_ref not found in any search location"
    fi
done

# Define all image search paths
IMAGE_PATHS=(
    "$PROJECT_ROOT/$RESOURCES_DIR/images"
    "$PROJECT_ROOT/book/images"
    "$PROJECT_ROOT/book/$LANGUAGE/images"
    "$PROJECT_ROOT/build/images"
    "$PROJECT_ROOT/build/$LANGUAGE/images"
    "$PROJECT_ROOT/art"
    "$MEDIA_DIR"
    "$(dirname "$INPUT_FILE")"
)

# Add all chapter image directories to search path
for chapter_dir in "$PROJECT_ROOT/book/$LANGUAGE/chapter-"*/; do
    if [ -d "$chapter_dir/images" ]; then
        IMAGE_PATHS+=("$chapter_dir/images")
    fi
done

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

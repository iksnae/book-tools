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

# Also create specific "images" directories in the media folder to match markdown references
mkdir -p "$MEDIA_DIR/images"

# Create a working directory for image processing
WORKING_DIR=$(dirname "$OUTPUT_FILE")/working
mkdir -p "$WORKING_DIR"

# Make a temporary copy of the input file that we can modify
TMP_INPUT_FILE="$WORKING_DIR/input.md"
cp "$INPUT_FILE" "$TMP_INPUT_FILE"

# Function to copy an image to all possible reference locations
copy_image_to_all_paths() {
    local img_file="$1"
    local img_name=$(basename "$img_file")
    
    # Copy to all possible reference locations to ensure it's found
    echo "Copying $img_name to multiple reference locations"
    cp "$img_file" "$MEDIA_DIR/images/$img_name"
    cp "$img_file" "$MEDIA_DIR/$img_name"
    
    # For references like ./images/file.jpg
    mkdir -p "$MEDIA_DIR/./images"
    cp "$img_file" "$MEDIA_DIR/./images/$img_name"
}

# Find all image files from source directories and copy them
echo "Copying all image files from source directories to EPUB media directory..."

# List of potential image source directories (from most specific to most general)
IMAGE_SOURCE_DIRS=(
    "$PROJECT_ROOT/book/$LANGUAGE/chapter-*/images"
    "$PROJECT_ROOT/book/$LANGUAGE/images"
    "$PROJECT_ROOT/book/images"
    "$PROJECT_ROOT/art"
    "$PROJECT_ROOT/build/images"
    "$PROJECT_ROOT/build/$LANGUAGE/images"
    "$PROJECT_ROOT/$RESOURCES_DIR/images"
)

# Copy all images from source directories to the media directory
for src_pattern in "${IMAGE_SOURCE_DIRS[@]}"; do
    for src_dir in $src_pattern; do
        if [ -d "$src_dir" ]; then
            echo "Copying images from $src_dir"
            for img_file in "$src_dir"/*; do
                if [ -f "$img_file" ] && [[ "$img_file" =~ \.(jpg|jpeg|png|gif|svg)$ ]]; then
                    copy_image_to_all_paths "$img_file"
                fi
            done
        fi
    done
done

# Find all image references in the markdown
echo "Processing image references in markdown..."
IMAGE_REFS=$(grep -o -E '!\[.*?\]\((.*?)\)' "$INPUT_FILE" | sed -E 's/!\[.*?\]\((.*?)\)/\1/g' | sort -u)

# Process each image reference
for img_ref in $IMAGE_REFS; do
    # Get the basename of the image
    img_name=$(basename "$img_ref")
    echo "Processing image reference: $img_ref (basename: $img_name)"
    
    # Create directory structure for the reference if it doesn't include just the filename
    if [ "$img_ref" != "$img_name" ]; then
        ref_dir=$(dirname "$img_ref")
        mkdir -p "$MEDIA_DIR/$ref_dir"
    fi
    
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
        "$PROJECT_ROOT/build/en/images/$img_name"
        "$PROJECT_ROOT/build/es/images/$img_name"
    )
    
    for img_path in "${img_locations[@]}"; do
        # Use globbing to expand wildcards if present
        for resolved_path in $img_path; do
            if [ -f "$resolved_path" ]; then
                echo "  Found at: $resolved_path"
                
                # Copy to exact reference path
                if [ "$img_ref" != "$img_name" ]; then
                    cp "$resolved_path" "$MEDIA_DIR/$img_ref"
                    echo "  Copied to: $MEDIA_DIR/$img_ref"
                fi
                
                # Also copy to the base names directory for simple references
                cp "$resolved_path" "$MEDIA_DIR/images/$img_name"
                echo "  Copied to: $MEDIA_DIR/images/$img_name"
                
                # For path-relative references
                img_rel_path="./images/$img_name"
                mkdir -p "$MEDIA_DIR/$(dirname "$img_rel_path")"
                cp "$resolved_path" "$MEDIA_DIR/$img_rel_path"
                echo "  Copied to: $MEDIA_DIR/$img_rel_path"
                
                # For chapter-level references
                chapter_dir="$(dirname "$INPUT_FILE")/images"
                mkdir -p "$chapter_dir"
                cp "$resolved_path" "$chapter_dir/$img_name"
                echo "  Copied to: $chapter_dir/$img_name"
                
                found=1
                break
            fi
        done
        [ $found -eq 1 ] && break
    done
    
    if [ $found -eq 0 ]; then
        echo "  ⚠️ Warning: Image $img_ref not found, creating placeholder"
        # Create a placeholder SVG for missing images
        cat > "$MEDIA_DIR/images/$img_name" << 'EOF'
<svg width="800" height="400" xmlns="http://www.w3.org/2000/svg">
    <rect width="100%" height="100%" fill="#f5f5f5"/>
    <text x="50%" y="45%" font-family="Arial" font-size="24" fill="#666" text-anchor="middle">Image Placeholder</text>
    <text x="50%" y="55%" font-family="Arial" font-size="18" fill="#999" text-anchor="middle">Missing: IMAGE_NAME</text>
</svg>
EOF
        # Replace the placeholder with the actual image name
        sed -i "s/IMAGE_NAME/$img_name/g" "$MEDIA_DIR/images/$img_name"
        
        # Also create for the exact reference path
        if [ "$img_ref" != "$img_name" ]; then
            mkdir -p "$MEDIA_DIR/$(dirname "$img_ref")"
            cp "$MEDIA_DIR/images/$img_name" "$MEDIA_DIR/$img_ref"
        fi
        
        # For path-relative references
        img_rel_path="./images/$img_name"
        mkdir -p "$MEDIA_DIR/$(dirname "$img_rel_path")"
        cp "$MEDIA_DIR/images/$img_name" "$MEDIA_DIR/$img_rel_path"
    fi
done

# Define all image search paths for Pandoc
IMAGE_PATHS=(
    # Current directories
    "$(dirname "$INPUT_FILE")"
    "$(dirname "$INPUT_FILE")/images"
    # Media directory with extracted images
    "$MEDIA_DIR"
    "$MEDIA_DIR/images"
    # Project directories
    "$PROJECT_ROOT/$RESOURCES_DIR/images"
    "$PROJECT_ROOT/book/images"
    "$PROJECT_ROOT/book/$LANGUAGE/images"
    "$PROJECT_ROOT/build/images"
    "$PROJECT_ROOT/build/$LANGUAGE/images"
    "$PROJECT_ROOT/art"
    # Absolute paths to chapter images
    "$PROJECT_ROOT/book/$LANGUAGE/chapter-*/images"
    # Relative paths
    "."
    "./images"
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
echo "Media directory: $MEDIA_DIR"
echo "Author: $AUTHOR"
echo "Publisher: $PUBLISHER"

# Generate EPUB with the prepared environment
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
    --resource-path="$RESOURCE_PATH" \
    --extract-media="$MEDIA_DIR" \
    $EPUB_TEMPLATE \
    $EPUB_STYLE \
    $COVER_IMAGE

# Check if EPUB was generated successfully
if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    echo "✅ EPUB generated successfully: $OUTPUT_FILE"
    # Get file size
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "File size: $FILE_SIZE"
    
    # Optionally, check the EPUB file for image inclusion
    if command -v zipinfo &> /dev/null; then
        echo "📊 EPUB content summary:"
        zipinfo -1 "$OUTPUT_FILE" | grep -i "\.\(jpg\|png\|svg\|gif\)" | wc -l | xargs echo "  Image files in EPUB:"
    fi
else
    echo "❌ Error: Something went wrong during EPUB generation."
    exit 1
fi

# Clean up working directory
if [ -d "$WORKING_DIR" ]; then
    rm -rf "$WORKING_DIR"
fi

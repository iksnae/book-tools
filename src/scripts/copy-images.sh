#!/bin/bash

# copy-images.sh - Handles copying of images for the book build process

set -e  # Exit on error

if [ "$VERBOSE" = true ]; then
    echo "🖼️ Setting up image directories..."
fi

# Create image directories
mkdir -p build/images
mkdir -p build/en/images
mkdir -p build/es/images 2>/dev/null || true

# Function to copy images with logging
copy_images() {
    local src="$1"
    local dest="$2"
    local type="$3"
    
    if [ -d "$src" ]; then
        if [ "$VERBOSE" = true ]; then
            echo "📸 Copying $type images from $src to $dest"
        fi
        cp -r "$src"/* "$dest/" 2>/dev/null || true
        
        if [ "$VERBOSE" = true ]; then
            local count=$(find "$dest" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" \) | wc -l)
            echo "✅ Found $count images in $dest"
        fi
    elif [ "$VERBOSE" = true ]; then
        echo "⚠️ No $type images found in $src"
    fi
}

# Copy common images from various locations
copy_images "art" "build/images" "artwork"
copy_images "book/images" "build/images" "common"
copy_images "images" "build/images" "root"

# Copy language-specific images
copy_images "book/en/images" "build/en/images" "English"
copy_images "book/es/images" "build/es/images" "Spanish"

# Handle cover image specially
for cover in "cover.jpg" "cover.png"; do
    for dir in "." "art" "book/images" "images"; do
        if [ -f "$dir/$cover" ]; then
            if [ "$VERBOSE" = true ]; then
                echo "📔 Found cover image: $dir/$cover"
            fi
            cp "$dir/$cover" "build/images/cover.jpg"
            break
        fi
    done
done

# Ensure all language directories have access to common images
for lang in en es; do
    if [ -d "build/$lang" ]; then
        if [ "$VERBOSE" = true ]; then
            echo "🔄 Linking common images to $lang directory"
        fi
        cp -r build/images/* "build/$lang/images/" 2>/dev/null || true
    fi
done

if [ "$VERBOSE" = true ]; then
    echo "✅ Image setup completed"
    echo "📊 Image counts by directory:"
    for dir in build/images build/en/images build/es/images; do
        if [ -d "$dir" ]; then
            count=$(find "$dir" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" \) | wc -l)
            echo "  - $dir: $count images"
        fi
    done
fi
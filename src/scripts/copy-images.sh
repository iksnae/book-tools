#!/bin/bash

# copy-images.sh - Handles image copying from multiple source directories

set -e  # Exit on error

if [ "$VERBOSE" = true ]; then
    echo "🖼️ Setting up images..."
fi

# Create main images directory
mkdir -p "build/images"

# Create placeholder image in the common images directory first
cat > "build/images/placeholder.svg" << 'EOF'
<svg width="800" height="400" xmlns="http://www.w3.org/2000/svg">
    <rect width="100%" height="100%" fill="#f0f0f0"/>
    <text x="50%" y="45%" font-family="Arial" font-size="24" fill="#666" text-anchor="middle">Placeholder Image</text>
    <text x="50%" y="55%" font-family="Arial" font-size="18" fill="#999" text-anchor="middle">Coming Soon</text>
</svg>
EOF

# Function to copy images from a source directory
copy_images() {
    local src="$1"
    local dest="$2"
    if [ -d "$src" ]; then
        if [ "$VERBOSE" = true ]; then
            echo "📂 Copying images from $src to $dest"
        fi
        # Create destination if it doesn't exist
        mkdir -p "$dest"
        # Copy all image files
        find "$src" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.svg" -o -name "*.gif" \) -exec cp {} "$dest/" \; 2>/dev/null || {
            if [ "$VERBOSE" = true ]; then
                echo "⚠️ Warning: Some files from $src could not be copied"
            fi
        }
    elif [ "$VERBOSE" = true ]; then
        echo "⚠️ Warning: Source directory $src not found"
    fi
}

# Function to find all referenced images in markdown files
find_referenced_images() {
    local lang="$1"
    if [ -d "book/$lang" ]; then
        # Find all markdown files and grep for image references
        find "book/$lang" -type f -name "*.md" -exec grep -ho "!\[.*\](\([^)]*\))" {} \; | sed 's/!\[.*\](\([^)]*\))/\1/g' | sort -u
    fi
}

# Copy common images first
copy_images "art" "build/images"
copy_images "book/images" "build/images"
copy_images "resources/images" "build/images"

# Handle language-specific images
for lang_dir in book/*/; do
    lang=$(basename "$lang_dir")
    # Skip if not a language directory (e.g., images/)
    if [ "$lang" = "images" ] || [ ! -d "$lang_dir" ]; then
        continue
    fi

    # Create language-specific build directory
    mkdir -p "build/$lang/images"

    # Copy language-specific images
    copy_images "book/$lang/images" "build/$lang/images"

    # Create symlinks for common images
    if [ -d "build/images" ]; then
        for img in build/images/*; do
            if [ -f "$img" ]; then
                base=$(basename "$img")
                if [ ! -e "build/$lang/images/$base" ]; then
                    ln -sf "../../images/$base" "build/$lang/images/$base" 2>/dev/null || {
                        if [ "$VERBOSE" = true ]; then
                            echo "⚠️ Warning: Could not create symlink for $base in $lang"
                        fi
                    }
                fi
            fi
        done
    fi

    # Create symlinks for missing referenced images
    while IFS= read -r img_path; do
        # Skip if empty
        [ -z "$img_path" ] && continue
        
        # Get the base filename
        base=$(basename "$img_path")
        
        # If image doesn't exist in either location, create symlink to placeholder
        if [ ! -f "build/$lang/images/$base" ] && [ ! -f "build/images/$base" ]; then
            if [ "$VERBOSE" = true ]; then
                echo "⚠️ Missing image: $img_path, using placeholder"
            fi
            ln -sf "../../images/placeholder.svg" "build/$lang/images/$base" 2>/dev/null || {
                if [ "$VERBOSE" = true ]; then
                    echo "⚠️ Warning: Could not create placeholder symlink for $base"
                fi
            }
        fi
    done < <(find_referenced_images "$lang")
done

# Handle cover image
for cover in book/images/cover.* book/*/images/cover.* resources/images/cover.*; do
    if [ -f "$cover" ]; then
        cp "$cover" "build/images/" || {
            if [ "$VERBOSE" = true ]; then
                echo "⚠️ Warning: Could not copy cover image: $cover"
            fi
        }
        break
    fi
done

# If no cover image found, create a placeholder
if ! ls build/images/cover.* >/dev/null 2>&1; then
    if [ "$VERBOSE" = true ]; then
        echo "⚠️ No cover image found, creating placeholder"
    fi
    cp "build/images/placeholder.svg" "build/images/cover.jpg" || {
        if [ "$VERBOSE" = true ]; then
            echo "⚠️ Warning: Could not create cover image placeholder"
        fi
    }
fi

# Count images in each directory
if [ "$VERBOSE" = true ]; then
    echo "📊 Image setup summary:"
    echo "Common images: $(find build/images -type f | wc -l)"
    for lang_dir in book/*/; do
        lang=$(basename "$lang_dir")
        if [ "$lang" != "images" ] && [ -d "build/$lang/images" ]; then
            echo "$lang images: $(find "build/$lang/images" -type f | wc -l)"
        fi
    done
fi
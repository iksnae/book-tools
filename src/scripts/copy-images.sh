#!/bin/bash

# copy-images.sh - Handles image copying from multiple source directories

set -e  # Exit on error

if [ "$VERBOSE" = true ]; then
    echo "🖼️ Setting up images..."
fi

# Create image directories
mkdir -p "build/images"
mkdir -p "build/en/images"
mkdir -p "build/es/images"

# Function to copy images from a source directory
copy_images() {
    local src="$1"
    local dest="$2"
    if [ -d "$src" ]; then
        if [ "$VERBOSE" = true ]; then
            echo "📂 Copying images from $src to $dest"
        fi
        cp -r "$src"/* "$dest/" 2>/dev/null || {
            if [ "$VERBOSE" = true ]; then
                echo "⚠️ Warning: Some files from $src could not be copied"
            fi
        }
    elif [ "$VERBOSE" = true ]; then
        echo "⚠️ Warning: Source directory $src not found"
    fi
}

# Copy images from all possible locations
copy_images "art" "build/images"
copy_images "book/images" "build/images"
copy_images "book/en/images" "build/en/images"
copy_images "book/es/images" "build/es/images"

# Link common images to language directories if they don't exist
for lang in en es; do
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
done

# Create placeholder for missing images
cat > "build/images/placeholder.svg" << 'EOF'
<svg width="800" height="400" xmlns="http://www.w3.org/2000/svg">
    <rect width="100%" height="100%" fill="#f0f0f0"/>
    <text x="50%" y="45%" font-family="Arial" font-size="24" fill="#666" text-anchor="middle">Placeholder Image</text>
    <text x="50%" y="55%" font-family="Arial" font-size="18" fill="#999" text-anchor="middle">Coming Soon</text>
</svg>
EOF

# Count images in each directory
if [ "$VERBOSE" = true ]; then
    echo "📊 Image setup summary:"
    echo "Common images: $(find build/images -type f | wc -l)"
    echo "English images: $(find build/en/images -type f | wc -l)"
    echo "Spanish images: $(find build/es/images -type f | wc -l)"
fi
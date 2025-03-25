#!/bin/bash

# build-language.sh - Builds book content for a specific language

set -e  # Exit on error

# Get the language from the first argument
LANG="$1"
if [ -z "$LANG" ]; then
    echo "❌ Error: Language parameter is required"
    exit 1
fi

if [ "$VERBOSE" = true ]; then
    echo "🔨 Building content for language: $LANG"
fi

# Ensure the language directory exists
if [ ! -d "book/$LANG" ]; then
    echo "❌ Error: Language directory book/$LANG does not exist"
    exit 1
fi

# Create build directory for this language
mkdir -p "build/$LANG"
mkdir -p "build/$LANG/images"

# Copy images from various locations
if [ "$VERBOSE" = true ]; then
    echo "🖼️ Setting up images..."
fi

# Copy placeholder image for missing images if it exists
if [ -f "book/$LANG/images/placeholder.svg" ]; then
    cp "book/$LANG/images/placeholder.svg" "build/$LANG/images/" || {
        echo "⚠️ Warning: Could not copy placeholder image"
    }
fi

# Copy all available images
find "book/$LANG" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.svg" \) -exec cp {} "build/$LANG/images/" \; || {
    echo "⚠️ Warning: Some images could not be copied"
}

# Combine markdown files using combine-markdown.sh
if [ "$VERBOSE" = true ]; then
    echo "📝 Combining markdown files..."
fi

# Get book metadata for the combined file
BOOK_YAML="book.yaml"
if [ -f "$BOOK_YAML" ]; then
    BOOK_TITLE=$(grep "^title:" "$BOOK_YAML" | cut -d ':' -f 2- | sed 's/^[ \t]*//' | tr -d '"')
    BOOK_SUBTITLE=$(grep "^subtitle:" "$BOOK_YAML" | cut -d ':' -f 2- | sed 's/^[ \t]*//' | tr -d '"')
else
    BOOK_TITLE="Book"
    BOOK_SUBTITLE="A Book"
fi

# Combine the markdown files using the dedicated script
# This handles chapter-based directories and creates a single combined markdown file
COMBINED_MD="build/$LANG/combined.md"
SCRIPTS_PATH=$(dirname "$0")
"$SCRIPTS_PATH/combine-markdown.sh" "$LANG" "$COMBINED_MD" "$BOOK_TITLE" "$BOOK_SUBTITLE" "$(pwd)"

# Verify the combined markdown file was created
if [ ! -f "$COMBINED_MD" ]; then
    echo "❌ Error: Failed to create combined markdown file"
    exit 1
fi

if [ "$VERBOSE" = true ]; then
    echo "✅ Created combined markdown file: $COMBINED_MD"
fi

# Build HTML version
if [ "$SKIP_HTML" != true ]; then
    if [ "$VERBOSE" = true ]; then
        echo "🌐 Building HTML version..."
    fi
    pandoc "$COMBINED_MD" \
        --from markdown \
        --to html5 \
        --output "build/$LANG/$BOOK_TITLE-$LANG.html" \
        --standalone \
        --toc \
        --toc-depth=3 \
        --resource-path="build/$LANG/images:build/images:build/$LANG/images" \
        --css=styles/book.css || {
            echo "❌ Error building HTML version"
            exit 1
        }
fi

# Build PDF version
if [ "$SKIP_PDF" != true ]; then
    if [ "$VERBOSE" = true ]; then
        echo "📄 Building PDF version..."
    fi
    pandoc "$COMBINED_MD" \
        --from markdown \
        --to pdf \
        --output "build/$LANG/$BOOK_TITLE-$LANG.pdf" \
        --toc \
        --toc-depth=3 \
        --resource-path="build/$LANG/images:build/images:build/$LANG/images" \
        --pdf-engine=xelatex \
        -V geometry:margin=1in \
        -V documentclass=report \
        -V papersize=letter \
        -V fontsize=11pt || {
            echo "❌ Error building PDF version"
            exit 1
        }
fi

# Build EPUB version
if [ "$SKIP_EPUB" != true ]; then
    if [ "$VERBOSE" = true ]; then
        echo "📱 Building EPUB version..."
    fi

    # Check for cover image
    COVER_ARG=""
    if [ -f "build/images/cover.jpg" ]; then
        COVER_ARG="--epub-cover-image=build/images/cover.jpg"
    elif [ -f "book/images/cover.jpg" ]; then
        cp "book/images/cover.jpg" "build/images/"
        COVER_ARG="--epub-cover-image=build/images/cover.jpg"
    elif [ -f "book/images/cover.png" ]; then
        cp "book/images/cover.png" "build/images/"
        COVER_ARG="--epub-cover-image=build/images/cover.png"
    fi

    pandoc "$COMBINED_MD" \
        --from markdown \
        --to epub \
        --output "build/$LANG/$BOOK_TITLE-$LANG.epub" \
        --toc \
        --toc-depth=3 \
        --resource-path="build/$LANG/images:build/images:build/$LANG/images" \
        $COVER_ARG || {
            echo "❌ Error building EPUB version"
            exit 1
        }
fi

# Build MOBI version if not skipped and calibre is available
if [ "$SKIP_MOBI" != true ] && command -v ebook-convert >/dev/null; then
    if [ "$VERBOSE" = true ]; then
        echo "📱 Building MOBI version..."
    fi
    ebook-convert "build/$LANG/$BOOK_TITLE-$LANG.epub" \
        "build/$LANG/$BOOK_TITLE-$LANG.mobi" || {
            echo "⚠️ Warning: Error building MOBI version"
        }
elif [ "$SKIP_MOBI" != true ]; then
    echo "⚠️ Skipping MOBI: calibre not installed"
fi

# Build DOCX version
if [ "$SKIP_DOCX" != true ]; then
    if [ "$VERBOSE" = true ]; then
        echo "📄 Building DOCX version..."
    fi
    
    # Look for a reference document
    REFERENCE_DOC=""
    if [ -f "templates/docx/reference.docx" ]; then
        REFERENCE_DOC="--reference-doc=templates/docx/reference.docx"
    elif [ -f "resources/templates/docx/reference.docx" ]; then
        REFERENCE_DOC="--reference-doc=resources/templates/docx/reference.docx"
    fi

    # Build DOCX with reference if available
    pandoc "$COMBINED_MD" \
        --from markdown \
        --to docx \
        --output "build/$LANG/$BOOK_TITLE-$LANG.docx" \
        --toc \
        --toc-depth=3 \
        --resource-path="build/$LANG/images:build/images:build/$LANG/images" \
        $REFERENCE_DOC || {
            echo "❌ Error building DOCX version"
            exit 1
        }
fi

if [ "$VERBOSE" = true ]; then
    echo "✅ Build completed for language: $LANG"
    ls -lh "build/$LANG"
fi
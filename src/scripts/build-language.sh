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

# Copy markdown files
if [ "$VERBOSE" = true ]; then
    echo "📝 Copying markdown files..."
fi
cp -r "book/$LANG"/*.md "build/$LANG/" 2>/dev/null || true

# Build HTML version
if [ "$SKIP_HTML" != true ]; then
    if [ "$VERBOSE" = true ]; then
        echo "🌐 Building HTML version..."
    fi
    pandoc "build/$LANG"/*.md \
        --from markdown \
        --to html5 \
        --output "build/$LANG/$BOOK_TITLE-$LANG.html" \
        --standalone \
        --toc \
        --toc-depth=3 \
        --resource-path="build/$LANG:build/images:build/$LANG/images" \
        --css=styles/book.css
fi

# Build PDF version
if [ "$SKIP_PDF" != true ]; then
    if [ "$VERBOSE" = true ]; then
        echo "📄 Building PDF version..."
    fi
    pandoc "build/$LANG"/*.md \
        --from markdown \
        --to pdf \
        --output "build/$LANG/$BOOK_TITLE-$LANG.pdf" \
        --toc \
        --toc-depth=3 \
        --resource-path="build/$LANG:build/images:build/$LANG/images" \
        --pdf-engine=xelatex
fi

# Build EPUB version
if [ "$SKIP_EPUB" != true ]; then
    if [ "$VERBOSE" = true ]; then
        echo "📱 Building EPUB version..."
    fi
    pandoc "build/$LANG"/*.md \
        --from markdown \
        --to epub \
        --output "build/$LANG/$BOOK_TITLE-$LANG.epub" \
        --toc \
        --toc-depth=3 \
        --resource-path="build/$LANG:build/images:build/$LANG/images" \
        --epub-cover-image="build/images/cover.jpg"
fi

# Build MOBI version if not skipped and calibre is available
if [ "$SKIP_MOBI" != true ] && command -v ebook-convert >/dev/null; then
    if [ "$VERBOSE" = true ]; then
        echo "📱 Building MOBI version..."
    fi
    ebook-convert "build/$LANG/$BOOK_TITLE-$LANG.epub" \
        "build/$LANG/$BOOK_TITLE-$LANG.mobi"
elif [ "$SKIP_MOBI" != true ]; then
    echo "⚠️ Skipping MOBI: calibre not installed"
fi

if [ "$VERBOSE" = true ]; then
    echo "✅ Build completed for language: $LANG"
    ls -lh "build/$LANG"
fi
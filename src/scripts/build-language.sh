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

# First check if there are any markdown files
MD_FILES=$(find "book/$LANG" -maxdepth 1 -name "*.md" | wc -l)
if [ "$MD_FILES" -eq 0 ]; then
    echo "❌ Error: No markdown files found in book/$LANG"
    exit 1
fi

# Copy the files
cp "book/$LANG"/*.md "build/$LANG/" || {
    echo "❌ Error copying markdown files"
    exit 1
}

if [ "$VERBOSE" = true ]; then
    echo "✅ Found and copied $MD_FILES markdown files"
    ls -l "build/$LANG"/*.md
fi

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
    pandoc "build/$LANG"/*.md \
        --from markdown \
        --to pdf \
        --output "build/$LANG/$BOOK_TITLE-$LANG.pdf" \
        --toc \
        --toc-depth=3 \
        --resource-path="build/$LANG:build/images:build/$LANG/images" \
        --pdf-engine=xelatex || {
            echo "❌ Error building PDF version"
            exit 1
        }
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
        --epub-cover-image="build/images/cover.jpg" || {
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

if [ "$VERBOSE" = true ]; then
    echo "✅ Build completed for language: $LANG"
    ls -lh "build/$LANG"
fi
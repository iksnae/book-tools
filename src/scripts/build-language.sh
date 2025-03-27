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

# Use PROJECT_ROOT from environment or default to current directory
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"

# Ensure the language directory exists
if [ ! -d "$PROJECT_ROOT/book/$LANG" ]; then
    echo "❌ Error: Language directory $PROJECT_ROOT/book/$LANG does not exist"
    exit 1
fi

# Create build directory for this language
mkdir -p "$PROJECT_ROOT/build/$LANG"
mkdir -p "$PROJECT_ROOT/build/$LANG/images"

# Copy images from various locations
if [ "$VERBOSE" = true ]; then
    echo "🖼️ Setting up images..."
fi

# Define all image search paths
IMAGE_PATHS=(
    "$PROJECT_ROOT/book/images"
    "$PROJECT_ROOT/book/$LANG/images"
    "$PROJECT_ROOT/resources/images"
    "$PROJECT_ROOT/build/images"
    "$PROJECT_ROOT/build/$LANG/images"
)

# Build the resource path string for pandoc
RESOURCE_PATH=$(IFS=:; echo "${IMAGE_PATHS[*]}")

# Combine markdown files using combine-markdown.sh
if [ "$VERBOSE" = true ]; then
    echo "📝 Combining markdown files..."
fi

# Get book metadata for the combined file
BOOK_YAML="$PROJECT_ROOT/book.yaml"
if [ -f "$BOOK_YAML" ]; then
    BOOK_TITLE=$(grep "^title:" "$BOOK_YAML" | cut -d ':' -f 2- | sed 's/^[ \t]*//' | tr -d '"')
    BOOK_SUBTITLE=$(grep "^subtitle:" "$BOOK_YAML" | cut -d ':' -f 2- | sed 's/^[ \t]*//' | tr -d '"')
else
    BOOK_TITLE="Book"
    BOOK_SUBTITLE="A Book"
fi

# Combine the markdown files using the dedicated script
# This handles chapter-based directories and creates a single combined markdown file
COMBINED_MD="$PROJECT_ROOT/build/$LANG/combined.md"
SCRIPTS_PATH=$(dirname "$0")
"$SCRIPTS_PATH/combine-markdown.sh" "$LANG" "$COMBINED_MD" "$BOOK_TITLE" "$BOOK_SUBTITLE" "$PROJECT_ROOT"

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
        --output "$PROJECT_ROOT/build/$LANG/$BOOK_TITLE-$LANG.html" \
        --standalone \
        --toc \
        --toc-depth=3 \
        --resource-path="$RESOURCE_PATH" \
        --css="$PROJECT_ROOT/styles/book.css" || {
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
        --output "$PROJECT_ROOT/build/$LANG/$BOOK_TITLE-$LANG.pdf" \
        --toc \
        --toc-depth=3 \
        --resource-path="$RESOURCE_PATH" \
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

    # Use the dedicated EPUB generation script for better image handling
    SCRIPTS_PATH=$(dirname "$0")
    "$SCRIPTS_PATH/generate-epub.sh" \
        "$LANG" \
        "$COMBINED_MD" \
        "$PROJECT_ROOT/build/$LANG/$BOOK_TITLE-$LANG.epub" \
        "$BOOK_TITLE" \
        "$BOOK_SUBTITLE" \
        "resources" \
        "$PROJECT_ROOT"

    # Check if EPUB was generated with correct size
    if [ -f "$PROJECT_ROOT/build/$LANG/$BOOK_TITLE-$LANG.epub" ]; then
        EPUB_SIZE=$(du -h "$PROJECT_ROOT/build/$LANG/$BOOK_TITLE-$LANG.epub" | cut -f1)
        if [ "$VERBOSE" = true ]; then
            echo "✅ EPUB generated successfully: build/$LANG/$BOOK_TITLE-$LANG.epub (Size: $EPUB_SIZE)"
        fi
    fi
fi

# Build MOBI version if not skipped and calibre is available
if [ "$SKIP_MOBI" != true ] && command -v ebook-convert >/dev/null; then
    if [ "$VERBOSE" = true ]; then
        echo "📱 Building MOBI version..."
    fi
    ebook-convert "$PROJECT_ROOT/build/$LANG/$BOOK_TITLE-$LANG.epub" \
        "$PROJECT_ROOT/build/$LANG/$BOOK_TITLE-$LANG.mobi" || {
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
        --output "$PROJECT_ROOT/build/$LANG/$BOOK_TITLE-$LANG.docx" \
        --toc \
        --toc-depth=3 \
        --resource-path="$RESOURCE_PATH" \
        $REFERENCE_DOC || {
            echo "❌ Error building DOCX version"
            exit 1
        }
fi

if [ "$VERBOSE" = true ]; then
    echo "✅ Build completed for language: $LANG"
    ls -lh "$PROJECT_ROOT/build/$LANG"
fi
#!/bin/bash

# build-language.sh - Builds book formats for a specific language
# Usage: build-language.sh [language] [config_file] [project_root] [skip_pdf] [skip_epub] [skip_html] [skip_mobi] [skip_docx]

set -e  # Exit on error

# Get arguments
LANGUAGE=${1:-en}
CONFIG_FILE=${2:-$(pwd)/book.yaml}
PROJECT_ROOT=${3:-$(pwd)}
SKIP_PDF=${4:-false}
SKIP_EPUB=${5:-false}
SKIP_HTML=${6:-false}
SKIP_MOBI=${7:-false}
SKIP_DOCX=${8:-false}

SCRIPTS_DIR="$(dirname "$(realpath "$0")")"
BUILD_DIR="$PROJECT_ROOT/build/$LANGUAGE"
RESOURCES_DIR="$PROJECT_ROOT/resources"

echo "🔧 Building $LANGUAGE version of the book..."
echo "   Using config file: $CONFIG_FILE"
echo "   Project root: $PROJECT_ROOT"
echo "   Build directory: $BUILD_DIR"

# Load book metadata from config
BOOK_TITLE=$(grep "title:" "$CONFIG_FILE" | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' || echo "Untitled Book")
BOOK_SUBTITLE=$(grep "subtitle:" "$CONFIG_FILE" | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' || echo "")
AUTHOR=$(grep "author:" "$CONFIG_FILE" | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' || echo "Anonymous")
FILE_PREFIX=$(grep -E "^file_prefix:|^filePrefix:" "$CONFIG_FILE" | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | tr -d '"' || echo "book")

# If file_prefix is empty, use "book"
if [ -z "$FILE_PREFIX" ]; then
  FILE_PREFIX="book"
fi

# Remove quotes from metadata if present
BOOK_TITLE=$(echo "$BOOK_TITLE" | sed 's/^"//;s/"$//')
BOOK_SUBTITLE=$(echo "$BOOK_SUBTITLE" | sed 's/^"//;s/"$//')
AUTHOR=$(echo "$AUTHOR" | sed 's/^"//;s/"$//')

echo "📚 Book Title: $BOOK_TITLE"
if [ -n "$BOOK_SUBTITLE" ]; then
  echo "📖 Book Subtitle: $BOOK_SUBTITLE"
fi
echo "✍️ Author: $AUTHOR"
echo "📄 File Prefix: $FILE_PREFIX"

# Create build directory
mkdir -p "$BUILD_DIR"

# 1. Combine markdown files
echo "📝 Combining markdown files..."
MARKDOWN_OUTPUT="$BUILD_DIR/book.md"
"$SCRIPTS_DIR/combine-markdown.sh" "$LANGUAGE" "$MARKDOWN_OUTPUT" "$BOOK_TITLE" "$BOOK_SUBTITLE" "$PROJECT_ROOT"

if [ ! -f "$MARKDOWN_OUTPUT" ]; then
  echo "❌ Error: Combined markdown file was not created."
  exit 1
fi

# 2. Generate PDF (if pandoc is available)
if command -v pandoc &> /dev/null && [ "$SKIP_PDF" != "true" ]; then
  echo "📄 Generating PDF..."
  PDF_OUTPUT="$BUILD_DIR/$FILE_PREFIX.pdf"
  "$SCRIPTS_DIR/generate-pdf.sh" "$LANGUAGE" "$MARKDOWN_OUTPUT" "$PDF_OUTPUT" "$BOOK_TITLE" "$BOOK_SUBTITLE" "resources" "$PROJECT_ROOT"
  echo "   PDF output: $PDF_OUTPUT"
fi

# 3. Generate HTML (if pandoc is available)
if command -v pandoc &> /dev/null && [ "$SKIP_HTML" != "true" ]; then
  echo "🌐 Generating HTML..."
  HTML_OUTPUT="$BUILD_DIR/$FILE_PREFIX.html"
  "$SCRIPTS_DIR/generate-html.sh" "$LANGUAGE" "$MARKDOWN_OUTPUT" "$HTML_OUTPUT" "$BOOK_TITLE" "$BOOK_SUBTITLE" "resources" "$PROJECT_ROOT"
  echo "   HTML output: $HTML_OUTPUT"
fi

# 4. Generate EPUB
if command -v pandoc &> /dev/null && [ "$SKIP_EPUB" != "true" ]; then
  echo "📱 Generating EPUB..."
  EPUB_OUTPUT="$BUILD_DIR/$FILE_PREFIX.epub"
  "$SCRIPTS_DIR/generate-epub.sh" "$LANGUAGE" "$MARKDOWN_OUTPUT" "$EPUB_OUTPUT" "$BOOK_TITLE" "$BOOK_SUBTITLE" "resources" "$PROJECT_ROOT"
  echo "   EPUB output: $EPUB_OUTPUT"
fi

# 5. Generate MOBI (if kindlegen or ebook-convert is available)
if (command -v kindlegen &> /dev/null || command -v ebook-convert &> /dev/null) && [ "$SKIP_MOBI" != "true" ] && [ "$SKIP_EPUB" != "true" ]; then
  echo "📚 Generating MOBI..."
  MOBI_OUTPUT="$BUILD_DIR/$FILE_PREFIX.mobi"
  "$SCRIPTS_DIR/generate-mobi.sh" "$LANGUAGE" "$EPUB_OUTPUT" "$MOBI_OUTPUT" "$PROJECT_ROOT"
  echo "   MOBI output: $MOBI_OUTPUT"
fi

# 6. Generate DOCX (if pandoc is available)
if command -v pandoc &> /dev/null && [ "$SKIP_DOCX" != "true" ]; then
  echo "📝 Generating DOCX..."
  DOCX_OUTPUT="$BUILD_DIR/$FILE_PREFIX.docx"
  "$SCRIPTS_DIR/generate-docx.sh" "$LANGUAGE" "$MARKDOWN_OUTPUT" "$DOCX_OUTPUT" "$BOOK_TITLE" "$BOOK_SUBTITLE" "resources" "$PROJECT_ROOT"
  echo "   DOCX output: $DOCX_OUTPUT"
fi

# Print success message with generated files
echo "✅ Build completed for $LANGUAGE version."
echo "📚 Generated files:"
find "$BUILD_DIR" -type f -not -name "*.md" -not -name "*.tmp" | sort

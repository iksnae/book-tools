#!/bin/bash

# build-language.sh - Builds book formats for a specific language
# Usage: build-language.sh [language] [config_file]

set -e  # Exit on error

# Get arguments
LANGUAGE=${1:-en}
CONFIG_FILE=${2:-../book.yaml}
SCRIPTS_DIR="$(dirname "$0")"
BUILD_DIR="../build/$LANGUAGE"

echo "🔧 Building $LANGUAGE version of the book..."

# Load book metadata from config
if [ -f "$CONFIG_FILE" ]; then
  BOOK_TITLE=$(grep "^title:" "$CONFIG_FILE" | cut -d ':' -f 2- | sed 's/^[ \t]*//')
  BOOK_SUBTITLE=$(grep "^subtitle:" "$CONFIG_FILE" | cut -d ':' -f 2- | sed 's/^[ \t]*//')
  AUTHOR=$(grep "^author:" "$CONFIG_FILE" | cut -d ':' -f 2- | sed 's/^[ \t]*//')
  PUBLISHER=$(grep "^publisher:" "$CONFIG_FILE" | cut -d ':' -f 2- | sed 's/^[ \t]*//')
else
  echo "❌ Config file not found: $CONFIG_FILE"
  exit 1
fi

# Create build directory
mkdir -p "$BUILD_DIR"

# Set file paths
MARKDOWN_OUTPUT="$BUILD_DIR/book.md"
PDF_OUTPUT="$BUILD_DIR/book.pdf"
EPUB_OUTPUT="$BUILD_DIR/book.epub"
MOBI_OUTPUT="$BUILD_DIR/book.mobi"
HTML_OUTPUT="$BUILD_DIR/book.html"
RESOURCES_DIR="../resources"

# 1. Combine markdown files
echo "📝 Combining markdown files..."
"$SCRIPTS_DIR/combine-markdown.sh" "$LANGUAGE" "$MARKDOWN_OUTPUT" "$BOOK_TITLE" "$BOOK_SUBTITLE"

# Check if markdown was generated successfully
if [ ! -s "$MARKDOWN_OUTPUT" ]; then
  echo "❌ Failed to generate markdown output"
  exit 1
fi

# 2. Generate PDF (if pandoc is available)
if command -v pandoc &> /dev/null; then
  echo "📄 Generating PDF..."
  "$SCRIPTS_DIR/generate-pdf.sh" "$LANGUAGE" "$MARKDOWN_OUTPUT" "$PDF_OUTPUT" "$BOOK_TITLE" "$RESOURCES_DIR"
else
  echo "⚠️ Pandoc not installed - skipping PDF generation"
fi

# 3. Generate EPUB
if command -v pandoc &> /dev/null; then
  echo "📱 Generating EPUB..."
  "$SCRIPTS_DIR/generate-epub.sh" "$LANGUAGE" "$MARKDOWN_OUTPUT" "$EPUB_OUTPUT" "$BOOK_TITLE" "$BOOK_SUBTITLE" "$RESOURCES_DIR"
else
  echo "⚠️ Pandoc not installed - skipping EPUB generation"
fi

# 4. Generate MOBI (if kindlegen or ebook-convert is available)
if command -v kindlegen &> /dev/null || command -v ebook-convert &> /dev/null; then
  echo "📚 Generating MOBI..."
  "$SCRIPTS_DIR/generate-mobi.sh" "$LANGUAGE" "$EPUB_OUTPUT" "$MOBI_OUTPUT" "$BOOK_TITLE"
else
  echo "⚠️ Neither kindlegen nor Calibre installed - skipping MOBI generation"
fi

# 5. Generate HTML (if pandoc is available)
if command -v pandoc &> /dev/null; then
  echo "🌐 Generating HTML..."
  pandoc "$MARKDOWN_OUTPUT" \
    -o "$HTML_OUTPUT" \
    --metadata title="$BOOK_TITLE" \
    --metadata author="$AUTHOR" \
    --toc \
    --standalone \
    --template="$RESOURCES_DIR/templates/html.template" 2>/dev/null || \
  pandoc "$MARKDOWN_OUTPUT" \
    -o "$HTML_OUTPUT" \
    --metadata title="$BOOK_TITLE" \
    --metadata author="$AUTHOR" \
    --toc \
    --standalone
else
  echo "⚠️ Pandoc not installed - skipping HTML generation"
fi

# Print summary of generated files
echo "✅ Build complete for language: $LANGUAGE"
echo ""
echo "Generated files:"

if [ -f "$MARKDOWN_OUTPUT" ]; then
  MARKDOWN_SIZE=$(du -h "$MARKDOWN_OUTPUT" | cut -f1)
  echo " - Markdown: $MARKDOWN_OUTPUT ($MARKDOWN_SIZE)"
fi

if [ -f "$PDF_OUTPUT" ]; then
  PDF_SIZE=$(du -h "$PDF_OUTPUT" | cut -f1)
  echo " - PDF: $PDF_OUTPUT ($PDF_SIZE)"
fi

if [ -f "$EPUB_OUTPUT" ]; then
  EPUB_SIZE=$(du -h "$EPUB_OUTPUT" | cut -f1)
  echo " - EPUB: $EPUB_OUTPUT ($EPUB_SIZE)"
fi

if [ -f "$MOBI_OUTPUT" ]; then
  MOBI_SIZE=$(du -h "$MOBI_OUTPUT" | cut -f1)
  echo " - MOBI: $MOBI_OUTPUT ($MOBI_SIZE)"
fi

if [ -f "$HTML_OUTPUT" ]; then
  HTML_SIZE=$(du -h "$HTML_OUTPUT" | cut -f1)
  echo " - HTML: $HTML_OUTPUT ($HTML_SIZE)"
fi

# Get word count from markdown
if [ -f "$MARKDOWN_OUTPUT" ]; then
  WORD_COUNT=$(wc -w < "$MARKDOWN_OUTPUT" | xargs)
  echo ""
  echo "📊 Word count: $WORD_COUNT words"
fi
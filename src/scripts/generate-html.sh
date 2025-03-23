#!/bin/bash

# generate-html.sh - Generates HTML from a markdown file
# Usage: generate-html.sh [language] [input_file] [output_file] [book_title] [book_subtitle] [resources_dir] [project_root]

set -e  # Exit on error

# Get parameters
LANGUAGE=${1:-en}
INPUT_FILE=${2:-"output.md"}
OUTPUT_FILE=${3:-"book.html"}
BOOK_TITLE=${4:-"Book Title"}
BOOK_SUBTITLE=${5:-"Book Subtitle"}
RESOURCES_DIR=${6:-"resources"}
PROJECT_ROOT=${7:-$(pwd)}

echo "🌐 Generating HTML for language: $LANGUAGE"
echo "  Input file: $INPUT_FILE"
echo "  Output file: $OUTPUT_FILE"
echo "  Book title: $BOOK_TITLE"
echo "  Book subtitle: $BOOK_SUBTITLE"
echo "  Resources directory: $RESOURCES_DIR"
echo "  Project root: $PROJECT_ROOT"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "⚠️ Error: Input file $INPUT_FILE doesn't exist!"
  exit 1
fi

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
  echo "❌ Error: pandoc is not installed. Please install it before continuing."
  exit 1
fi

# Check for custom HTML template
HTML_TEMPLATE=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/templates/html/template.html" ]; then
  HTML_TEMPLATE="--template=$PROJECT_ROOT/$RESOURCES_DIR/templates/html/template.html"
  echo "Using custom HTML template: $PROJECT_ROOT/$RESOURCES_DIR/templates/html/template.html"
elif [ -f "$PROJECT_ROOT/$RESOURCES_DIR/templates/html/default.html" ]; then
  HTML_TEMPLATE="--template=$PROJECT_ROOT/$RESOURCES_DIR/templates/html/default.html"
  echo "Using default HTML template: $PROJECT_ROOT/$RESOURCES_DIR/templates/html/default.html"
elif [ -f "$PROJECT_ROOT/$RESOURCES_DIR/templates/html/$LANGUAGE-template.html" ]; then
  HTML_TEMPLATE="--template=$PROJECT_ROOT/$RESOURCES_DIR/templates/html/$LANGUAGE-template.html"
  echo "Using language-specific HTML template: $PROJECT_ROOT/$RESOURCES_DIR/templates/html/$LANGUAGE-template.html"
fi

# Check for custom CSS
HTML_STYLE=""
if [ -f "$PROJECT_ROOT/$RESOURCES_DIR/css/html.css" ]; then
  HTML_STYLE="--css=$PROJECT_ROOT/$RESOURCES_DIR/css/html.css"
  echo "Using custom HTML style: $PROJECT_ROOT/$RESOURCES_DIR/css/html.css"
elif [ -f "$PROJECT_ROOT/$RESOURCES_DIR/css/$LANGUAGE-html.css" ]; then
  HTML_STYLE="--css=$PROJECT_ROOT/$RESOURCES_DIR/css/$LANGUAGE-html.css"
  echo "Using language-specific HTML style: $PROJECT_ROOT/$RESOURCES_DIR/css/$LANGUAGE-html.css"
else
  # Create a basic style if none exists
  mkdir -p "$PROJECT_ROOT/$RESOURCES_DIR/css"
  cat > "$PROJECT_ROOT/$RESOURCES_DIR/css/html.css" << EOF
/* Default styles for HTML output */
body {
  max-width: 800px;
  margin: 0 auto;
  padding: 1em;
  line-height: 1.5;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  color: #333;
}

h1, h2, h3, h4, h5, h6 {
  margin-top: 1.5em;
  margin-bottom: 0.5em;
}

h1 { font-size: 2.5em; }
h2 { font-size: 1.8em; }
h3 { font-size: 1.4em; }
h4 { font-size: 1.2em; }
h5 { font-size: 1.1em; }
h6 { font-size: 1em; }

a { color: #0366d6; }
a:hover { text-decoration: underline; }

pre, code {
  background-color: #f6f8fa;
  border-radius: 3px;
  font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
}

pre {
  padding: 16px;
  overflow: auto;
}

code {
  padding: 0.2em 0.4em;
}

blockquote {
  padding: 0 1em;
  color: #6a737d;
  border-left: 0.25em solid #dfe2e5;
}

img {
  max-width: 100%;
}

table {
  border-collapse: collapse;
  width: 100%;
  margin-bottom: 1em;
}

th, td {
  border: 1px solid #dfe2e5;
  padding: 8px 16px;
}

th {
  background-color: #f6f8fa;
  text-align: left;
}

/* Navigation and TOC */
nav {
  background-color: #f6f8fa;
  padding: 1em;
  margin-bottom: 2em;
  border-radius: 5px;
}

nav ul {
  padding-left: 2em;
}

/* Responsive design */
@media (max-width: 600px) {
  body {
    padding: 0.5em;
  }
  
  pre {
    white-space: pre-wrap;
  }
}
EOF
  HTML_STYLE="--css=$PROJECT_ROOT/$RESOURCES_DIR/css/html.css"
  echo "Created default HTML style: $PROJECT_ROOT/$RESOURCES_DIR/css/html.css"
fi

# Define HTML metadata
HTML_METADATA=(
  "--metadata=title:$BOOK_TITLE"
  "--metadata=subtitle:$BOOK_SUBTITLE"
  "--metadata=lang:$LANGUAGE"
)

# Check if book.yaml contains author for metadata
if [ -n "$BOOK_AUTHOR" ]; then
  HTML_METADATA+=("--metadata=author:$BOOK_AUTHOR")
fi

# Ensure image paths are correctly handled
IMAGE_PATH="$PROJECT_ROOT/$RESOURCES_DIR/images"

# Create a build/images directory for HTML output if it doesn't exist
mkdir -p "$PROJECT_ROOT/$RESOURCES_DIR/images"

# Copy book images to build/images for HTML use
if [ -d "book/images" ]; then
  cp -r book/images/* "$PROJECT_ROOT/$RESOURCES_DIR/images/" 2>/dev/null || true
fi

# Copy language-specific images if they exist
if [ -d "book/$LANGUAGE/images" ]; then
  cp -r "book/$LANGUAGE/images/"* "$PROJECT_ROOT/$RESOURCES_DIR/images/" 2>/dev/null || true
fi

# Set HTML-specific options
HTML_OPTIONS=(
  "--toc"
  "--toc-depth=3"
  "--number-sections"
  "--standalone"
  "--highlight-style=tango"
  "--self-contained"  # Include all assets in the HTML file
)

# Build the pandoc command
PANDOC_CMD=(
  "pandoc"
  "$INPUT_FILE"
  "-o" "$OUTPUT_FILE"
  "${HTML_METADATA[@]}"
  "$IMAGE_PATH"
  "${HTML_OPTIONS[@]}"
)

# Add conditional options if they're set
if [ -n "$HTML_TEMPLATE" ]; then
  PANDOC_CMD+=("$HTML_TEMPLATE")
fi

if [ -n "$HTML_STYLE" ]; then
  PANDOC_CMD+=("$HTML_STYLE")
fi

# Run the pandoc command
echo "Executing pandoc command to generate HTML..."
echo "${PANDOC_CMD[@]}"
"${PANDOC_CMD[@]}"

# Check if the HTML was created successfully
if [ -f "$OUTPUT_FILE" ]; then
  file_size=$(du -h "$OUTPUT_FILE" | cut -f1)
  echo "✅ Successfully created HTML: $OUTPUT_FILE ($file_size)"
else
  echo "⚠️ Error: Failed to create HTML!"
  exit 1
fi
#!/bin/bash

# Simple test script to debug build issues - focused on core formats only

set -e  # Exit on error

# Add debug flag to see commands
if [ "$1" == "--debug" ]; then
  set -x  # Show commands as they execute
fi

echo "🧪 Running test build focusing on core formats (PDF, EPUB, HTML, MOBI)"

# Create necessary template directories if they don't exist
mkdir -p templates/html
mkdir -p templates/pdf
mkdir -p templates/epub

# Create minimal template files if they don't exist
if [ ! -f templates/html/default.html ]; then
  echo "Creating minimal HTML template"
  cat > templates/html/default.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="generator" content="pandoc">
  <title>$title$</title>
  <style>
    body { max-width: 800px; margin: 0 auto; padding: 20px; }
    h1, h2, h3 { color: #333; }
  </style>
</head>
<body>
  <header>
    <h1>$title$</h1>
    $if(subtitle)$<h2>$subtitle$</h2>$endif$
    $if(author)$<p>$author$</p>$endif$
  </header>
  <main>
    $body$
  </main>
</body>
</html>
EOF
fi

if [ ! -f templates/html/style.css ]; then
  echo "Creating minimal CSS"
  cat > templates/html/style.css << 'EOF'
body { font-family: sans-serif; line-height: 1.5; }
h1, h2, h3 { color: #333; }
EOF
fi

if [ ! -f templates/pdf/default.latex ]; then
  echo "Creating minimal LaTeX template"
  cat > templates/pdf/default.latex << 'EOF'
\documentclass[$if(fontsize)$$fontsize$,$endif$$if(lang)$$lang$,$endif$$if(papersize)$$papersize$,$endif$]{article}
\usepackage{lmodern}
\usepackage{amssymb,amsmath}
\usepackage{ifxetex,ifluatex}
\usepackage[utf8]{inputenc}
\begin{document}
\maketitle
$body$
\end{document}
EOF
fi

if [ ! -f templates/epub/style.css ]; then
  echo "Creating minimal EPUB CSS"
  cat > templates/epub/style.css << 'EOF'
body { font-family: sans-serif; line-height: 1.5; }
h1, h2, h3 { color: #333; }
EOF
fi

# Make sure the book directory has content
mkdir -p book/en/chapter-01

# Ensure the build directory exists
mkdir -p build

# Check for dependencies
echo "📋 Checking dependencies..."
echo -n "pandoc: "
if command -v pandoc &> /dev/null; then
  echo "✅ $(pandoc --version | head -n 1)"
else
  echo "❌ Not found (needed for PDF, EPUB, HTML)"
fi

echo -n "kindlegen or ebook-convert: "
if command -v kindlegen &> /dev/null; then
  echo "✅ kindlegen found"
elif command -v ebook-convert &> /dev/null; then
  echo "✅ ebook-convert found"
else
  echo "❌ Not found (optional for MOBI format)"
fi

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x src/scripts/*.sh

# Run the build script
echo "🚀 Running build script..."
./src/scripts/build.sh --skip=docx

# Check for output files
echo -e "\n📦 Checking output files..."
find build -type f -not -name "*.md" -not -name "*.tmp" | sort

# Report success or failure
if [ -f build/en/write-and-publish.pdf ] || [ -f build/en/write-and-publish.html ] || [ -f build/en/write-and-publish.epub ]; then
  echo -e "\n✅ Test build succeeded! At least one output format was generated."
else
  echo -e "\n❌ Test build failed: No output files were generated."
  exit 1
fi

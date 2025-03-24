#!/bin/bash

# Simple test script to debug build issues

set -ex  # Exit on error, show commands

# Create necessary template directories if they don't exist
mkdir -p templates/html
mkdir -p templates/pdf
mkdir -p templates/epub
mkdir -p templates/docx

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
\documentclass[$if(fontsize)$$fontsize$,$endif$$if(lang)$$lang$,$endif$$if(papersize)$$papersize$,$endif$]{$documentclass$}
\usepackage{lmodern}
\usepackage{amssymb,amsmath}
\usepackage{ifxetex,ifluatex}
\usepackage{fixltx2e}
\usepackage[utf8]{inputenc}
\usepackage{titling}
\usepackage{fancyhdr}
\pagestyle{fancy}
\begin{document}
\begin{titlingpage}
\maketitle
\end{titlingpage}
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

# Create a basic docx reference document if it doesn't exist
if [ ! -f templates/docx/reference.docx ]; then
  echo "Creating minimal DOCX reference template"
  pandoc -o templates/docx/reference.docx --print-default-data-file reference.docx 2>/dev/null || true
fi

# Make sure the book directory has content
mkdir -p book/en/chapter-01

# Ensure the build directory exists
mkdir -p build

# Run the build script with verbose output
chmod +x src/scripts/build.sh
./src/scripts/build.sh --languages=en

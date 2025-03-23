#!/bin/bash

# setup.sh - Setup script for book build environment
# Usage: setup.sh [--install-deps]

set -e  # Exit on error

INSTALL_DEPS=false

# Parse command line arguments
for arg in "$@"; do
  case $arg in
    --install-deps)
      INSTALL_DEPS=true
      ;;
  esac
done

echo "🔧 Setting up book build environment..."

# Check prerequisites
check_command() {
  if command -v "$1" &> /dev/null; then
    echo "✅ $1 found"
    return 0
  else
    echo "❌ $1 not found"
    return 1
  fi
}

# Create required directories
mkdir -p build
mkdir -p resources/templates
mkdir -p resources/css
mkdir -p resources/images

echo "📋 Checking system prerequisites..."

# Essential tools
check_command "pandoc" || MISSING_ESSENTIAL=true
check_command "bash" || MISSING_ESSENTIAL=true
check_command "grep" || MISSING_ESSENTIAL=true
check_command "sed" || MISSING_ESSENTIAL=true

# Optional tools
check_command "kindlegen" || echo "⚠️ kindlegen not found - MOBI generation may be limited"
check_command "ebook-convert" || echo "⚠️ Calibre's ebook-convert not found - MOBI generation may be limited"
check_command "pdflatex" || echo "⚠️ pdflatex not found - PDF generation may be limited"

# Check for basic directory structure
if [ ! -d "book" ]; then
  echo "❌ 'book' directory not found in current directory"
  echo "Creating 'book' directory structure..."
  mkdir -p book/en/01-chapter-one
  mkdir -p book/en/02-chapter-two
  mkdir -p book/en/images
  mkdir -p book/en/appendices
  
  # Create sample markdown files
  echo "# Chapter One" > book/en/01-chapter-one/01-introduction.md
  echo "This is the introduction to chapter one." >> book/en/01-chapter-one/01-introduction.md
  
  echo "# Chapter Two" > book/en/02-chapter-two/01-content.md
  echo "This is the content of chapter two." >> book/en/02-chapter-two/01-content.md
  
  echo "# Appendix A" > book/en/appendices/appendix-a.md
  echo "This is appendix A." >> book/en/appendices/appendix-a.md
  
  echo "# Glossary" > book/en/glossary.md
  echo "**Term**: Definition" >> book/en/glossary.md
fi

# Check for book.yaml
if [ ! -f "book.yaml" ]; then
  echo "❌ 'book.yaml' file not found in current directory"
  echo "Creating sample book.yaml..."

  cat > book.yaml << EOF
title: "Sample Book"
subtitle: "A Book Built with the Template System"
author: "Your Name"
publisher: "Self-Published"
rights: "Copyright © $(date +%Y)"
description: "This is a sample book created with the book template system."
languages: [en]

# PDF Settings
pdf:
  enabled: true
  fontsize: 12pt
  papersize: letter
  margin: 1in
  lineheight: 1.5

# EPUB Settings
epub:
  enabled: true
  css: "resources/css/epub.css"
  cover_image: "resources/images/cover.jpg"

# MOBI Settings
mobi:
  enabled: true

# HTML Settings
html:
  enabled: true
  css: "resources/css/html.css"
  template: "resources/templates/html.template"
EOF
fi

# Create CSS files if they don't exist
if [ ! -f "resources/css/epub.css" ]; then
  echo "Creating sample EPUB CSS..."
  mkdir -p resources/css
  cat > resources/css/epub.css << EOF
body {
  font-family: serif;
  margin: 5%;
  text-align: justify;
  line-height: 1.5;
}
h1, h2, h3, h4, h5, h6 {
  font-family: sans-serif;
  text-align: left;
  margin-top: 2em;
}
h1 { font-size: 2em; }
h2 { font-size: 1.5em; }
code { font-family: monospace; }
a { text-decoration: none; }
EOF
fi

if [ ! -f "resources/css/html.css" ]; then
  echo "Creating sample HTML CSS..."
  mkdir -p resources/css
  cat > resources/css/html.css << EOF
body {
  font-family: serif;
  margin: 0 auto;
  max-width: 50em;
  padding: 1em;
  line-height: 1.5;
  color: #333;
}
h1, h2, h3, h4, h5, h6 {
  font-family: sans-serif;
  margin-top: 1.5em;
  color: #222;
}
code { font-family: monospace; background: #f5f5f5; padding: 0.2em; }
a { color: #1a6091; text-decoration: none; }
a:hover { text-decoration: underline; }
EOF
fi

# Try to install missing dependencies if requested
if [ "$INSTALL_DEPS" = true ] && [ "$MISSING_ESSENTIAL" = true ]; then
  echo "Attempting to install missing dependencies..."
  
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v apt-get &> /dev/null; then
      echo "Using apt-get to install dependencies..."
      sudo apt-get update
      sudo apt-get install -y pandoc texlive
    elif command -v yum &> /dev/null; then
      echo "Using yum to install dependencies..."
      sudo yum install -y pandoc texlive
    else
      echo "❌ Unsupported package manager. Please install Pandoc and LaTeX manually."
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v brew &> /dev/null; then
      echo "Using Homebrew to install dependencies..."
      brew install pandoc
      brew install --cask basictex
    else
      echo "❌ Homebrew not found. Please install Homebrew first or install the dependencies manually."
      echo "To install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
  else
    echo "❌ Unsupported operating system. Please install the dependencies manually."
  fi
fi

echo "✅ Setup complete!"
if [ "$MISSING_ESSENTIAL" = true ]; then
  echo "⚠️ Some essential tools are missing. Not all book formats may be generated correctly."
  echo "   Please install the missing tools mentioned above."
fi
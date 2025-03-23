#!/bin/bash

# setup.sh - Checks for required dependencies and sets up the build environment

echo "🔧 Setting up build environment..."

# Check for required commands
MISSING_DEPS=false

check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "❌ $1 is not installed or not in PATH"
    MISSING_DEPS=true
    return 1
  else
    echo "✅ Found $1: $(command -v "$1")"
    return 0
  fi
}

# Basic dependencies
echo "Checking for basic dependencies..."
check_command "pandoc"
check_command "pdflatex"

# Optional dependencies
echo "Checking for optional dependencies..."
check_command "kindlegen" || echo "ℹ️ kindlegen not found. MOBI generation will be disabled."
check_command "convert" || echo "ℹ️ ImageMagick convert not found. Some image processing may be limited."

# Check pandoc version
if check_command "pandoc"; then
  PANDOC_VERSION=$(pandoc --version | head -n 1 | cut -d' ' -f2)
  echo "Pandoc version: $PANDOC_VERSION"
  
  # Parse version numbers
  PANDOC_MAJOR=$(echo $PANDOC_VERSION | cut -d'.' -f1)
  PANDOC_MINOR=$(echo $PANDOC_VERSION | cut -d'.' -f2)
  
  if [ "$PANDOC_MAJOR" -lt 2 ] || ([ "$PANDOC_MAJOR" -eq 2 ] && [ "$PANDOC_MINOR" -lt 10 ]); then
    echo "⚠️ Warning: Pandoc version $PANDOC_VERSION may be too old. Version 2.10 or newer is recommended."
  fi
fi

# Check LaTeX dependencies
echo "Checking LaTeX dependencies..."
LATEX_PACKAGES=("xcolor" "graphicx" "hyperref" "ulem" "geometry" "setspace" "booktabs" "footmisc" "csquotes")

for pkg in "${LATEX_PACKAGES[@]}"; do
  if kpsewhich "$pkg.sty" &> /dev/null; then
    echo "✅ Found LaTeX package: $pkg"
  else
    echo "⚠️ Missing LaTeX package: $pkg"
    # Not setting MISSING_DEPS to true as these are optional
  fi
done

# Create build directories if they don't exist
echo "Creating required directories..."
mkdir -p build
mkdir -p templates/{pdf,epub,html}
mkdir -p build/images
mkdir -p book/images

# Ensure language directories exist
if [ -f "book.yaml" ]; then
  for lang in "${CONFIGURED_LANGUAGES[@]}"; do
    if [ ! -d "book/$lang" ]; then
      echo "📁 Creating language directory for $lang"
      mkdir -p "book/$lang"
    fi
  done
fi

# Check for front matter
for lang in "${CONFIGURED_LANGUAGES[@]}"; do
  if [ ! -f "book/$lang/00-front-matter.md" ]; then
    echo "ℹ️ No front matter found for $lang, creating a template"
    cat > "book/$lang/00-front-matter.md" << EOF
---
title: "${BOOK_TITLE}"
subtitle: "${BOOK_SUBTITLE}"
author: "${BOOK_AUTHOR}"
date: "$(date +"%B %Y")"
language: "${lang}"
---

# ${BOOK_TITLE}

## ${BOOK_SUBTITLE}

By ${BOOK_AUTHOR}

---

This is the front matter of your book. You can customize this file with your book's
introduction, copyright information, dedication, etc.

EOF
  fi
done

# Check environment variables
if [ -z "$BOOK_TITLE" ]; then
  echo "⚠️ BOOK_TITLE environment variable is not set. Using 'My Book' as default."
  export BOOK_TITLE="My Book"
fi

if [ -z "$BOOK_AUTHOR" ]; then
  echo "⚠️ BOOK_AUTHOR environment variable is not set. Using 'Author Name' as default."
  export BOOK_AUTHOR="Author Name"
fi

# Print setup results
if [ "$MISSING_DEPS" = true ]; then
  echo "⚠️ Some required dependencies are missing. Please install them before continuing."
  echo "   The build process may fail or produce unexpected results."
else
  echo "✅ All required dependencies are installed."
fi

echo "✅ Setup complete!"
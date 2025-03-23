#!/bin/bash

# create-book.sh - Creates a new book template
# Usage: create-book.sh <book-name> [language] [--copy-scripts]

set -e  # Exit on error

# Usage: create-book.sh <book-name> [language] [--copy-scripts]
# Creates a new book project with the correct directory structure

BOOK_NAME=$1
LANGUAGE="en"
COPY_SCRIPTS=false

shift # Remove book name from arguments

# Process remaining arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --copy-scripts)
            COPY_SCRIPTS=true
            ;;
        *)
            if [[ "$1" != --* ]]; then
                LANGUAGE="$1" # Assume it's a language code
            fi
            ;;
    esac
    shift
done

if [[ -z "$BOOK_NAME" ]]; then
    echo "Usage: create-book.sh <book-name> [language] [--copy-scripts]"
    exit 1
fi

# Format book name for title (capitalize words, replace hyphens with spaces)
BOOK_TITLE=$(echo "$BOOK_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

# Create directory structure
mkdir -p "$BOOK_NAME"
mkdir -p "$BOOK_NAME/book/$LANGUAGE/01-introduction"
mkdir -p "$BOOK_NAME/book/$LANGUAGE/02-chapter-one"
mkdir -p "$BOOK_NAME/book/$LANGUAGE/03-chapter-two"
mkdir -p "$BOOK_NAME/book/$LANGUAGE/appendices"
mkdir -p "$BOOK_NAME/book/$LANGUAGE/images"
mkdir -p "$BOOK_NAME/resources/css"
mkdir -p "$BOOK_NAME/resources/images"
mkdir -p "$BOOK_NAME/resources/templates"

echo "📚 Creating new book: $BOOK_NAME (Language: $LANGUAGE)"
echo "📁 Created directory structure"

# Create book.yaml
cat > "$BOOK_NAME/book.yaml" << EOF
title: "$BOOK_TITLE"
subtitle: "A Comprehensive Guide"
author: "Your Name"
publisher: "Your Publisher"
rights: "Copyright © $(date +%Y)"
description: "A comprehensive guide about $BOOK_TITLE."
languages: [$LANGUAGE]

# PDF Settings
pdf:
  enabled: true
  fontsize: 11pt
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

echo "📝 Created book.yaml configuration file"

# Copy scripts if requested
if [ "$COPY_SCRIPTS" = true ]; then
    echo "📋 Copying book-tools scripts to the project..."
    mkdir -p "$BOOK_NAME/scripts"
    cp "$(dirname "$0")"/*.sh "$BOOK_NAME/scripts/"
    # Make scripts executable
    chmod +x "$BOOK_NAME/scripts"/*.sh
    # Copy make-scripts-executable.sh to the book root
    cp "$(dirname "$0")/../make-scripts-executable.sh" "$BOOK_NAME/"
    chmod +x "$BOOK_NAME/make-scripts-executable.sh"
    echo "✅ Scripts copied and made executable"
fi

# Create sample markdown files
cat > "$BOOK_NAME/book/$LANGUAGE/01-introduction/01-preface.md" << EOF
# Preface

Welcome to $BOOK_TITLE. This book aims to provide...

## About this Book

This book is organized into several chapters...

## Acknowledgments

I would like to thank...
EOF

cat > "$BOOK_NAME/book/$LANGUAGE/02-chapter-one/01-section.md" << EOF
# Getting Started

This chapter covers the basics of...

## First Steps

Here are the first steps you should take...

## Key Concepts

Some important concepts to understand include...
EOF

cat > "$BOOK_NAME/book/$LANGUAGE/03-chapter-two/01-advanced.md" << EOF
# Advanced Topics

This chapter dives deeper into...

## Complex Examples

Let's examine some more complex examples...

## Best Practices

Here are some best practices to follow...
EOF

cat > "$BOOK_NAME/book/$LANGUAGE/appendices/01-appendix-a.md" << EOF
# Appendix A: Resources

Here are some additional resources that you might find helpful:

- Resource 1: Description and link
- Resource 2: Description and link
- Resource 3: Description and link
EOF

cat > "$BOOK_NAME/book/$LANGUAGE/glossary.md" << EOF
# Glossary

**Term 1**: Definition of term 1.

**Term 2**: Definition of term 2.

**Term 3**: Definition of term 3.
EOF
echo "📄 Created sample markdown files"

# Create CSS files
cat > "$BOOK_NAME/resources/css/epub.css" << EOF
body {
  font-family: serif;
  font-size: 1em;
  line-height: 1.5;
  margin: 5%;
}

h1, h2, h3, h4, h5, h6 {
  font-family: sans-serif;
  margin-top: 2em;
}

h1 {
  font-size: 2em;
}

h2 {
  font-size: 1.5em;
}
EOF

cat > "$BOOK_NAME/resources/css/html.css" << EOF
body {
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  line-height: 1.6;
  max-width: 800px;
  margin: 0 auto;
  padding: 2em 1em;
  color: #333;
}

h1, h2, h3, h4, h5, h6 {
  color: #222;
  margin-top: 1.5em;
  margin-bottom: 0.5em;
}

a {
  color: #0066cc;
}

pre, code {
  background: #f5f5f5;
  border-radius: 3px;
  padding: 0.2em 0.4em;
  font-size: 0.9em;
}

pre {
  padding: 1em;
  overflow: auto;
}

pre code {
  background: none;
  padding: 0;
}
EOF
echo "🎨 Created CSS files"

# Create placeholder image
mkdir -p "$BOOK_NAME/resources/images"
cat > "$BOOK_NAME/resources/images/cover.jpg" << EOF
(This is a placeholder file. Replace with an actual JPEG image.)
EOF
echo "🖼️ Created placeholder image"

# Create README with standard sections
echo "# $BOOK_TITLE" > "$BOOK_NAME/README.md"
echo "" >> "$BOOK_NAME/README.md"
echo "This is a book created with the Book Tools system." >> "$BOOK_NAME/README.md"
echo "" >> "$BOOK_NAME/README.md"
echo "## Building the Book" >> "$BOOK_NAME/README.md"
echo "" >> "$BOOK_NAME/README.md"
echo "To build this book in various formats:" >> "$BOOK_NAME/README.md"
echo "" >> "$BOOK_NAME/README.md"
echo "1. Install the required dependencies:" >> "$BOOK_NAME/README.md"
echo "   - Pandoc" >> "$BOOK_NAME/README.md"
echo "   - LaTeX (for PDF generation)" >> "$BOOK_NAME/README.md"
echo "   - Kindlegen or Calibre (for MOBI generation)" >> "$BOOK_NAME/README.md"
echo "" >> "$BOOK_NAME/README.md"
echo "2. Run the build script:" >> "$BOOK_NAME/README.md"
echo "" >> "$BOOK_NAME/README.md"

if [ "$COPY_SCRIPTS" = true ]; then
    echo "   \`\`\`bash" >> "$BOOK_NAME/README.md"
    echo "   ./scripts/build.sh" >> "$BOOK_NAME/README.md"
    echo "   \`\`\`" >> "$BOOK_NAME/README.md"
    echo "" >> "$BOOK_NAME/README.md"
    echo "   Or to build only specific formats:" >> "$BOOK_NAME/README.md"
    echo "   \`\`\`bash" >> "$BOOK_NAME/README.md"
    echo "   ./scripts/build.sh --skip pdf,mobi" >> "$BOOK_NAME/README.md"
    echo "   \`\`\`" >> "$BOOK_NAME/README.md"
else
    echo "   \`\`\`bash" >> "$BOOK_NAME/README.md"
    echo "   /path/to/book-tools/src/scripts/build.sh" >> "$BOOK_NAME/README.md"
    echo "   \`\`\`" >> "$BOOK_NAME/README.md"
    echo "" >> "$BOOK_NAME/README.md"
    echo "   Or to build only specific formats:" >> "$BOOK_NAME/README.md"
    echo "   \`\`\`bash" >> "$BOOK_NAME/README.md"
    echo "   /path/to/book-tools/src/scripts/build.sh --skip pdf,mobi" >> "$BOOK_NAME/README.md"
    echo "   \`\`\`" >> "$BOOK_NAME/README.md"
fi

echo "" >> "$BOOK_NAME/README.md"
echo "## Directory Structure" >> "$BOOK_NAME/README.md"
echo "" >> "$BOOK_NAME/README.md"
echo "- \`book/\`: Contains the book content organized by language" >> "$BOOK_NAME/README.md"
echo "  - \`$LANGUAGE/\`: Content in $LANGUAGE language" >> "$BOOK_NAME/README.md"
echo "    - \`01-introduction/\`: Introduction chapters" >> "$BOOK_NAME/README.md"
echo "    - \`02-chapter-one/\`: First main chapter" >> "$BOOK_NAME/README.md"
echo "    - \`03-chapter-two/\`: Second main chapter" >> "$BOOK_NAME/README.md"
echo "    - \`appendices/\`: Appendix content" >> "$BOOK_NAME/README.md"
echo "    - \`glossary.md\`: Glossary of terms" >> "$BOOK_NAME/README.md"
echo "- \`resources/\`: Contains resources like images and CSS" >> "$BOOK_NAME/README.md"
echo "  - \`css/\`: Stylesheets for EPUB and HTML" >> "$BOOK_NAME/README.md"
echo "  - \`images/\`: Common images including cover" >> "$BOOK_NAME/README.md"
echo "  - \`templates/\`: Custom templates (if any)" >> "$BOOK_NAME/README.md"
echo "- \`book.yaml\`: Book configuration file" >> "$BOOK_NAME/README.md"

if [ "$COPY_SCRIPTS" = true ]; then
    echo "- \`scripts/\`: Book building scripts" >> "$BOOK_NAME/README.md"
    echo "  - \`build.sh\`: Main build script" >> "$BOOK_NAME/README.md" 
    echo "  - And various helper scripts" >> "$BOOK_NAME/README.md"
fi

echo "✅ Book project created successfully at $BOOK_NAME/"
echo ""
echo "Next steps:"
echo "1. Navigate to the book directory: cd $BOOK_NAME"
echo "2. Edit book.yaml to update metadata"
echo "3. Replace the sample markdown files with your content"
echo "4. Add a cover image to resources/images/cover.jpg"
if [ "$COPY_SCRIPTS" = true ]; then
    echo "5. Build your book: ./scripts/build.sh"
else
    echo "5. Build your book: /path/to/book-tools/src/scripts/build.sh"
fi
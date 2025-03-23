#!/bin/bash

# test-build.sh - Test the book building system

set -e  # Exit on error

echo "🧪 Running book build test..."

# Make scripts executable
./make-scripts-executable.sh

# Create test directory structure if it doesn't exist
mkdir -p test-book/en/01-chapter-one
mkdir -p test-book/en/02-chapter-two
mkdir -p test-book/en/appendices
mkdir -p test-book/en/images
mkdir -p test-book/resources/templates
mkdir -p test-book/resources/css
mkdir -p test-book/resources/images

# Create sample book.yaml
cat > test-book/book.yaml << EOF
title: "Test Book"
subtitle: "A Book Building Test"
author: "Test Author"
publisher: "Test Publisher"
rights: "Copyright © $(date +%Y)"
description: "This is a test book."
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

# MOBI Settings
mobi:
  enabled: true

# HTML Settings
html:
  enabled: true
EOF

# Create sample markdown files
cat > test-book/en/01-chapter-one/01-introduction.md << EOF
# Introduction

This is a test chapter for the book building system.

## Section 1.1

This is a subsection with some content.

### Subsection 1.1.1

More detailed content goes here.
EOF

cat > test-book/en/02-chapter-two/01-content.md << EOF
# Chapter Two

This is the second chapter of our test book.

## Important Information

Here is some important information for our test.

1. First item
2. Second item
3. Third item

## Code Example

Here is a code example:

\`\`\`bash
#!/bin/bash
echo "Hello, World!"
\`\`\`
EOF

cat > test-book/en/appendices/appendix-a.md << EOF
# Appendix A

This is an appendix with additional information.

## Reference Table

| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
EOF

cat > test-book/en/glossary.md << EOF
# Glossary

**Term 1**: Definition of term 1.

**Term 2**: Definition of term 2.

**Term 3**: Definition of term 3.
EOF

# Copy our scripts to the test directory
cp -r scripts test-book/

# Navigate to test directory
cd test-book

# Run setup script
./scripts/setup.sh

# Run build script
./scripts/build.sh

# Check results
echo ""
echo "📊 Test Results:"
echo ""

if [ -f "build/en/book.md" ]; then
  echo "✅ Markdown generation successful"
else
  echo "❌ Markdown generation failed"
fi

if [ -f "build/en/book.epub" ]; then
  echo "✅ EPUB generation successful"
else
  echo "❌ EPUB generation failed"
fi

if [ -f "build/en/book.pdf" ]; then
  echo "✅ PDF generation successful"
else
  echo "❌ PDF generation failed"
fi

if [ -f "build/en/book.mobi" ]; then
  echo "✅ MOBI generation successful"
else
  echo "❌ MOBI generation failed"
fi

if [ -f "build/en/book.html" ]; then
  echo "✅ HTML generation successful"
else
  echo "❌ HTML generation failed"
fi

echo ""
echo "🎉 Test completed!"

# Return to original directory
cd ..

echo "Run 'cd test-book && ls -la build/en/' to see the generated files" 
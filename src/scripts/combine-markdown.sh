#!/bin/bash

# combine-markdown.sh - Combines markdown files from the book directory
# Usage: combine-markdown.sh [language] [output_file] [book_title] [book_subtitle] [project_root]

set -e  # Exit on error

# Get arguments
LANGUAGE=${1:-en}
OUTPUT_PATH=${2:-book.md}
BOOK_TITLE=${3:-"Test Book"}
BOOK_SUBTITLE=${4:-"A Test Book"}
PROJECT_ROOT=${5:-$(pwd)}

echo "📝 Combining markdown files for $LANGUAGE..."
echo "  - Language: $LANGUAGE"
echo "  - Output: $OUTPUT_PATH"
echo "  - Title: $BOOK_TITLE"
echo "  - Project Root: $PROJECT_ROOT"

# Debugging directory information
echo "Checking for language directory:"
ls -la "$PROJECT_ROOT/book" || echo "No book directory found at $PROJECT_ROOT/book"

# Get author, publisher etc. from book.yaml
BOOK_YAML="$PROJECT_ROOT/book.yaml"
echo "Reading metadata from $BOOK_YAML..."

if [ -f "$BOOK_YAML" ]; then
  BOOK_AUTHOR=$(grep "^author:" "$BOOK_YAML" | cut -d ':' -f 2- | sed 's/^[ \t]*//' | tr -d '"')
  PUBLISHER=$(grep "^publisher:" "$BOOK_YAML" | cut -d ':' -f 2- | sed 's/^[ \t]*//' | tr -d '"')
else
  BOOK_AUTHOR="Test Author"
  PUBLISHER="Test Publisher"
fi

LANGUAGE_DIR="$PROJECT_ROOT/book/$LANGUAGE"

# Check that the language directory exists
echo "Checking $LANGUAGE_DIR directory..."
if [ ! -d "$LANGUAGE_DIR" ]; then
  echo "❌ Language directory not found: $LANGUAGE_DIR"
  echo "Creating minimal content..."
  mkdir -p "$LANGUAGE_DIR/chapter-01"
  echo "# Sample Chapter" > "$LANGUAGE_DIR/chapter-01/01-sample.md"
  echo "This is a sample chapter created automatically." >> "$LANGUAGE_DIR/chapter-01/01-sample.md"
  echo "Created minimal content in $LANGUAGE_DIR"
fi

# Make sure the parent directory exists
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Clear the file if it exists
true > "$OUTPUT_PATH"

# Add metadata header
cat > "$OUTPUT_PATH" << EOF
---
title: $BOOK_TITLE
subtitle: $BOOK_SUBTITLE
author: $BOOK_AUTHOR
publisher: $PUBLISHER
language: "$LANGUAGE"
toc: true
EOF

# Add cover image metadata if a cover image exists
if [ -f "$PROJECT_ROOT/resources/images/cover.jpg" ]; then
  echo "cover-image: \"$PROJECT_ROOT/resources/images/cover.jpg\"" >> "$OUTPUT_PATH"
elif [ -f "$PROJECT_ROOT/resources/images/cover.png" ]; then
  echo "cover-image: \"$PROJECT_ROOT/resources/images/cover.png\"" >> "$OUTPUT_PATH"
elif [ -f "$PROJECT_ROOT/book/images/cover.jpg" ]; then
  echo "cover-image: \"$PROJECT_ROOT/book/images/cover.jpg\"" >> "$OUTPUT_PATH"
elif [ -f "$PROJECT_ROOT/book/images/cover.png" ]; then
  echo "cover-image: \"$PROJECT_ROOT/book/images/cover.png\"" >> "$OUTPUT_PATH"
fi

# Close the metadata block
cat >> "$OUTPUT_PATH" << EOF
---

EOF

# Find all markdown files to process
echo "Finding markdown files in $LANGUAGE_DIR..."

# Auto-detect structure type
if find "$LANGUAGE_DIR" -maxdepth 1 -type d -name "chapter-*" | grep -q .; then
  STRUCTURE_TYPE="chapter-based"
  echo "Using chapter-based directory structure"
else
  STRUCTURE_TYPE="flat"
  echo "Using flat file structure (all markdown files)"
fi

# Process files based on structure type
if [ "$STRUCTURE_TYPE" = "chapter-based" ]; then
  # Find all chapter directories and sort them
  CHAPTERS=$(find "$LANGUAGE_DIR" -maxdepth 1 -type d -name "chapter-*" | sort)
  
  if [ -z "$CHAPTERS" ]; then
    echo "No chapter directories found in $LANGUAGE_DIR"
    # Fallback to flat structure
    FILES=$(find "$LANGUAGE_DIR" -maxdepth 1 -name "*.md" | sort)
    
    if [ -z "$FILES" ]; then
      echo "No markdown files found, creating a sample file"
      mkdir -p "$LANGUAGE_DIR/chapter-01"
      echo "# Sample Chapter" > "$LANGUAGE_DIR/chapter-01/01-sample.md"
      echo "This is a sample chapter created automatically." >> "$LANGUAGE_DIR/chapter-01/01-sample.md"
      CHAPTERS="$LANGUAGE_DIR/chapter-01"
    fi
  fi
  
  for CHAPTER in $CHAPTERS; do
    CHAPTER_NAME=$(basename "$CHAPTER")
    echo "Processing chapter: $CHAPTER_NAME"
    
    # Add chapter heading
    CHAPTER_NUM=$(echo "$CHAPTER_NAME" | sed -E 's/chapter-0*([0-9]+).*/\1/')
    echo -e "\n# Chapter $CHAPTER_NUM\n" >> "$OUTPUT_PATH"
    
    # Get all markdown files in this chapter
    CHAPTER_FILES=$(find "$CHAPTER" -maxdepth 1 -name "*.md" | sort)
    
    if [ -z "$CHAPTER_FILES" ]; then
      echo "No markdown files found in $CHAPTER"
      continue
    fi
    
    for FILE in $CHAPTER_FILES; do
      echo "Adding section from $FILE"
      # Add section heading with file name
      FILE_NAME=$(basename "$FILE" .md)
      FILE_TITLE=$(sed -n '1s/^#\s*//p' "$FILE" 2>/dev/null || echo "$FILE_NAME")
      
      echo "" >> "$OUTPUT_PATH"
      echo "<!-- Start of section: $FILE_NAME -->" >> "$OUTPUT_PATH"
      echo "" >> "$OUTPUT_PATH"
      
      # Remove YAML front matter if present and append content
      sed -n '/^---$/,/^---$/!p' "$FILE" | sed '/./,$!d' >> "$OUTPUT_PATH"
      echo "" >> "$OUTPUT_PATH"
      echo "" >> "$OUTPUT_PATH"
    done
    
    # Add page break between chapters
    echo -e "\n\n<div style=\"page-break-after: always;\"></div>\n\n" >> "$OUTPUT_PATH"
  done
else
  # Flat structure: process all markdown files in alphabetical order
  FILES=$(find "$LANGUAGE_DIR" -maxdepth 1 -name "*.md" | sort)
  
  if [ -z "$FILES" ]; then
    echo "No markdown files found, creating a sample file"
    echo "# Sample Content" > "$LANGUAGE_DIR/01-sample.md"
    echo "This is sample content created automatically." >> "$LANGUAGE_DIR/01-sample.md"
    FILES="$LANGUAGE_DIR/01-sample.md"
  fi
  
  for FILE in $FILES; do
    echo "Adding section from $FILE"
    FILE_NAME=$(basename "$FILE" .md)
    
    echo "" >> "$OUTPUT_PATH"
    echo "<!-- Start of section: $FILE_NAME -->" >> "$OUTPUT_PATH"
    echo "" >> "$OUTPUT_PATH"
    
    # Remove YAML front matter if present and append content
    sed -n '/^---$/,/^---$/!p' "$FILE" | sed '/./,$!d' >> "$OUTPUT_PATH"
    echo "" >> "$OUTPUT_PATH"
    echo "" >> "$OUTPUT_PATH"
  done
fi

# Process appendices if they exist
APPENDICES_DIR="$PROJECT_ROOT/book/$LANGUAGE/appendices"
if [ -d "$APPENDICES_DIR" ]; then
  echo "Processing appendices from $APPENDICES_DIR"
  
  echo -e "\n\n# Appendices\n\n" >> "$OUTPUT_PATH"
  
  find "$APPENDICES_DIR" -type f -name "*.md" | sort -V | while read -r appendix_file; do
    echo "Adding appendix: $appendix_file"
    cat "$appendix_file" >> "$OUTPUT_PATH"
    # Only add page break if file doesn't already have one
    if ! grep -q '<div style="page-break-after: always;"></div>' "$appendix_file"; then
      echo -e "\n\n---\n\n<div style=\"page-break-after: always;\"></div>\n\n" >> "$OUTPUT_PATH"
    fi
  done
fi

# Process glossary if it exists
GLOSSARY_FILE="$PROJECT_ROOT/book/$LANGUAGE/glossary.md"
if [ -f "$GLOSSARY_FILE" ]; then
  echo "Adding glossary from $GLOSSARY_FILE"
  echo -e "\n\n# Glossary\n\n" >> "$OUTPUT_PATH"
  cat "$GLOSSARY_FILE" >> "$OUTPUT_PATH"
  # Only add page break if file doesn't already have one
  if ! grep -q '<div style="page-break-after: always;"></div>' "$GLOSSARY_FILE"; then
    echo -e "\n\n---\n\n<div style=\"page-break-after: always;\"></div>\n\n" >> "$OUTPUT_PATH"
  fi
fi

echo "✅ Markdown files combined into $OUTPUT_PATH"

# Print a word count
if command -v wc &> /dev/null; then
  WORD_COUNT=$(wc -w < "$OUTPUT_PATH")
  CHAR_COUNT=$(wc -c < "$OUTPUT_PATH")
  echo "📊 Word count: $WORD_COUNT words, $CHAR_COUNT characters"
fi

# Verify the output file exists and has content
if [ ! -s "$OUTPUT_PATH" ]; then
  echo "⚠️ Warning: The combined Markdown file is empty!"
  
  # Create a minimal file with just the metadata
  cat > "$OUTPUT_PATH" << EOF
---
title: "$BOOK_TITLE"
subtitle: "$BOOK_SUBTITLE"
author: "$BOOK_AUTHOR"
publisher: "$PUBLISHER"
language: "$LANGUAGE"
toc: true
---

# $BOOK_TITLE

## $BOOK_SUBTITLE

By $BOOK_AUTHOR

This book appears to be empty or the Markdown files could not be processed correctly.
Please check the directory structure and ensure there are valid Markdown files in the correct locations.
EOF

  echo "Created minimal fallback content to prevent build failures."
fi
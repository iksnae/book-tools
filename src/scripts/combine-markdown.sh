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

# Get author, publisher etc. from book.yaml
BOOK_YAML="$PROJECT_ROOT/book.yaml"
echo "Reading metadata from $BOOK_YAML..."

if [ -f "$BOOK_YAML" ]; then
  BOOK_AUTHOR=$(grep "^author:" "$BOOK_YAML" | cut -d ':' -f 2- | sed 's/^[ \t]*//')
  PUBLISHER=$(grep "^publisher:" "$BOOK_YAML" | cut -d ':' -f 2- | sed 's/^[ \t]*//')
  LANGUAGE_DIR="$PROJECT_ROOT/book/$LANGUAGE"
else
  BOOK_AUTHOR="Test Author"
  PUBLISHER="Test Publisher"
  LANGUAGE_DIR="$PROJECT_ROOT/book/$LANGUAGE"
fi

# Check that the language directory exists
echo "Checking $LANGUAGE_DIR directory..."
if [ ! -d "$LANGUAGE_DIR" ]; then
  echo "❌ Language directory not found: $LANGUAGE_DIR"
  exit 1
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
fi

# Close the metadata block
cat >> "$OUTPUT_PATH" << EOF
---

EOF

# Find all markdown files to process
FILES=""
echo "Files to be processed:"

# Get files in the language directory
FILES=$(find "$LANGUAGE_DIR" -name "*.md" | sort)
for FILE in $FILES; do
  echo "$FILE"
done

# Check for a marker file that indicates the structure type
if [ -f "$LANGUAGE_DIR/.numeric-structure" ]; then
  STRUCTURE_TYPE="numeric"
elif [ -f "$LANGUAGE_DIR/.custom-order" ]; then
  STRUCTURE_TYPE="custom"
else
  # Auto-detect structure type
  if find "$LANGUAGE_DIR" -maxdepth 1 -name "[0-9]*-*" | grep -q .; then
    STRUCTURE_TYPE="numeric"
    echo "Using numeric directory-based structure"
  else
    STRUCTURE_TYPE="flat"
    echo "Using flat file structure (all markdown files)"
  fi
fi

# Process files based on structure type
if [ "$STRUCTURE_TYPE" = "numeric" ]; then
  # Find all directories that match the numeric pattern
  DIRS=$(find "$LANGUAGE_DIR" -maxdepth 1 -type d -name "[0-9]*-*" | sort)
  
  if [ -z "$DIRS" ]; then
    echo "No chapter directories found in $LANGUAGE_DIR"
    # Fallback to flat structure
    FILES=$(find "$LANGUAGE_DIR" -maxdepth 1 -name "*.md" | sort)
  else
    echo "Processing directory: $LANGUAGE_DIR"
    # Process each directory
    for DIR in $DIRS; do
      echo "Processing directory: $DIR"
      # Get all markdown files in this directory
      DIR_FILES=$(find "$DIR" -maxdepth 1 -name "*.md" | sort)
      for FILE in $DIR_FILES; do
        echo "Adding section from $FILE"
        # Add section heading with file name
        echo "" >> "$OUTPUT_PATH"
        echo "<!-- Start of section: $(basename "$FILE") -->" >> "$OUTPUT_PATH"
        echo "" >> "$OUTPUT_PATH"
        # Remove YAML front matter if present and append content
        sed -n '/^---$/,/^---$/!p' "$FILE" | sed '/./,$!d' >> "$OUTPUT_PATH"
        echo "" >> "$OUTPUT_PATH"
        echo "" >> "$OUTPUT_PATH"
      done
    done
  fi
elif [ "$STRUCTURE_TYPE" = "custom" ]; then
  # Read custom order from file
  if [ -f "$LANGUAGE_DIR/.custom-order" ]; then
    while IFS= read -r FILE; do
      if [ -f "$LANGUAGE_DIR/$FILE" ]; then
        echo "Adding section from $LANGUAGE_DIR/$FILE (custom order)"
        echo "" >> "$OUTPUT_PATH"
        echo "<!-- Start of section: $FILE -->" >> "$OUTPUT_PATH"
        echo "" >> "$OUTPUT_PATH"
        # Remove YAML front matter if present and append content
        sed -n '/^---$/,/^---$/!p' "$LANGUAGE_DIR/$FILE" | sed '/./,$!d' >> "$OUTPUT_PATH"
        echo "" >> "$OUTPUT_PATH"
        echo "" >> "$OUTPUT_PATH"
      fi
    done < "$LANGUAGE_DIR/.custom-order"
  else
    echo "Custom order specified but no .custom-order file found"
    exit 1
  fi
else
  # Flat structure: process all markdown files in alphabetical order
  FILES=$(find "$LANGUAGE_DIR" -maxdepth 1 -name "*.md" | sort)
  for FILE in $FILES; do
    echo "Adding section from $FILE"
    echo "" >> "$OUTPUT_PATH"
    echo "<!-- Start of section: $(basename "$FILE") -->" >> "$OUTPUT_PATH"
    echo "" >> "$OUTPUT_PATH"
    # Remove YAML front matter if present and append content
    sed -n '/^---$/,/^---$/!p' "$FILE" | sed '/./,$!d' >> "$OUTPUT_PATH"
    echo "" >> "$OUTPUT_PATH"
    echo "" >> "$OUTPUT_PATH"
  done
fi

# Process appendices if they exist, ensuring numeric sorting
APPENDICES_DIR="../book/$LANGUAGE/appendices"
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
GLOSSARY_FILE="../book/$LANGUAGE/glossary.md"
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
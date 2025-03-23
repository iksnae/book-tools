#!/bin/bash

# combine-markdown.sh - Combines multiple markdown files into a single file
# Usage: combine-markdown.sh [language] [output_file] [book_title] [book_subtitle]

set -e  # Exit on error

# Get parameters
LANGUAGE=${1:-en}
OUTPUT_FILE=${2:-build/book.md}
BOOK_TITLE=${3:-"My Book"}
BOOK_SUBTITLE=${4:-"A Book Built with the Template System"}

echo "📝 Combining markdown files for language: $LANGUAGE"
echo "  Output file: $OUTPUT_FILE"
echo "  Book title: $BOOK_TITLE"

# Ensure the book directory for this language exists
if [ ! -d "book/$LANGUAGE" ]; then
  echo "⚠️ Error: Language directory book/$LANGUAGE doesn't exist!"
  exit 1
fi

# Create build directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Start with front matter and metadata
cat > "$OUTPUT_FILE" << EOF
---
title: "$BOOK_TITLE"
subtitle: "$BOOK_SUBTITLE"
author: "$BOOK_AUTHOR"
date: "$(date +"%B %Y")"
language: "$LANGUAGE"
---

EOF

# First, check if we have a front matter file
if [ -f "book/$LANGUAGE/00-front-matter.md" ]; then
  echo "Found front matter file, adding to output..."
  # Skip YAML front matter if it exists
  if grep -q "^---" "book/$LANGUAGE/00-front-matter.md"; then
    # Extract content after front matter
    sed -n '/^---/,/^---/!p;//{/^---/!p}' "book/$LANGUAGE/00-front-matter.md" >> "$OUTPUT_FILE"
  else
    # No front matter, append directly
    cat "book/$LANGUAGE/00-front-matter.md" >> "$OUTPUT_FILE"
  fi
else
  echo "No front matter file found, creating default..."
  cat >> "$OUTPUT_FILE" << EOF
# $BOOK_TITLE

## $BOOK_SUBTITLE

By $BOOK_AUTHOR

---

EOF
fi

# Add a page break
echo -e "\n\\pagebreak\n" >> "$OUTPUT_FILE"

# Process ToC if it exists
if [ -f "book/$LANGUAGE/00-toc.md" ]; then
  echo "Found ToC file, adding to output..."
  cat "book/$LANGUAGE/00-toc.md" >> "$OUTPUT_FILE"
  echo -e "\n\\pagebreak\n" >> "$OUTPUT_FILE"
else
  echo "No ToC file found, generating a placeholder..."
  cat >> "$OUTPUT_FILE" << EOF
# Table of Contents

<!-- This is a placeholder. The table of contents will be generated automatically. -->

\\tableofcontents

\\pagebreak

EOF
fi

# Find all chapter directories, sort them alphabetically
CHAPTER_DIRS=$(find "book/$LANGUAGE" -type d -name "chapter-*" | sort)
CHAPTER_COUNT=$(echo "$CHAPTER_DIRS" | wc -l)

if [ -z "$CHAPTER_DIRS" ]; then
  echo "⚠️ Warning: No chapter directories found in book/$LANGUAGE/"
  # If we don't have chapters, look for markdown files directly
  MARKDOWN_FILES=$(find "book/$LANGUAGE" -maxdepth 1 -name "*.md" | grep -v "00-front-matter.md" | grep -v "00-toc.md" | sort)
  if [ -n "$MARKDOWN_FILES" ]; then
    echo "Found $(echo "$MARKDOWN_FILES" | wc -l) markdown files directly in book/$LANGUAGE/"
    echo "$MARKDOWN_FILES" | while read -r file; do
      echo "Processing $file..."
      
      # Add a chapter title from the filename
      filename=$(basename "$file" .md)
      chapter_title=$(echo "$filename" | sed 's/^[0-9]*-//' | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')
      
      # Skip if it's a special file
      if [[ "$filename" == "00-"* ]]; then
        continue
      fi
      
      echo -e "\n# $chapter_title\n" >> "$OUTPUT_FILE"
      
      # Add the content
      cat "$file" >> "$OUTPUT_FILE"
      echo -e "\n\\pagebreak\n" >> "$OUTPUT_FILE"
    done
  else
    echo "⚠️ Error: No markdown files found in book/$LANGUAGE/"
    exit 1
  fi
else
  echo "Found $CHAPTER_COUNT chapter directories"
  
  # Process each chapter directory
  echo "$CHAPTER_DIRS" | while read -r chapter_dir; do
    chapter_name=$(basename "$chapter_dir")
    echo "Processing chapter: $chapter_name"
    
    # Extract chapter number and title
    chapter_number=$(echo "$chapter_name" | sed 's/chapter-\([0-9]*\).*/\1/')
    
    # Find the introduction file to get the chapter title
    if [ -f "$chapter_dir/00-introduction.md" ]; then
      chapter_title=$(head -n 1 "$chapter_dir/00-introduction.md" | sed 's/^# *//')
    else
      # Fallback to a generated title if introduction file is missing
      chapter_title="Chapter $chapter_number"
    fi
    
    # Add the chapter number and title to the output, but only once
    echo -e "\n# Chapter $chapter_number: $chapter_title\n" >> "$OUTPUT_FILE"
    
    # Process all markdown files in the chapter directory
    find "$chapter_dir" -maxdepth 1 -name "*.md" | sort | while read -r file; do
      filename=$(basename "$file")
      
      echo "  Adding $filename..."
      
      # For introduction files, skip the title since we already added it
      if [[ "$filename" == "00-introduction.md" ]]; then
        # Skip the first line (the title) and add the rest
        sed '1d' "$file" >> "$OUTPUT_FILE"
      else
        # For other files, add everything
        cat "$file" >> "$OUTPUT_FILE"
      fi
      
      # Add a newline after each file
      echo -e "\n" >> "$OUTPUT_FILE"
    done
    
    # Add a page break after each chapter
    echo -e "\\pagebreak\n" >> "$OUTPUT_FILE"
  done
fi

# Add appendices if they exist
APPENDIX_DIRS=$(find "book/$LANGUAGE" -type d -name "appendix-*" | sort)
if [ -n "$APPENDIX_DIRS" ]; then
  echo "Found appendix directories, processing..."
  
  # Add appendix header
  echo -e "\n# Appendices\n" >> "$OUTPUT_FILE"
  
  echo "$APPENDIX_DIRS" | while read -r appendix_dir; do
    appendix_name=$(basename "$appendix_dir")
    echo "Processing appendix: $appendix_name"
    
    # Extract appendix letter
    appendix_letter=$(echo "$appendix_name" | sed 's/appendix-\(.\).*/\1/' | tr '[:lower:]' '[:upper:]')
    
    # Find the introduction file to get the appendix title
    if [ -f "$appendix_dir/00-introduction.md" ]; then
      appendix_title=$(head -n 1 "$appendix_dir/00-introduction.md" | sed 's/^# *//')
    else
      # Fallback to a generated title if introduction file is missing
      appendix_title="Appendix $appendix_letter"
    fi
    
    # Add the appendix letter and title to the output
    echo -e "\n## Appendix $appendix_letter: $appendix_title\n" >> "$OUTPUT_FILE"
    
    # Process all markdown files in the appendix directory
    find "$appendix_dir" -maxdepth 1 -name "*.md" | sort | while read -r file; do
      filename=$(basename "$file")
      
      echo "  Adding $filename..."
      
      # For introduction files, skip the title since we already added it
      if [[ "$filename" == "00-introduction.md" ]]; then
        # Skip the first line (the title) and add the rest
        sed '1d' "$file" >> "$OUTPUT_FILE"
      else
        # For other files, add everything
        cat "$file" >> "$OUTPUT_FILE"
      fi
      
      # Add a newline after each file
      echo -e "\n" >> "$OUTPUT_FILE"
    done
    
    # Add a page break after each appendix
    echo -e "\\pagebreak\n" >> "$OUTPUT_FILE"
  done
fi

# Check if the combined markdown file was created successfully
if [ -f "$OUTPUT_FILE" ]; then
  file_size=$(du -h "$OUTPUT_FILE" | cut -f1)
  echo "✅ Successfully created combined markdown file: $OUTPUT_FILE ($file_size)"
else
  echo "⚠️ Error: Failed to create combined markdown file!"
  exit 1
fi
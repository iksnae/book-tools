#!/bin/bash

# load-config.sh - Loads and validates book configuration

set -e  # Exit on error

# Default values
BOOK_TITLE=${BOOK_TITLE:-"Untitled Book"}
BOOK_AUTHOR=${BOOK_AUTHOR:-"Unknown Author"}
BOOK_LANGUAGE=${BOOK_LANGUAGE:-"en"}
BOOK_VERSION=${BOOK_VERSION:-"1.0.0"}

# Load from book.yaml if it exists
if [ -f "book.yaml" ]; then
    if [ "$VERBOSE" = true ]; then
        echo "📖 Loading configuration from book.yaml"
    fi
    
    # Extract values using grep and sed
    YAML_TITLE=$(grep '^title:' book.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/\"//g' || echo "")
    YAML_AUTHOR=$(grep '^author:' book.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/\"//g' || echo "")
    YAML_LANGUAGE=$(grep '^language:' book.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/\"//g' || echo "")
    YAML_VERSION=$(grep '^version:' book.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | sed 's/\"//g' || echo "")
    
    # Update values if found in yaml
    [ ! -z "$YAML_TITLE" ] && BOOK_TITLE="$YAML_TITLE"
    [ ! -z "$YAML_AUTHOR" ] && BOOK_AUTHOR="$YAML_AUTHOR"
    [ ! -z "$YAML_LANGUAGE" ] && BOOK_LANGUAGE="$YAML_LANGUAGE"
    [ ! -z "$YAML_VERSION" ] && BOOK_VERSION="$YAML_VERSION"
fi

# Export the configuration
export BOOK_TITLE
export BOOK_AUTHOR
export BOOK_LANGUAGE
export BOOK_VERSION

if [ "$VERBOSE" = true ]; then
    echo "📚 Book Configuration:"
    echo "  Title: $BOOK_TITLE"
    echo "  Author: $BOOK_AUTHOR"
    echo "  Language: $BOOK_LANGUAGE"
    echo "  Version: $BOOK_VERSION"
fi
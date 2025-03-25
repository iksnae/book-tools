#!/bin/bash

# build-language.sh - Builds book content for a specific language

set -e  # Exit on error

# Get the language from the first argument
LANG="$1"
if [ -z "$LANG" ]; then
    echo "❌ Error: Language parameter is required"
    exit 1
fi

if [ "$VERBOSE" = true ]; then
    echo "🔨 Building content for language: $LANG"
fi

# Ensure the language directory exists
if [ ! -d "book/$LANG" ]; then
    echo "❌ Error: Language directory book/$LANG does not exist"
    exit 1
fi

# Create build directory for this language
mkdir -p "build/$LANG"
mkdir -p "build/$LANG/images"

# Copy images from various locations
if [ "$VERBOSE" = true ]; then
    echo "🖼️ Setting up images..."
fi

# Copy placeholder image for missing images
cp "book/$LANG/images/placeholder.svg" "build/$LANG/images/" || {
    echo "⚠️ Warning: Could not copy placeholder image"
}

# Copy all available images
for img in $(find "book/$LANG/images" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.svg" \)); do
    cp "$img" "build/$LANG/images/" || {
        echo "⚠️ Warning: Could not copy image $img"
    }
done

# Create symlinks for missing images to placeholder
cd "build/$LANG/images"
for img in hesitant-beginner.jpg reflection-notebook.jpg first-conversation.jpg kitchen-analogy.jpg \
           human-ai-partnership.jpg teacher-example.jpg prompt-template.jpg simple-interface.jpg \
           purpose-meaning.jpg artist-example.jpg information-processing.jpg director-assistant.jpg \
           bakery-example.jpg senior-genealogy.jpg pattern-matcher.jpg echo-chamber.jpg \
           foreign-cookbook.jpg probability-prediction.jpg human-judgment.jpg director-mindset.jpg \
           specific-direction.jpg critical-evaluation.jpg teacher-curriculum.jpg text-generation.jpg \
           hallucination.jpg ai-misconceptions.jpg verification-principle.jpg directing-process.jpg \
           hands-on-learning.jpg prompt-specificity.jpg identify-challenge.jpg testing-limitations.jpg \
           creative-control.jpg personal-guidelines.jpg moving-forward.jpg director-clapperboard.jpg \
           chatgpt-interface.jpg prompt-anatomy.jpg context-window.jpg; do
    if [ ! -f "$img" ]; then
        ln -sf placeholder.svg "$img" || {
            echo "⚠️ Warning: Could not create symlink for $img"
        }
    fi
done
cd - > /dev/null

# Copy markdown files
if [ "$VERBOSE" = true ]; then
    echo "📝 Copying markdown files..."
fi

# First check if there are any markdown files
MD_FILES=$(find "book/$LANG" -maxdepth 1 -name "*.md" | wc -l)
if [ "$MD_FILES" -eq 0 ]; then
    echo "❌ Error: No markdown files found in book/$LANG"
    exit 1
fi

# Copy the files
cp "book/$LANG"/*.md "build/$LANG/" || {
    echo "❌ Error copying markdown files"
    exit 1
}

if [ "$VERBOSE" = true ]; then
    echo "✅ Found and copied $MD_FILES markdown files"
    ls -l "build/$LANG"/*.md
fi

# Build HTML version
if [ "$SKIP_HTML" != true ]; then
    if [ "$VERBOSE" = true ]; then
        echo "🌐 Building HTML version..."
    fi
    pandoc "build/$LANG"/*.md \
        --from markdown \
        --to html5 \
        --output "build/$LANG/$BOOK_TITLE-$LANG.html" \
        --standalone \
        --toc \
        --toc-depth=3 \
        --resource-path="build/$LANG/images:build/images:build/$LANG/images" \
        --css=styles/book.css || {
            echo "❌ Error building HTML version"
            exit 1
        }
fi

# Build PDF version
if [ "$SKIP_PDF" != true ]; then
    if [ "$VERBOSE" = true ]; then
        echo "📄 Building PDF version..."
    fi
    pandoc "build/$LANG"/*.md \
        --from markdown \
        --to pdf \
        --output "build/$LANG/$BOOK_TITLE-$LANG.pdf" \
        --toc \
        --toc-depth=3 \
        --resource-path="build/$LANG/images:build/images:build/$LANG/images" \
        --pdf-engine=xelatex \
        -V geometry:margin=1in \
        -V documentclass=report \
        -V papersize=letter \
        -V fontsize=11pt || {
            echo "❌ Error building PDF version"
            exit 1
        }
fi

# Build EPUB version
if [ "$SKIP_EPUB" != true ]; then
    if [ "$VERBOSE" = true ]; then
        echo "📱 Building EPUB version..."
    fi
    pandoc "build/$LANG"/*.md \
        --from markdown \
        --to epub \
        --output "build/$LANG/$BOOK_TITLE-$LANG.epub" \
        --toc \
        --toc-depth=3 \
        --resource-path="build/$LANG/images:build/images:build/$LANG/images" \
        --epub-cover-image="build/images/cover.jpg" || {
            echo "❌ Error building EPUB version"
            exit 1
        }
fi

# Build MOBI version if not skipped and calibre is available
if [ "$SKIP_MOBI" != true ] && command -v ebook-convert >/dev/null; then
    if [ "$VERBOSE" = true ]; then
        echo "📱 Building MOBI version..."
    fi
    ebook-convert "build/$LANG/$BOOK_TITLE-$LANG.epub" \
        "build/$LANG/$BOOK_TITLE-$LANG.mobi" || {
            echo "⚠️ Warning: Error building MOBI version"
        }
elif [ "$SKIP_MOBI" != true ]; then
    echo "⚠️ Skipping MOBI: calibre not installed"
fi

# Build DOCX version
if [ "$SKIP_DOCX" != true ]; then
    if [ "$VERBOSE" = true ]; then
        echo "📄 Building DOCX version..."
    fi
    
    # Look for a reference document
    REFERENCE_DOC=""
    if [ -f "templates/docx/reference.docx" ]; then
        REFERENCE_DOC="--reference-doc=templates/docx/reference.docx"
    elif [ -f "resources/templates/docx/reference.docx" ]; then
        REFERENCE_DOC="--reference-doc=resources/templates/docx/reference.docx"
    fi

    # Build DOCX with reference if available
    pandoc "build/$LANG"/*.md \
        --from markdown \
        --to docx \
        --output "build/$LANG/$BOOK_TITLE-$LANG.docx" \
        --toc \
        --toc-depth=3 \
        --resource-path="build/$LANG/images:build/images:build/$LANG/images" \
        $REFERENCE_DOC || {
            echo "❌ Error building DOCX version"
            exit 1
        }
fi

if [ "$VERBOSE" = true ]; then
    echo "✅ Build completed for language: $LANG"
    ls -lh "build/$LANG"
fi
# Book Tools

A collection of tools for building books in multiple formats (PDF, EPUB, MOBI, HTML) from markdown files.

## Overview

This project provides shell scripts for building books from markdown files using Pandoc and other tools. The scripts handle:

- Combining markdown files into a single document
- Converting markdown to PDF, EPUB, MOBI, and HTML formats
- Supporting multiple languages
- Building books with proper metadata

## Getting Started

### Prerequisites

- **Pandoc** - For markdown conversion
- **LaTeX** - For PDF generation
- **Kindlegen** (optional) - For MOBI generation
- **Calibre** (optional) - Alternative for MOBI generation

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/book-tools.git
   cd book-tools
   ```

2. Make the scripts executable:
   ```bash
   cd src
   ./make-scripts-executable.sh
   ```

### Creating a New Book

To create a new book project with the proper directory structure and sample files:

```bash
./src/scripts/create-book.sh my-awesome-book
```

This will create a new directory with the specified name containing all the necessary files and directories to get started. You can also specify a language:

```bash
./src/scripts/create-book.sh my-awesome-book es
```

For a completely self-contained book project with its own scripts:

```bash
./src/scripts/create-book.sh my-awesome-book --copy-scripts
```

### Building a Book

To build a book in various formats:

1. Create a book with the directory structure according to the guidelines (see below)
2. Create a `book.yaml` configuration file
3. Run the build script:
   ```bash
   ./src/scripts/build.sh
   ```

## Directory Structure

The scripts expect the following directory structure:

```
your-book-project/
├── book.yaml           # Book configuration
├── book/               # Source content
│   ├── en/             # English content
│   │   ├── 01-chapter-one/  # Chapter directories
│   │   │   ├── 01-section.md
│   │   │   └── 02-section.md
│   │   ├── 02-chapter-two/
│   │   ├── appendices/     # Optional appendices
│   │   ├── glossary.md     # Optional glossary
│   │   └── images/         # Language-specific images
│   └── es/             # Spanish content (similar structure)
├── resources/          # Resources directory
│   ├── templates/      # Custom templates
│   ├── css/            # CSS files for HTML/EPUB
│   └── images/         # Common images
└── build/              # Output directory (created automatically)
```

## Configuration

Create a `book.yaml` file with the following structure:

```yaml
title: "Your Book Title"
subtitle: "Your Book Subtitle"
author: "Your Name"
publisher: "Your Publisher"
rights: "Copyright © 2023"
description: "A description of your book."
languages: [en, es, fr]  # Languages to build

# PDF Settings
pdf:
  enabled: true
  fontsize: 12pt
  papersize: letter  # a4, letter, etc.
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
```

## Testing

To test the system with a sample book:

```bash
cd src
./test-build.sh
```

This creates a test book project and runs the build process.

## Advanced Options

For more advanced options and configuration, see the [Script Documentation](src/README.md).

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by the [iksnae/book-template](https://github.com/iksnae/book-template) repository
- Uses [Pandoc](https://pandoc.org/) for document conversion
# Book Tools

A powerful and flexible toolkit for creating and managing multi-format, multi-language books. Build beautiful books in PDF, EPUB, MOBI, HTML, and DOCX formats from markdown files, with support for multiple languages, chapters, and advanced formatting options.

## Overview

Book Tools provides a comprehensive suite of tools for book creation and management:

- **Multi-format Output**: Generate books in PDF, EPUB, MOBI, HTML, and DOCX formats
- **Language Support**: Build books in multiple languages with parallel content structures
- **Chapter Management**: Create and organize chapters with automatic numbering and structure
- **Smart Building**: Intelligent build system that only processes changed content
- **Verbose Mode**: Detailed output options for debugging and progress tracking
- **Docker Support**: Containerized building with all dependencies included
- **GitHub Actions**: Built-in CI/CD workflows for automated builds and releases

This project provides shell scripts for building books from markdown files using Pandoc and other tools. The scripts handle:

- Combining markdown files into a single document
- Converting markdown to PDF, EPUB, MOBI, HTML, and DOCX formats
- Supporting multiple languages
- Building books with proper metadata

## Getting Started

### Prerequisites

- **Docker** (recommended) - For containerized building with all dependencies included
- **OR**
- **Pandoc** - For markdown conversion
- **LaTeX** - For PDF generation
- **Kindlegen** (optional) - For MOBI generation
- **Calibre** (optional) - Alternative for MOBI generation

> **Note:** For CI/CD pipelines and GitHub Actions, we recommend using the `iksnae/book-builder` Docker image which contains all required dependencies.

### Installation

#### Option 1: CLI Installation (Recommended)

Install the book-tools CLI with a single command:

```bash
curl -sSL https://raw.githubusercontent.com/iksnae/book-tools/main/install.sh | bash
```

This will:
1. Download the book-tools repository to `~/.book-tools`
2. Create a `book-tools` command in `~/.local/bin`
3. Make all scripts executable

After installation, you can use book-tools from anywhere:

```bash
# Create a new book
book-tools create my-awesome-book

# Build a book
book-tools build
```

#### Option 2: Manual Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/iksnae/book-tools.git
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
# Using the CLI
book-tools create my-awesome-book

# OR, if manually installed
./src/scripts/create-book.sh my-awesome-book
```

This will create a new directory with the specified name containing all the necessary files and directories to get started. You can also specify a language:

```bash
book-tools create my-awesome-book es
```

For a completely self-contained book project with its own scripts:

```bash
book-tools create my-awesome-book --copy-scripts
```

### Creating Chapters

You can create new chapters using the CLI:

```bash
# Create a new chapter
book-tools create-chapter -n 01 -t "Introduction" -l en

# Or use interactive mode
book-tools create-chapter
```

The create-chapter command will:
1. Create a new chapter directory with proper numbering
2. Set up the initial markdown files
3. Add the chapter to the book's structure

### Build Options

When building your book, you can use various options:

```bash
# Build with verbose output
book-tools build --verbose

# Build specific formats
book-tools build pdf
book-tools build epub
book-tools build all

# Build with Docker
book-tools build-docker --verbose
```

The verbose mode provides detailed output about:
- File processing steps
- Build progress
- Error details
- Resource usage

### Building a Book

To build a book in various formats:

1. Create a book with the directory structure according to the guidelines (see below)
2. Create a `book.yaml` configuration file
3. Run the build script:
   ```bash
   # Using the CLI
   book-tools build
   
   # OR, if manually installed
   ./src/scripts/build.sh
   ```

#### Using Docker (Recommended)

The easiest way to build your book is using Docker, which includes all required dependencies:

```bash
# Using the CLI
book-tools build-docker

# OR, if manually installed
./docker-build.sh
```

This uses the `iksnae/book-builder` Docker image that contains all necessary dependencies including Pandoc, LaTeX, Kindlegen, and Calibre.

> **Note for Apple Silicon (M1/M2) users:** The Docker image may require platform emulation. The script will automatically detect this and apply the necessary settings.

## GitHub Actions Integration

This project includes GitHub Actions workflows that automate the build and release process:

### Automated Builds
The build workflow automatically builds the book on pushes to any branch and pull requests when book content changes. This includes:

- Building whenever content in the `book/` directory changes
- Building when templates, styles, or build scripts are modified
- Generating all formats (PDF, EPUB, HTML, MOBI, DOCX)
- Uploading build artifacts for review
- Creating detailed build summaries

You can also manually trigger builds from the Actions tab in your GitHub repository.

### Creating Releases
To create a new release:

1. Run the provided release script:
   ```
   ./tag-release.sh v1.0.0
   ```
   
   This will create and push a new git tag, which automatically triggers the release workflow.

   For CI/CD pipelines, you can use the `--force` option to skip confirmation:
   ```
   ./tag-release.sh v1.0.0 --force
   ```

2. Alternatively, manually create and push a tag with a version number:
   ```
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

3. The release workflow will:
   - Build the book in all formats
   - Create a GitHub release with release notes
   - Attach the built books as release assets
   - Deploy to GitHub Pages for web reading

You can also manually trigger a release from the Actions tab in your GitHub repository.

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
  
# DOCX Settings
docx:
  enabled: true
  reference_doc: "resources/templates/docx/reference.docx"  # Optional reference document
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

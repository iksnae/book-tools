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

#### GitHub Actions Integration

This project includes a GitHub Actions workflow that automatically builds your book whenever changes are pushed. To use it:

1. Push your book project to GitHub
2. The workflow will automatically run on each push to the `main` branch
3. You can also manually trigger builds with specific options via the Actions tab
4. Built files are available as workflow artifacts

The GitHub Actions workflow uses the same `iksnae/book-builder` Docker image, ensuring consistent builds across all environments.

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
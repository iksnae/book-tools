# Book Tools 📚

> A powerful toolkit for creating and managing multi-format, multi-language books

Book Tools helps you create beautiful books in multiple formats (PDF, EPUB, MOBI, HTML, DOCX) from markdown files, with support for multiple languages, chapters, and advanced formatting options.

## ✨ Key Features

- 📦 **Multi-format Output**: Generate books in PDF, EPUB, MOBI, HTML, and DOCX
- 🌍 **Language Support**: Build books in multiple languages with parallel content
- 📑 **Chapter Management**: Create and organize chapters with automatic numbering
- 🔄 **Smart Building**: Only process changed content for faster builds
- 🐳 **Docker Support**: Containerized building with all dependencies included
- 🔧 **GitHub Actions**: Built-in CI/CD workflows for automated builds
- 📝 **Markdown-based**: Write in plain text with rich formatting options
- 🎨 **Customizable**: Templates, styles, and formatting options
- 📱 **Mobile-friendly HTML**: Responsive design for better reading on all devices

## Overview

Book Tools provides a comprehensive suite of tools for book creation and management:

- **Multi-format Output**: Generate books in PDF, EPUB, MOBI, HTML, and DOCX formats
- **Language Support**: Build books in multiple languages with parallel content structures
- **Chapter Management**: Create and organize chapters with automatic numbering and structure
- **Smart Building**: Intelligent build system that only processes changed content
- **Verbose Mode**: Detailed output options for debugging and progress tracking
- **Docker Support**: Containerized building with all dependencies included
- **GitHub Actions**: Built-in CI/CD workflows for automated builds and releases
- **Mobile-friendly HTML**: Responsive output with image scaling for better reading on all devices

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
   
   # Build a book from a specific path
   book-tools build /path/to/your/book
   
   # OR, if manually installed
   ./src/scripts/build.sh
   ```

> **Note**: If you run the build command without a path and no `book.yaml` is found in the current directory or any parent directory, the system will use the current directory as the project root and automatically create a default `book.yaml` and sample chapter structure.

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

The `book.yaml` file controls all aspects of your book build:

```yaml
# Book metadata
title: "Your Book Title"
subtitle: "An optional subtitle"
author: "Your Name"
publisher: "Publisher Name"
year: "2025"
language: "en"  # Main language code

# File naming
file_prefix: "your-book"  # Used for output filenames (e.g., your-book.pdf)

# Output formats to generate
formats:
  pdf: true
  epub: true
  mobi: true
  html: true
  docx: true
  
# Languages to build
languages:
  - "en"
  - "es"  # Uncomment to enable Spanish
  
# Format-specific settings
pdf:
  paperSize: "letter"
  marginTop: "1in"
  fontSize: "11pt"
  lineHeight: "1.5"
  
epub:
  coverImage: "book/images/cover.png"
  css: "templates/epub/style.css"
  
html:
  responsive: true  # Enable/disable mobile-friendly features
```

### File Naming

The `file_prefix` setting in your `book.yaml` controls the filenames of your generated book files. For example, if you set:

```yaml
file_prefix: "my-awesome-book"
```

Your output files will be named:
- `my-awesome-book.pdf`
- `my-awesome-book.epub`
- `my-awesome-book.mobi`
- `my-awesome-book.html`
- `my-awesome-book.docx`

If not specified, the default behavior is to use `book` as the file prefix.

## Mobile-Friendly HTML

The HTML output is now mobile-friendly by default, with responsive features that make your book look great on all devices. Key features include:

- Viewport meta tag for proper scaling on mobile devices
- Responsive image handling with automatic scaling to fit screen width
- Media queries for different device sizes

For more details, see the [Mobile-Friendly HTML documentation](docs/mobile-friendly-html.md).

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
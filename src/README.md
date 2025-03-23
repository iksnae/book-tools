# Book Building Scripts

This directory contains shell scripts for building books in multiple formats (PDF, EPUB, MOBI, HTML) from markdown files.

## Setup

First, make the scripts executable:

```bash
./make-scripts-executable.sh
```

## Structure

The scripts are organized as follows:

- `scripts/build.sh` - Main entry point for building books
- `scripts/setup.sh` - Prepares the environment for building
- `scripts/build-language.sh` - Builds all formats for a specific language
- `scripts/combine-markdown.sh` - Combines markdown files into a single file
- `scripts/generate-pdf.sh` - Generates PDF output
- `scripts/generate-epub.sh` - Generates EPUB output
- `scripts/generate-mobi.sh` - Generates MOBI output (Kindle)
- `scripts/create-book.sh` - Creates a new book template

## Usage

### Creating a New Book

To create a new book project with all necessary files and structure:

```bash
./scripts/create-book.sh my-book-name [language]
```

This will create a new directory with the proper structure and sample files to get started.

If you want to include a copy of all book-tools scripts in the new book project (so it can be self-contained):

```bash
./scripts/create-book.sh my-book-name [language] --copy-scripts
```

### Basic Usage

To build a book in all formats for all languages:

```bash
./scripts/build.sh
```

### Building Specific Languages

To build only specific languages:

```bash
./scripts/build.sh --languages=en,es
```

### Skipping Formats

To skip specific output formats:

```bash
./scripts/build.sh --skip=pdf,mobi
```

### Using an Alternative Config

To use a non-default configuration file:

```bash
./scripts/build.sh --config=custom-book.yaml
```

## Prerequisites

The scripts require the following tools to be installed:

- **Pandoc** - For markdown conversion and ebook generation
- **LaTeX** - For PDF generation
- **Kindlegen** (optional) - For MOBI generation
- **Calibre** (optional) - Alternative for MOBI generation

To install dependencies automatically (where possible):

```bash
./scripts/setup.sh --install-deps
```

## Directory Structure

The scripts expect the following directory structure:

```
.
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

## Output

The build process generates files in the `build` directory, organized by language. 
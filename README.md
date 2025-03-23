# Book Tools

A comprehensive CLI and utility package for building books in multiple formats from markdown sources. This package extracts the book-building tools from the [book-template](https://github.com/iksnae/book-template) project.

## Features

- Build books from Markdown source files
- Support for multiple languages and formats (PDF, EPUB, MOBI, HTML)
- Interactive CLI with friendly user experience
- Structured chapter creation and management
- Configurable via YAML

## Installation

```bash
# Global installation
npm install -g book-tools

# Local installation
npm install book-tools
```

## CLI Usage

```bash
# Build book in all formats
book build

# Build book with interactive prompts
book interactive

# Create a new chapter
book create-chapter

# Check chapter structure
book check-chapter

# Display book information
book info

# Clean build artifacts
book clean
```

## API Usage

```javascript
const bookTools = require('book-tools');

// Build a book
bookTools.build({
  allLanguages: true,
  skipPdf: false,
  skipEpub: false,
  skipMobi: false,
  skipHtml: false
});

// Create a chapter
bookTools.createChapter({
  number: '04',
  title: 'My New Chapter',
  language: 'en'
});
```

## Project Structure

Your book project should follow this structure:

```
my-book/
├── book.yaml          # Configuration file
├── book/              # Markdown source files
│   ├── en/            # English content
│   │   ├── chapter-01/
│   │   │   ├── 00-introduction.md
│   │   │   ├── 01-section.md
│   │   │   └── images/
│   │   └── chapter-02/
│   └── es/            # Spanish content
├── templates/         # Custom templates
└── build/             # Output directory (created automatically)
```

## Configuration

Create a `book.yaml` file in your project root:

```yaml
title: My Book Title
subtitle: An Amazing Book
author: Your Name
file_prefix: my-book
languages:
  - en
  - es
```

## License

MIT
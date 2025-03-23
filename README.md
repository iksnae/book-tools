# Book Tools

A comprehensive CLI and utility package for building books in multiple formats from markdown sources. This package extracts the book-building tools from the [book-template](https://github.com/iksnae/book-template) project.

![Node.js Tests](https://github.com/iksnae/book-tools/workflows/Node.js%20Tests/badge.svg)

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

## Development

### Requirements

- Node.js (v14 or higher)
- Pandoc (for format conversions)
- LaTeX (for PDF generation)
- Kindlegen or Calibre (for MOBI generation)

### Testing

The project uses Jest for testing. Test files are located in the `tests` directory.

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:coverage

# Run tests in watch mode
npm run test:watch
```

### Testing Status

The test suite is currently under development. We've implemented:

- Unit tests for core utility functions
- Basic tests for CLI command structure
- Tests for project configuration loading

We're working on increasing test coverage. If you'd like to contribute, test coverage for the main module functionality would be greatly appreciated.

### GitHub Actions

This project is configured with GitHub Actions for continuous integration:

- Runs tests on Node.js 20.x
- Lints code with ESLint
- Generates test coverage reports
- Provides detailed test run information

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT
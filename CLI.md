# Book-Tools CLI

Book Tools provides a comprehensive command-line interface (CLI) for creating, building, and managing book projects in multiple formats.

## Available Commands

### `book build` - Build the book in various formats

```bash
book build [options]
```

Options:
- `--all-languages` - Build for all configured languages
- `--lang <language>` - Specify language to build (default: "en")
- `--skip-pdf` - Skip PDF generation
- `--skip-epub` - Skip EPUB generation
- `--skip-mobi` - Skip MOBI generation
- `--skip-html` - Skip HTML generation
- `--skip-docx` - Skip DOCX generation
- `--with-recovery` - Enable enhanced error recovery
- `--verbose` - Show verbose output

### `book interactive` - Interactive build process

```bash
book interactive
```

Guides you through an interactive process for building your book.

### `book create-chapter` - Create a new chapter

```bash
book create-chapter [options]
```

Options:
- `-n, --number <number>` - Chapter number (e.g., "01")
- `-t, --title <title>` - Chapter title
- `-l, --lang <language>` - Language code (default: "en")

### `book check-chapter` - Check a chapter structure

```bash
book check-chapter [options]
```

Options:
- `-n, --number <number>` - Chapter number (e.g., "01")
- `-l, --lang <language>` - Language code (default: "en")

### `book info` - Display book information

```bash
book info
```

Shows information about the book configuration, formats, and built files.

### `book clean` - Clean build artifacts

```bash
book clean
```

Removes all build artifacts.

### `book validate` - Check configuration and dependencies

```bash
book validate [options]
```

Options:
- `-c, --config <path>` - Path to configuration file (default: "book.yaml")
- `-f, --fix` - Attempt to fix common issues
- `--verbose` - Show detailed validation information

### `book github-action` - Run as GitHub Action

```bash
book github-action [options]
```

Options:
- `--all-languages` - Build for all configured languages
- `--create-release` - Create GitHub release
- `--no-recovery` - Disable enhanced error recovery

### `book init` - Initialize a new book project (Coming Soon)

```bash
book init [options]
```

Options:
- `-t, --template <template>` - Template to use (basic, academic, technical)
- `-n, --name <name>` - Book name
- `-a, --author <author>` - Author name
- `-l, --languages <languages>` - Comma-separated list of language codes

### `book generate` - Generate a specific format (Coming Soon)

```bash
book generate <format> [options]
```

Options:
- `-l, --lang <language>` - Language to build for
- `-i, --input <path>` - Custom input path
- `-o, --output <path>` - Custom output path
- `-t, --template <path>` - Custom template path

### `book watch` - Watch for changes and rebuild (Coming Soon)

```bash
book watch [options]
```

Options:
- `-l, --lang <language>` - Language to watch
- `-f, --formats <formats>` - Comma-separated formats to build

### `book serve` - Serve built HTML and provide live preview (Coming Soon)

```bash
book serve [options]
```

Options:
- `-p, --port <port>` - Port to serve on
- `-l, --lang <language>` - Language to serve

## Installation

```bash
curl -sSL https://raw.githubusercontent.com/iksnae/book-tools/main/install.sh | bash
```

## Usage Examples

### Building a book in PDF format

```bash
book build --skip-epub --skip-mobi --skip-html --skip-docx
```

### Creating a new chapter

```bash
book create-chapter -n 03 -t "Advanced Techniques" -l en
```

### Validating project setup

```bash
book validate --verbose
```

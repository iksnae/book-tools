# Configuration Guide

This document explains the configuration options available in `book-tools` for customizing your book builds.

## Configuration File

The configuration file `book.yaml` should be placed in the root of your project. It contains all the settings for your book, including metadata, formatting options, and build settings.

## Basic Structure

Here's the basic structure of the configuration file:

```yaml
# Basic Information
title: "Your Book Title"
subtitle: "Optional Subtitle"
author: "Author Name"
publisher: "Publisher Name"
year: "2025"
filePrefix: "your-book-file-prefix"

# Languages
languages:
  - "en"  # English
  # - "es"  # Spanish (optional)

# Output formats
formats:
  pdf: true
  epub: true
  mobi: true
  html: true

# Format-specific settings
formatSettings:
  pdf:
    # PDF settings here
  epub:
    # EPUB settings here
  html:
    # HTML settings here

# Metadata
rights: "Copyright information"
description: "Book description"
keywords: "comma, separated, keywords"
```

## Configuration Sections

### Basic Information

These settings provide the essential information about your book:

| Setting | Description | Default | Required |
|---------|-------------|---------|----------|
| `title` | The title of your book | "Untitled Book" | Yes |
| `subtitle` | A subtitle for your book | "" | No |
| `author` | The author's name | "Unknown Author" | Yes |
| `publisher` | The publisher's name | "" | No |
| `year` | Publication year | Current year | No |
| `filePrefix` | Prefix for output files | Based on title | No |

### Languages

The `languages` setting is an array of language codes (ISO 639-1) that your book supports. At least one language must be specified.

```yaml
languages:
  - "en"  # English (primary language)
  - "es"  # Spanish
  - "fr"  # French
```

### Output Formats

The `formats` section controls which output formats will be generated:

```yaml
formats:
  pdf: true    # Generate PDF
  epub: true   # Generate EPUB
  mobi: true   # Generate MOBI (Kindle)
  html: true   # Generate HTML
```

Set any format to `false` to disable generation of that format.

### Format-Specific Settings

The `formatSettings` section allows detailed customization of each output format.

#### PDF Settings

```yaml
formatSettings:
  pdf:
    paperSize: "letter"  # letter, a4, a5, b5, etc.
    marginTop: "1in"
    marginRight: "1in"
    marginBottom: "1in"
    marginLeft: "1in"
    fontSize: "11pt"
    lineHeight: "1.5"
    template: "templates/pdf/default.latex"  # Custom LaTeX template
```

| Setting | Description | Default |
|---------|-------------|---------|
| `paperSize` | Paper size for PDF | "letter" |
| `marginTop` | Top margin | "1in" |
| `marginRight` | Right margin | "1in" |
| `marginBottom` | Bottom margin | "1in" |
| `marginLeft` | Left margin | "1in" |
| `fontSize` | Base font size | "11pt" |
| `lineHeight` | Line height | "1.5" |
| `template` | Path to custom LaTeX template | "templates/pdf/default.latex" |

#### EPUB Settings

```yaml
formatSettings:
  epub:
    coverImage: "book/images/cover.png"  # Path to cover image
    css: "templates/epub/style.css"      # Custom CSS
    tocDepth: 3                          # Table of contents depth
```

| Setting | Description | Default |
|---------|-------------|---------|
| `coverImage` | Path to cover image | "book/images/cover.png" |
| `css` | Path to custom CSS | "templates/epub/style.css" |
| `tocDepth` | Depth of table of contents | 3 |

#### HTML Settings

```yaml
formatSettings:
  html:
    template: "templates/html/default.html"  # Custom HTML template
    css: "templates/html/style.css"          # Custom CSS
    toc: true                                # Include table of contents
    tocDepth: 3                              # Table of contents depth
    sectionDivs: true                        # Put sections in div elements
    selfContained: true                      # Create standalone HTML
```

| Setting | Description | Default |
|---------|-------------|---------|
| `template` | Path to custom HTML template | "templates/html/default.html" |
| `css` | Path to custom CSS | "templates/html/style.css" |
| `toc` | Include table of contents | true |
| `tocDepth` | Depth of table of contents | 3 |
| `sectionDivs` | Put sections in div elements | true |
| `selfContained` | Create standalone HTML | true |

### Metadata

Additional metadata settings:

```yaml
rights: "Copyright © 2025 Author Name. All rights reserved."
description: "A description of your book for metadata."
keywords: "keyword1, keyword2, keyword3"
```

| Setting | Description | Default |
|---------|-------------|---------|
| `rights` | Copyright information | "" |
| `description` | Book description | "" |
| `keywords` | Keywords for metadata | "" |

## Legacy Format Support

For backward compatibility, `book-tools` also supports the following legacy formats:

### Legacy Formats

```yaml
file_prefix: "legacy-format"  # Instead of filePrefix
outputs:                      # Instead of formats
  pdf: true
  epub: true

pdf:                         # Instead of formatSettings.pdf
  paper_size: "letter"       # Instead of paperSize
  margin_top: "1in"          # Instead of marginTop

epub:                        # Instead of formatSettings.epub
  cover_image: "path/to.png" # Instead of coverImage
```

Both formats are supported, but the new format is recommended for new projects.

## Example Configuration

See the full example configuration in [examples/book.yaml](../examples/book.yaml).

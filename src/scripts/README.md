# Book Tools Scripts

This directory contains the bash scripts that power the book-tools package. These scripts handle the various processes involved in building books from markdown sources.

## Core Scripts

- **build.sh**: Main entry point for the book building process
- **setup.sh**: Checks for required dependencies and sets up the build environment
- **build-language.sh**: Builds a specific language version of the book
- **combine-markdown.sh**: Combines multiple markdown files into a single file

## Format-Specific Scripts

- **generate-pdf.sh**: Generates a PDF from the markdown content
- **generate-epub.sh**: Generates an EPUB from the markdown content
- **generate-html.sh**: Generates HTML from the markdown content
- **generate-mobi.sh**: Converts EPUB to MOBI format (requires kindlegen)

## Usage in Node.js

These scripts are executed from Node.js using the child_process module. The Node.js wrapper provides a user-friendly API for these scripts.

## Dependencies

The scripts have the following dependencies:

- **pandoc**: For markdown conversion
- **LaTeX**: For PDF generation (specifically pdflatex/xelatex)
- **kindlegen**: For MOBI generation (optional)
- **ImageMagick**: For image processing (optional)

The setup.sh script checks for these dependencies and provides appropriate warnings when they're missing.
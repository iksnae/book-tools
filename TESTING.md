# Testing Guide for Book Tools

This guide provides instructions for testing and troubleshooting the book build process.

## Quick Start

Run the test script to verify that all formats are working, including DOCX:

```bash
chmod +x test-build.sh
./test-build.sh
```

This will:
1. Create necessary template directories and files if missing
2. Check for required dependencies
3. Build a sample book with PDF, EPUB, HTML, MOBI, and DOCX formats
4. Show detailed output of the build process

## Testing Specific Formats

To test specific formats only:

```bash
# Test PDF only
./src/scripts/build.sh --skip=epub,html,mobi,docx

# Test EPUB only
./src/scripts/build.sh --skip=pdf,html,mobi,docx

# Test HTML only
./src/scripts/build.sh --skip=pdf,epub,mobi,docx

# Test DOCX only
./src/scripts/build.sh --skip=pdf,epub,html,mobi
```

## Dependencies

The book build process requires the following dependencies:

- **pandoc**: Required for PDF, EPUB, HTML, and DOCX formats
- **kindlegen** or **ebook-convert** (from Calibre): Required for MOBI format

## DOCX-Specific Setup

For DOCX output, you can create a custom reference document:

1. Create a default reference document:
   ```bash
   chmod +x templates/docx/create_reference.sh
   ./templates/docx/create_reference.sh
   ```

2. Or use a custom Word template:
   - Create a Word document with your desired styles
   - Save it as `templates/docx/reference.docx`
   - Update your `book.yaml` to point to this file:
     ```yaml
     docx:
       reference_doc: "templates/docx/reference.docx"
       toc: true
       toc_depth: 3
     ```

## Troubleshooting

If you encounter issues with the build process:

### 1. Enable Debug Mode

```bash
./test-build.sh --debug
```

This will show all the commands being executed during the build.

### 2. Check Template Files

Ensure template files exist and are properly formatted:

```bash
ls -la templates/pdf/
ls -la templates/html/
ls -la templates/epub/
ls -la templates/docx/
```

### 3. Check Book Content

Make sure your book has proper content:

```bash
find book/ -name "*.md" | sort
```

### 4. Examine Build Output

Check the build directory for output files:

```bash
find build/ -type f
```

### 5. Check Script Permissions

Ensure all scripts are executable:

```bash
chmod +x src/scripts/*.sh
chmod +x test-build.sh
chmod +x templates/docx/create_reference.sh
```

## Advanced Testing

### Testing With Docker

To test in a controlled environment:

```bash
docker run -it --rm -v "$PWD:/app" -w /app iksnae/book-builder ./test-build.sh
```

## DOCX Format Tips

When working with DOCX output:

1. **Custom Styles**: You can create a Word document with your preferred styles (headings, paragraphs, etc.) and save it as a reference document.

2. **Style Mapping**: 
   - `# Heading 1` → 'Heading 1' style
   - `## Heading 2` → 'Heading 2' style
   - Regular paragraph → 'Normal' style
   - Code blocks → 'Source Code' style
   - Blockquotes → 'Quote' style

3. **Troubleshooting DOCX Issues**:
   - If DOCX generation fails but other formats work, check if pandoc supports DOCX output:
     ```bash
     pandoc --list-output-formats | grep docx
     ```
   - Ensure you have a valid reference document
   - Try using a simpler reference document
   - Check pandoc version (newer versions have better DOCX support)

## Common Issues

- **Missing Template Files**: The build process will try to create minimal templates if they don't exist, but they might not be suitable for all books.
- **LaTeX Errors in PDF Generation**: If you get LaTeX errors when generating PDFs, check for special characters in your Markdown files.
- **Empty Output Files**: Make sure your Markdown files have valid content and are properly structured.
- **Path Resolution Issues**: Ensure paths in `book.yaml` match your actual directory structure.
- **DOCX Style Issues**: If your DOCX output doesn't match your expectations, you probably need to customize the reference document.

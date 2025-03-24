# Testing Guide for Book Tools

This guide provides instructions for testing and troubleshooting the book build process.

## Quick Start

Run the test script to verify that core formats are working:

```bash
chmod +x test-build.sh
./test-build.sh
```

This will:
1. Create necessary template directories and files if missing
2. Check for required dependencies
3. Build a sample book with PDF, EPUB, HTML, and MOBI formats
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
```

## Dependencies

The book build process requires the following dependencies:

- **pandoc**: Required for PDF, EPUB, HTML, and DOCX formats
- **kindlegen** or **ebook-convert** (from Calibre): Required for MOBI format

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
```

## Advanced Testing

### Testing With Docker

To test in a controlled environment:

```bash
docker run -it --rm -v "$PWD:/app" -w /app iksnae/book-builder ./test-build.sh
```

### Testing DOCX Format (Experimental)

DOCX support is currently experimental. To test it:

1. Enable DOCX output in `book.yaml`:
   ```yaml
   outputs:
     # ...other formats...
     docx: true
   ```

2. Create DOCX template directory:
   ```bash
   mkdir -p templates/docx
   ```

3. Create a reference document (optional):
   ```bash
   pandoc -o templates/docx/reference.docx --print-default-data-file reference.docx
   ```

4. Build with DOCX enabled:
   ```bash
   ./src/scripts/build.sh
   ```

## Common Issues

- **Missing Template Files**: The build process will try to create minimal templates if they don't exist, but they might not be suitable for all books.
- **LaTeX Errors in PDF Generation**: If you get LaTeX errors when generating PDFs, check for special characters in your Markdown files.
- **Empty Output Files**: Make sure your Markdown files have valid content and are properly structured.
- **Path Resolution Issues**: Ensure paths in `book.yaml` match your actual directory structure.

## Next Steps

1. First focus on getting PDF, EPUB, and HTML formats working
2. Add more complex content and test with it
3. Test with multiple languages if needed
4. Only then enable and test DOCX format

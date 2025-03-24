# DOCX Templates

You can place custom DOCX reference templates in this directory to control the styling of your DOCX output.

## Creating a reference DOCX

To create a reference DOCX document:

1. Create a new document in Microsoft Word or compatible application
2. Set up styles for:
   - Headings (H1, H2, H3, etc.)
   - Body text
   - Code blocks
   - Lists
   - Tables
   - Any other styles you want to apply to your document
3. Save the document as 'reference.docx' in this directory

## Using custom reference DOCX

To use a custom reference DOCX, add the following to your book.yaml configuration:

```yaml
docx:
  enabled: true
  reference_doc: "resources/templates/docx/reference.docx"
```

## More information

The DOCX output format uses Pandoc's DOCX writer. For more detailed information about creating reference DOCX files, see the Pandoc documentation:

https://pandoc.org/MANUAL.html#option--reference-doc

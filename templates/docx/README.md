# DOCX Templates

This directory contains DOCX template files used for generating Word documents with pandoc.

## Reference Document

To customize DOCX output, you need to have a `reference.docx` file here. This file serves as a style template for pandoc when generating DOCX files.

## Creating a Reference Document

1. Create a Word document with the styles you want
2. Save it as `reference.docx` in this directory
3. Update your `book.yaml` file to point to this file:

```yaml
docx:
  reference_doc: "templates/docx/reference.docx"
  toc: true
  toc_depth: 3
```

## Default Styles

If no reference document is provided, pandoc will use its default styles. To create a starting reference document, run:

```bash
pandoc -o templates/docx/reference.docx --print-default-data-file reference.docx
```

## Style Mapping

Pandoc maps markdown elements to Word styles as follows:

- `# Heading 1` → 'Heading 1' style
- `## Heading 2` → 'Heading 2' style
- Regular paragraph → 'Normal' style
- Code blocks → 'Source Code' style
- Blockquotes → 'Quote' style

Customizing these styles in your reference document will affect the appearance of your final document.
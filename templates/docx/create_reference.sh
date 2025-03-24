#!/bin/bash

# Create a default reference.docx file for DOCX template
echo "Creating default reference.docx template..."

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
    echo "Error: pandoc is not installed or not in PATH."
    echo "Please install pandoc and try again."
    exit 1
fi

# Create the directory if it doesn't exist
mkdir -p templates/docx

# Generate the default reference document
pandoc -o templates/docx/reference.docx --print-default-data-file reference.docx

if [ $? -eq 0 ]; then
    echo "Successfully created reference.docx in templates/docx/"
    echo "You can now customize this file in Word and save it back to use as your template."
    
    # Get the file size
    SIZE=$(du -h templates/docx/reference.docx | cut -f1)
    echo "File size: $SIZE"
else
    echo "Error: Failed to create reference.docx."
    echo "Please check your pandoc installation."
    exit 1
fi

echo "Done."

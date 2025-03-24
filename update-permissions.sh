#!/bin/bash

# Update permissions on all scripts
set -e

echo "Updating permissions on all script files..."

# Make all shell scripts executable
find . -name "*.sh" -exec chmod +x {} \;

# Make sure the bin scripts are executable too
chmod +x bin/* 2>/dev/null || true

# Create template directories if they don't exist
mkdir -p templates/html templates/pdf templates/epub templates/docx

echo "✅ Updated permissions on all script files"
echo "✅ Created template directories if they didn't exist"

# Run template creation script if it exists and reference.docx doesn't
if [ -f "templates/docx/create_reference.sh" ] && [ ! -f "templates/docx/reference.docx" ]; then
  echo "Running DOCX reference template creation script..."
  ./templates/docx/create_reference.sh
fi

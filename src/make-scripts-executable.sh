#!/bin/bash

# make-scripts-executable.sh - Makes all the scripts executable

# Get the scripts directory
SCRIPTS_DIR="$(dirname "$0")/scripts"

echo "🔧 Making scripts executable..."

# Make all shell scripts executable
chmod +x "$SCRIPTS_DIR"/*.sh

echo "✅ All scripts are now executable!"

# List the scripts that were made executable
echo "📃 Executable scripts:"
ls -l "$SCRIPTS_DIR"/*.sh 
#!/bin/bash

# tag-release.sh - Tags a new release in git and pushes to GitHub
# Usage: ./tag-release.sh [version]

set -e  # Exit on error

# Default to prompting for version if not provided
VERSION=${1:-""}

if [ -z "$VERSION" ]; then
  echo "Enter release version (e.g. v1.0.0):"
  read VERSION
fi

# Validate version format
if ! [[ $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ Invalid version format: $VERSION"
  echo "Version must be in format v1.0.0"
  exit 1
fi

# Check if tag already exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "❌ Tag $VERSION already exists!"
  exit 1
fi

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $BRANCH"

# Confirm with user
echo "About to create tag $VERSION on branch $BRANCH"
echo "Type 'yes' to confirm:"
read CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "❌ Release creation cancelled"
  exit 1
fi

# Create and push tag
echo "Creating tag $VERSION..."
git tag -a "$VERSION" -m "Release $VERSION"

echo "Pushing tag to origin..."
git push origin "$VERSION"

echo "✅ Release $VERSION tagged and pushed to GitHub!"
echo "The release workflow should start automatically."
echo "You can check the status in GitHub Actions." 
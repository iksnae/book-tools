#!/bin/bash

# tag-release.sh - Script to tag a new release in Git and push it to GitHub
# Usage: ./tag-release.sh [version]
# Examples:
#   ./tag-release.sh v1.0.1  # Create tag v1.0.1
#   ./tag-release.sh         # Auto-increments latest patch version

set -e  # Exit on error

# Parse arguments
VERSION=""

for arg in "$@"; do
  if [[ "$arg" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    VERSION="$arg"
  else
    echo "Error: Invalid argument '$arg'"
    echo "Usage: ./tag-release.sh [version]"
    echo "       version format: v1.0.1"
    exit 1
  fi
done

# If version wasn't provided, auto-increment the patch version
if [ -z "$VERSION" ]; then
  # Get latest tag
  LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
  
  # Extract major, minor, and patch numbers
  MAJOR=$(echo $LATEST_TAG | sed -E 's/v([0-9]+)\.([0-9]+)\.([0-9]+)/\1/')
  MINOR=$(echo $LATEST_TAG | sed -E 's/v([0-9]+)\.([0-9]+)\.([0-9]+)/\2/')
  PATCH=$(echo $LATEST_TAG | sed -E 's/v([0-9]+)\.([0-9]+)\.([0-9]+)/\3/')
  
  # Increment patch version
  PATCH=$((PATCH + 1))
  
  # Create new version
  VERSION="v$MAJOR.$MINOR.$PATCH"
  
  echo "Auto-incrementing from $LATEST_TAG to $VERSION"
fi

echo "🏷️ Creating release tag: $VERSION"

# Check if tag already exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "❌ Error: Tag $VERSION already exists."
  echo "   Use 'git tag -d $VERSION && git push origin :refs/tags/$VERSION' to delete it first."
  exit 1
fi

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "📋 Current branch: $BRANCH"

# Create the tag
echo "📌 Creating tag $VERSION..."
git tag -a "$VERSION" -m "Release $VERSION"

# Push the tag
echo "⬆️ Pushing tag to origin..."
git push origin "$VERSION"

echo "✅ Successfully created and pushed tag: $VERSION"
echo "🚀 GitHub Actions workflow should now be triggered to build and release the book."
echo "   Check progress at: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions" 
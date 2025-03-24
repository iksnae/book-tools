#!/bin/bash

# tag-release.sh - Script to tag a new release in Git and push it to GitHub
# Usage: ./tag-release.sh [version] [--force]
# Examples:
#   ./tag-release.sh v1.0.0         # Create tag v1.0.0 with confirmation
#   ./tag-release.sh v1.0.0 --force # Create tag v1.0.0 without confirmation
#   ./tag-release.sh                # Prompt for version

set -e  # Exit on error

# Parse arguments
VERSION=""
FORCE=false

for arg in "$@"; do
  if [[ "$arg" == "--force" ]]; then
    FORCE=true
  elif [[ "$arg" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    VERSION="$arg"
  else
    echo "Error: Invalid argument '$arg'"
    echo "Usage: ./tag-release.sh [version] [--force]"
    echo "       version format: v1.0.0"
    exit 1
  fi
done

# If version wasn't provided, prompt for it
if [ -z "$VERSION" ]; then
  read -p "Enter release version (e.g. v1.0.0): " VERSION
  
  # Validate version format
  if ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format v1.0.0"
    exit 1
  fi
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

# Confirm unless force flag is used
if [[ "$FORCE" != true ]]; then
  read -p "⚠️ Are you sure you want to create tag $VERSION on branch $BRANCH? (y/N): " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "❌ Aborted. No tag created."
    exit 0
  fi
fi

# Create the tag
echo "📌 Creating tag $VERSION..."
git tag -a "$VERSION" -m "Release $VERSION"

# Push the tag
echo "⬆️ Pushing tag to origin..."
git push origin "$VERSION"

echo "✅ Successfully created and pushed tag: $VERSION"
echo "🚀 GitHub Actions workflow should now be triggered to build and release the book."
echo "   Check progress at: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions" 
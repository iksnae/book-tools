#!/bin/bash

# tag-release.sh - Tags a new release in git and pushes to GitHub
# Usage: ./tag-release.sh [version]

set -e  # Exit on error

# Get version from argument or prompt user
if [ $# -eq 0 ]; then
    echo "Enter version tag (e.g., v1.0.0):"
    read VERSION
else
    VERSION="$1"
fi

# Check for force flag
FORCE=false
if [ "$2" == "--force" ] || [ "$1" == "--force" ]; then
    FORCE=true
    if [ "$1" == "--force" ]; then
        VERSION="$2"
    fi
fi

# Validate version format
if ! [[ $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid version format. Please use the format v1.0.0"
    exit 1
fi

# Check if tag already exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo "❌ Tag $VERSION already exists!"
    exit 1
fi

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Confirm action
if [ "$FORCE" != "true" ]; then
    echo "Current branch: $BRANCH"
    echo "About to create tag $VERSION on branch $BRANCH"
    echo "Type 'yes' to confirm:"
    read CONFIRMATION
    if [ "$CONFIRMATION" != "yes" ]; then
        echo "❌ Release creation cancelled"
        exit 1
    fi
fi

# Create and push tag
echo "🏷️ Creating tag $VERSION..."
git tag -a "$VERSION" -m "Release $VERSION"
echo "📤 Pushing tag to origin..."
git push origin "$VERSION"
echo "✅ Successfully created and pushed tag $VERSION!"
echo ""
echo "The release workflow should now be running on GitHub."
echo "Check the Actions tab at https://github.com/$(git config --get remote.origin.url | sed -E 's/.*github.com[:\/](.*)(\.git)?/\1/')/actions" 
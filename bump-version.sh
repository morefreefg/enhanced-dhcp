#!/bin/bash
# Version Bump Script for Enhanced DHCP
# Automatically increments version number

set -e

# Check if VERSION file exists
if [ ! -f "VERSION" ]; then
    echo "❌ VERSION file not found!"
    exit 1
fi

# Read current version
CURRENT_VERSION=$(cat VERSION | tr -d '[:space:]')
echo "📌 Current version: $CURRENT_VERSION"

# Parse version parts (major.minor.patch)
IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"

# Determine bump type
BUMP_TYPE=${1:-patch}

case $BUMP_TYPE in
    major)
        major=$((major + 1))
        minor=0
        patch=0
        ;;
    minor)
        minor=$((minor + 1))
        patch=0
        ;;
    patch)
        patch=$((patch + 1))
        ;;
    *)
        echo "❌ Invalid bump type: $BUMP_TYPE"
        echo "Usage: $0 [major|minor|patch]"
        exit 1
        ;;
esac

# Create new version
NEW_VERSION="$major.$minor.$patch"

# Update VERSION file
echo "$NEW_VERSION" > VERSION

echo "✅ Version bumped: $CURRENT_VERSION → $NEW_VERSION"
echo "📦 Next build will use version: $NEW_VERSION"
echo ""
echo "🚀 Next steps:"
echo "  1. Build: ./build.sh"
echo "  2. Tag:   git tag -a v$NEW_VERSION -m 'Release v$NEW_VERSION'"
echo "  3. Push:  git push origin v$NEW_VERSION"
echo "  4. Release: gh release create v$NEW_VERSION"
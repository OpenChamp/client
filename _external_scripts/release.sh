#!/bin/bash
# Release helper script for OpenChamp
# Usage: ./release.sh v1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if version is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version not provided${NC}"
    echo "Usage: ./release.sh v1.0.0"
    exit 1
fi

VERSION=$1

# Validate version format
if ! [[ $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo -e "${RED}Error: Invalid version format. Use v1.0.0${NC}"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check if the tag already exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo -e "${RED}Error: Tag $VERSION already exists${NC}"
    exit 1
fi

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}Error: You have uncommitted changes. Please commit or stash them first.${NC}"
    exit 1
fi

echo -e "${YELLOW}Creating release $VERSION${NC}"
echo ""

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $CURRENT_BRANCH"

# Generate changelog preview
echo -e "${YELLOW}Recent commits (changelog preview):${NC}"
PREVIOUS_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "$PREVIOUS_TAG" ]; then
    git log --oneline --no-merges -10
else
    git log "$PREVIOUS_TAG..HEAD" --oneline --no-merges
fi

echo ""
echo -e "${YELLOW}About to:${NC}"
echo "1. Create tag: $VERSION"
echo "2. Push tag to origin (triggers CI/CD pipeline)"
echo "3. GitHub Actions will build all exports and create a release"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Cancelled${NC}"
    exit 1
fi

# Create the tag
echo -e "${GREEN}Creating annotated tag...${NC}"
git tag -a "$VERSION" -m "Release $VERSION"

# Push the tag
echo -e "${GREEN}Pushing tag to origin...${NC}"
git push origin "$VERSION"

echo ""
echo -e "${GREEN}✓ Release $VERSION created and pushed!${NC}"
echo -e "${YELLOW}The CI/CD pipeline is now building all exports.${NC}"
echo "View progress at: https://github.com/openchamp/openchamppc/actions"
echo ""
echo "The release will be automatically published once all builds complete."

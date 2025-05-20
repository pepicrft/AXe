#!/bin/bash

set -e

# --- Helper Functions ---
log_info() { echo ""; echo "🔷 $1"; }
log_error() { echo "❌ $1"; exit 1; }
log_success() { echo "✅ $1"; }

# --- Validation ---
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) not found. Please install it first: brew install gh"
fi

if ! gh auth status &> /dev/null; then
    log_error "Not authenticated with GitHub CLI. Please run: gh auth login"
fi

# --- Get version ---
echo "Enter the version for the new release (e.g., 1.0.0):"
read -p "Version: " VERSION

if [ -z "$VERSION" ]; then
    log_error "No version entered. Aborting."
fi

# Validate version format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
    log_error "Invalid version format: '$VERSION'. Must be x.y.z or x.y.z-tag.n (e.g., 1.4.0 or 1.4.0-beta.3)"
fi

TAG_NAME="v$VERSION"

# --- Check if tag already exists ---
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    log_error "Tag $TAG_NAME already exists locally. Please choose a different version."
fi

if git ls-remote --tags origin | grep -q "refs/tags/$TAG_NAME$"; then
    log_error "Tag $TAG_NAME already exists on remote. Please choose a different version."
fi

# --- Get release notes ---
echo ""
echo "Enter release notes (press Ctrl+D when finished):"
RELEASE_NOTES=$(cat)

if [ -z "$RELEASE_NOTES" ]; then
    RELEASE_NOTES="Release $TAG_NAME"
fi

# --- Determine if prerelease ---
PRERELEASE_FLAG=""
if [[ "$VERSION" == *"-"* ]]; then
    PRERELEASE_FLAG="--prerelease"
    log_info "This will be marked as a pre-release."
fi

# --- Create release ---
log_info "Creating GitHub release $TAG_NAME..."

gh release create "$TAG_NAME" \
    --title "Release $TAG_NAME" \
    --notes "$RELEASE_NOTES" \
    --draft \
    $PRERELEASE_FLAG

log_success "Draft release $TAG_NAME created successfully!"
log_info "The GitHub Actions workflow will now build and attach the artifacts."
log_info "Once the build completes, you can publish the release at:"
log_info "https://github.com/$(gh repo view --json owner,name -q '.owner.login + "/" + .name')/releases"

echo ""
echo "To monitor the build progress:"
echo "gh run list --workflow=release.yml" 
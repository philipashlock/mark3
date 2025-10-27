#!/bin/bash

# Cache CDN libraries locally at build time
# This script downloads ProseMirror and other libraries from CDN and caches them locally
# Run this script from the MarkdownEditor directory

set -e

RESOURCES_DIR="$(dirname "$0")/Resources/Web"
LIB_DIR="$RESOURCES_DIR/lib"
CACHE_FILE="$RESOURCES_DIR/.cdn-cache-version"
CURRENT_VERSION="2024-10-26-v4"

# Create lib directory if it doesn't exist
mkdir -p "$LIB_DIR"

# Check if we need to update the cache
if [ -f "$CACHE_FILE" ]; then
    CACHED_VERSION=$(cat "$CACHE_FILE")
    if [ "$CACHED_VERSION" = "$CURRENT_VERSION" ]; then
        echo "✅ CDN libraries already cached (version: $CURRENT_VERSION)"
        exit 0
    fi
fi

echo "📥 Caching CDN libraries locally..."

# Download ProseMirror libraries
echo "   Downloading prosemirror-state..."
curl -sL "https://cdn.jsdelivr.net/npm/prosemirror-state@1.4.3/dist/index.js" -o "$LIB_DIR/prosemirror-state.js"

echo "   Downloading prosemirror-model..."
curl -sL "https://cdn.jsdelivr.net/npm/prosemirror-model@1.21.3/dist/index.js" -o "$LIB_DIR/prosemirror-model.js"

echo "   Downloading prosemirror-view..."
curl -sL "https://cdn.jsdelivr.net/npm/prosemirror-view@1.33.4/dist/index.js" -o "$LIB_DIR/prosemirror-view.js"

echo "   Downloading prosemirror-transform..."
curl -sL "https://cdn.jsdelivr.net/npm/prosemirror-transform@1.10.1/dist/index.js" -o "$LIB_DIR/prosemirror-transform.js"

echo "   Downloading prosemirror-commands..."
curl -sL "https://cdn.jsdelivr.net/npm/prosemirror-commands@1.5.0/dist/index.js" -o "$LIB_DIR/prosemirror-commands.js"

echo "   Downloading prosemirror-schema-basic..."
curl -sL "https://cdn.jsdelivr.net/npm/prosemirror-schema-basic@1.2.2/dist/index.js" -o "$LIB_DIR/prosemirror-schema-basic.js"

echo "   Downloading prosemirror-schema-list..."
curl -sL "https://cdn.jsdelivr.net/npm/prosemirror-schema-list@1.4.0/dist/index.js" -o "$LIB_DIR/prosemirror-schema-list.js"

echo "   Downloading prosemirror-history..."
curl -sL "https://cdn.jsdelivr.net/npm/prosemirror-history@1.4.0/dist/index.js" -o "$LIB_DIR/prosemirror-history.js"

echo "   Downloading prosemirror-gapcursor..."
curl -sL "https://cdn.jsdelivr.net/npm/prosemirror-gapcursor@1.3.2/dist/index.js" -o "$LIB_DIR/prosemirror-gapcursor.js"

echo "   Downloading prosemirror-keymap..."
curl -sL "https://cdn.jsdelivr.net/npm/prosemirror-keymap@1.2.3/dist/index.js" -o "$LIB_DIR/prosemirror-keymap.js"

echo "   Downloading prosemirror-markdown..."
curl -sL "https://cdn.jsdelivr.net/npm/prosemirror-markdown@1.13.2/dist/index.js" -o "$LIB_DIR/prosemirror-markdown.js"

echo "   Downloading marked.js..."
curl -sL "https://cdn.jsdelivr.net/npm/marked@13.0.0/marked.umd.js" -o "$RESOURCES_DIR/marked.js"

# Update cache version
echo "$CURRENT_VERSION" > "$CACHE_FILE"

echo "✅ CDN libraries cached successfully in $LIB_DIR"
echo "   Cache version: $CURRENT_VERSION"

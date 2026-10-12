#!/bin/bash
# Generate shelf cards from the same catalog and palettes as the app.
# macOS + Xcode only; no third-party dependencies. Run from any directory.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

xcrun swiftc -O -o "$BUILD_DIR/generate-shelf" \
    "$REPO_DIR/Gallery Glow/Models.swift" \
    "$REPO_DIR/Gallery Glow/PaintingData.swift" \
    "$REPO_DIR/Gallery Glow/GradientPalette.swift" \
    "$REPO_DIR/Tools/GenerateTopShelfImages.swift"
"$BUILD_DIR/generate-shelf" "$REPO_DIR"

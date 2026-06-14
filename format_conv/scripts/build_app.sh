#!/bin/bash
# format_conv/scripts/build_app.sh

set -e

echo "Building Flutter application..."

# Build for Windows
echo "Building for Windows..."
flutter build windows --release
echo "Windows build complete"

# Build for macOS
echo "Building for macOS..."
flutter build macos --release
echo "macOS build complete"

# Build for Linux
echo "Building for Linux..."
flutter build linux --release
echo "Linux build complete"

echo "All builds complete!"

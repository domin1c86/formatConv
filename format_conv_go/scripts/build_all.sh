#!/bin/bash
# format_conv_go/scripts/build_all.sh

set -e

echo "Building Go shared library for all platforms..."

mkdir -p build/windows build/macos build/linux

# Windows
echo "Building for Windows..."
GOOS=windows GOARCH=amd64 go build -buildmode=c-shared -o build/windows/format_conv.dll .
echo "Windows build complete"

# macOS
echo "Building for macOS..."
GOOS=darwin GOARCH=amd64 go build -buildmode=c-shared -o build/macos/libformat_conv.dylib .
echo "macOS build complete"

# Linux
echo "Building for Linux..."
GOOS=linux GOARCH=amd64 go build -buildmode=c-shared -o build/linux/libformat_conv.so .
echo "Linux build complete"

echo "All builds complete!"

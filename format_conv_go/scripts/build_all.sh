#!/bin/bash
set -e

echo "=== Go Shared Library Build ==="
echo ""
echo "NOTE: This project uses -buildmode=c-shared because the Flutter frontend"
echo "communicates with Go via FFI (Foreign Function Interface). The shared"
echo "library (.dll/.dylib/.so) is loaded at runtime by the Flutter app."
echo ""
echo "Static linking (-buildmode=c-archive) would require linking the Go"
echo "runtime directly into the Flutter binary via CMake, which adds build"
echo "complexity and larger Flutter binaries. The c-shared approach is the"
echo "standard pattern for Flutter+Go integration."
echo ""
echo "Dependencies: The Go shared library depends on system libc. On Linux,"
echo "the bundled .so should be distributed alongside the app binary."
echo ""

mkdir -p build/windows build/macos build/linux

echo "Building for Windows..."
GOOS=windows GOARCH=amd64 go build -buildmode=c-shared -o build/windows/format_conv.dll .
echo "  -> build/windows/format_conv.dll"

echo "Building for macOS..."
GOOS=darwin GOARCH=amd64 go build -buildmode=c-shared -o build/macos/libformat_conv.dylib .
echo "  -> build/macos/libformat_conv.dylib"

echo "Building for Linux..."
GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build -buildmode=c-shared -o build/linux/libformat_conv.so .
echo "  -> build/linux/libformat_conv.so"

echo ""
echo "All Go shared library builds complete!"

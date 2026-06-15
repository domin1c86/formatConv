#!/bin/bash
set -e

echo "=== Go Shared Library Build: Windows ==="
mkdir -p build/windows

GOOS=windows GOARCH=amd64 CGO_ENABLED=1 \
  go build -buildmode=c-shared -o build/windows/format_conv.dll .

echo "  -> build/windows/format_conv.dll"
echo "Windows Go shared library build complete."

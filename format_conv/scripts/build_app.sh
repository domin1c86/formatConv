#!/bin/bash
# build_app.sh - Main build dispatcher for FormatConv
# Usage: ./build_app.sh {windows|macos|linux|all}
#
# Individual platform scripts are in:
#   build_common.sh  - shared utilities and download functions
#   build_windows.sh - Windows build (MSIX/NSIS)
#   build_linux.sh   - Linux build (DEB/AppImage)
#   build_macos.sh   - macOS build (DMG)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

case "${1:-all}" in
    windows)  source "$SCRIPT_DIR/build_windows.sh"; build_windows ;;
    macos)    source "$SCRIPT_DIR/build_macos.sh"; build_macos ;;
    linux)    source "$SCRIPT_DIR/build_linux.sh"; build_linux ;;
    all)
        source "$SCRIPT_DIR/build_windows.sh"
        source "$SCRIPT_DIR/build_macos.sh"
        source "$SCRIPT_DIR/build_linux.sh"
        build_windows
        build_macos
        build_linux
        ;;
    *)
        echo "Usage: $0 {windows|macos|linux|all}"
        exit 1
        ;;
esac

echo ""
echo "=== Build Summary ==="
echo "Version: ${APP_VERSION:-1.0.0}"
echo "Builds stored in: ${FLUTTER_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}/build/"

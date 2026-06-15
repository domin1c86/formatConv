#!/bin/bash
# build_app.sh - Main build dispatcher for FormatConv
# Usage: ./build_app.sh [windows]
#
# Individual scripts are in:
#   build_common.sh  - shared utilities and download functions
#   build_windows.sh - Windows build (MSIX/NSIS)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

case "${1:-windows}" in
    windows)  source "$SCRIPT_DIR/build_windows.sh"; build_windows ;;
    *)
        echo "Usage: $0 [windows]"
        exit 1
        ;;
esac

echo ""
echo "=== Build Summary ==="
echo "Version: ${APP_VERSION:-1.0.0}"
echo "Builds stored in: ${FLUTTER_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}/build/"

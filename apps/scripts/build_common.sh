#!/bin/bash
# build_common.sh - Shared build utilities for FormatConv

set -e

APP_NAME="format_conv"
APP_VERSION="1.0.0"
PUBLISHER="FormatConv"

FFMPEG_VERSION="master-latest"
IMAGEMAGICK_VERSION="7.1.1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GO_DIR="$FLUTTER_DIR/../native"

cleanup_paths=()
cleanup() {
    for p in "${cleanup_paths[@]}"; do
        rm -rf "$p"
    done
}
trap cleanup EXIT

ensure_tool() {
    local cmd="$1"
    local pkg="$2"
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: '$cmd' not found. Install with: $pkg"
        return 1
    fi
}

check_url() {
    local url="$1"
    local label="$2"
    echo "Checking $label URL reachability..."
    if ! curl --head -fsSL --max-time 15 "$url" >/dev/null 2>&1; then
        echo "WARNING: $label URL may be unreachable: $url"
        echo "  Update FFMPEG_VERSION / IMAGEMAGICK_VERSION if the URL has changed."
    fi
}

verify_sha256() {
    local file="$1"
    local expected="$2"
    if [ -z "$expected" ]; then
        echo "  No checksum provided for $(basename "$file"), skipping verification."
        return 0
    fi
    local actual
    actual=$(sha256sum "$file" | awk '{print $1}')
    if [ "$actual" != "$expected" ]; then
        echo "ERROR: SHA256 mismatch for $(basename "$file")"
        echo "  Expected: $expected"
        echo "  Got:      $actual"
        return 1
    fi
    echo "  SHA256 verified: ${actual:0:16}..."
}

to_windows_path() {
    local path="$1"
    if command -v cygpath &>/dev/null; then
        cygpath -w "$path"
    else
        echo "$path" | sed 's|/|\\|g'
    fi
}

download_ffmpeg_windows() {
    local dest="$1"
    echo "Downloading FFmpeg ${FFMPEG_VERSION} for Windows..."
    mkdir -p "$dest"
    local url="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    check_url "$url" "FFmpeg Windows"
    local tmpzip="/tmp/ffmpeg-win64.zip"
    cleanup_paths+=("$tmpzip" "/tmp/ffmpeg-win64")
    download_and_verify "$url" "$tmpzip" "${FFMPEG_WIN_SHA256:-}" "FFmpeg Windows"
    unzip -q -o "$tmpzip" -d /tmp/ffmpeg-win64
    cp /tmp/ffmpeg-win64/ffmpeg-master-latest-win64-gpl/bin/ffmpeg.exe "$dest/"
    cp /tmp/ffmpeg-win64/ffmpeg-master-latest-win64-gpl/bin/ffprobe.exe "$dest/"
    rm -rf "$tmpzip" /tmp/ffmpeg-win64
}

download_imagemagick_windows() {
    local dest="$1"
    echo "Downloading ImageMagick ${IMAGEMAGICK_VERSION} for Windows..."
    mkdir -p "$dest"
    local url="https://imagemagick.org/archive/binaries/ImageMagick-${IMAGEMAGICK_VERSION}-portable-Q16-HDRI-x64-static.zip"
    check_url "$url" "ImageMagick Windows"
    local tmpzip="/tmp/imagemagick-win64.zip"
    cleanup_paths+=("$tmpzip")
    download_and_verify "$url" "$tmpzip" "${IMAGEMAGICK_WIN_SHA256:-}" "ImageMagick Windows"
    unzip -q -o "$tmpzip" -d "$dest"
    rm -f "$tmpzip"
}

download_and_verify() {
    local url="$1"
    local dest="$2"
    local sha256="$3"
    local label="$4"
    echo "  Downloading $label..."
    curl -L --fail -o "$dest" "$url"
    verify_sha256 "$dest" "$sha256"
}

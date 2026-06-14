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
GO_DIR="$FLUTTER_DIR/../format_conv_go"

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

download_ffmpeg_linux() {
    local dest="$1"
    echo "Downloading FFmpeg static build for Linux..."
    mkdir -p "$dest"
    local url="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
    check_url "$url" "FFmpeg Linux"
    local tmptar="/tmp/ffmpeg-linux.tar.xz"
    local tmpdir="/tmp/ffmpeg-linux"
    cleanup_paths+=("$tmptar" "$tmpdir")
    download_and_verify "$url" "$tmptar" "${FFMPEG_LINUX_SHA256:-}" "FFmpeg Linux"
    mkdir -p "$tmpdir"
    tar -xf "$tmptar" -C "$tmpdir" --strip-components=1
    cp "$tmpdir/ffmpeg" "$dest/"
    cp "$tmpdir/ffprobe" "$dest/"
    rm -rf "$tmptar" "$tmpdir"
}

download_imagemagick_linux() {
    local dest="$1"
    echo "Downloading ImageMagick static build for Linux..."
    mkdir -p "$dest"
    local url="https://imagemagick.org/download/binaries/magick"
    check_url "$url" "ImageMagick Linux"
    local tmpfile="/tmp/magick-linux"
    cleanup_paths+=("$tmpfile")
    download_and_verify "$url" "$tmpfile" "${IMAGEMAGICK_LINUX_SHA256:-}" "ImageMagick Linux"
    cp "$tmpfile" "$dest/magick"
    chmod +x "$dest/magick"
    rm -f "$tmpfile"
}

download_ffmpeg_macos() {
    local dest="$1"
    echo "Downloading FFmpeg for macOS..."
    mkdir -p "$dest"
    local url="https://evermeet.cx/ffmpeg/ffmpeg-${FFMPEG_VERSION}.zip"
    check_url "$url" "FFmpeg macOS"
    local tmpzip="/tmp/ffmpeg-macos.zip"
    cleanup_paths+=("$tmpzip")
    download_and_verify "$url" "$tmpzip" "${FFMPEG_MACOS_SHA256:-}" "FFmpeg macOS"
    unzip -q -o "$tmpzip" -d "$dest"
    rm -f "$tmpzip"
}

download_ffprobe_macos() {
    local dest="$1"
    echo "Downloading ffprobe for macOS..."
    local url="https://evermeet.cx/ffmpeg/ffprobe-${FFMPEG_VERSION}.zip"
    check_url "$url" "ffprobe macOS"
    local tmpzip="/tmp/ffprobe-macos.zip"
    cleanup_paths+=("$tmpzip")
    download_and_verify "$url" "$tmpzip" "${FFPROBE_MACOS_SHA256:-}" "ffprobe macOS"
    unzip -q -o "$tmpzip" -d "$dest"
    rm -f "$tmpzip"
}

download_imagemagick_macos() {
    local dest="$1"
    echo "Downloading ImageMagick for macOS..."
    mkdir -p "$dest"
    local url="https://imagemagick.org/archive/binaries/ImageMagick-${IMAGEMAGICK_VERSION}-clang.tar.gz"
    check_url "$url" "ImageMagick macOS"
    local tmptar="/tmp/imagemagick-macos.tar.gz"
    local tmpdir="/tmp/imagemagick-macos"
    cleanup_paths+=("$tmptar" "$tmpdir")
    download_and_verify "$url" "$tmptar" "${IMAGEMAGICK_MACOS_SHA256:-}" "ImageMagick macOS"
    mkdir -p "$tmpdir"
    tar -xzf "$tmptar" -C "$tmpdir" --strip-components=1
    cp "$tmpdir/bin/magick" "$dest/" 2>/dev/null || cp "$tmpdir/magick" "$dest/" 2>/dev/null || echo "WARNING: Could not find magick binary in archive"
    rm -rf "$tmptar" "$tmpdir"
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

#!/bin/bash
# build_macos.sh - macOS build for FormatConv
source "$(cd "$(dirname "$0")" && pwd)/build_common.sh"

build_macos() {
    echo ""
    echo "=== Building for macOS ==="

    ensure_tool "flutter" "Flutter SDK"
    ensure_tool "go" "Go SDK"
    ensure_tool "curl" "curl (brew install curl)"
    ensure_tool "unzip" "unzip (brew install unzip)"

    echo "Step 1: Building Flutter macOS app..."
    flutter build macos --release
    local output_dir="$FLUTTER_DIR/build/macos/Build/Products/Release"
    local app_bundle="$output_dir/format_conv.app"

    echo "Step 2: Building Go shared library..."
    local frameworks_dir="$app_bundle/Contents/Frameworks"
    mkdir -p "$frameworks_dir"
    (cd "$GO_DIR" && GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 go build -buildmode=c-shared -o "$frameworks_dir/libformat_conv.dylib" .)

    echo "Step 3: Bundling external tools..."
    local tools_dir="$app_bundle/Contents/Resources/tools"
    mkdir -p "$tools_dir"
    download_ffmpeg_macos "$tools_dir"
    download_ffprobe_macos "$tools_dir"
    download_imagemagick_macos "$tools_dir"

    echo "Step 4: Creating DMG..."
    build_dmg "$output_dir"

    echo "macOS build complete!"
    echo "Output: $output_dir"
}

build_dmg() {
    local output_dir="$1"
    local dmg_name="${APP_NAME}-${APP_VERSION}-macos.dmg"
    local dmg_path="$FLUTTER_DIR/build/macos/$dmg_name"
    local dmg_staging="/tmp/format_conv_dmg"
    cleanup_paths+=("$dmg_staging")

    rm -rf "$dmg_staging"
    mkdir -p "$dmg_staging"

    cp -R "$output_dir/format_conv.app" "$dmg_staging/"

    ln -s /Applications "$dmg_staging/Applications"

    if command -v hdiutil &>/dev/null; then
        hdiutil create -volname "Format Converter" \
            -srcfolder "$dmg_staging" \
            -ov -format UDZO \
            "$dmg_path"
        echo "DMG created: $dmg_path"
    else
        echo "WARNING: hdiutil not found. Cannot create DMG."
        echo "  App bundle at: $output_dir/format_conv.app"
        echo "  On macOS, run: hdiutil create -volname 'Format Converter' -srcfolder '$dmg_staging' -ov -format UDZO '$dmg_path'"
    fi
    rm -rf "$dmg_staging"
}

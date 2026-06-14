#!/bin/bash
# build_linux.sh - Linux build for FormatConv
source "$(cd "$(dirname "$0")" && pwd)/build_common.sh"

build_linux() {
    echo ""
    echo "=== Building for Linux ==="

    ensure_tool "flutter" "Flutter SDK"
    ensure_tool "go" "Go SDK"
    ensure_tool "curl" "curl (apt/brew)"
    ensure_tool "tar" "tar (usually pre-installed)"
    ensure_tool "dpkg-deb" "dpkg (apt install dpkg)"

    echo "Step 1: Building Flutter Linux app..."
    flutter build linux --release
    local bundle_dir="$FLUTTER_DIR/build/linux/x64/release/bundle"

    echo "Step 2: Building Go shared library..."
    (cd "$GO_DIR" && GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build -buildmode=c-shared -o "$bundle_dir/lib/libformat_conv.so" .)

    echo "Step 3: Bundling external tools..."
    local tools_dir="$bundle_dir/tools"
    mkdir -p "$tools_dir"
    download_ffmpeg_linux "$tools_dir"
    download_imagemagick_linux "$tools_dir"

    echo "Step 4: Creating DEB package..."
    build_deb "$bundle_dir"

    echo "Step 5: Creating AppImage..."
    build_appimage "$bundle_dir"

    echo "Linux build complete!"
    echo "Output: $bundle_dir"
}

build_deb() {
    local bundle_dir="$1"
    local deb_root="/tmp/format_conv_deb"
    local deb_name="${APP_NAME}_${APP_VERSION}_amd64"
    cleanup_paths+=("$deb_root")

    rm -rf "$deb_root"
    mkdir -p "$deb_root/DEBIAN"
    mkdir -p "$deb_root/usr/bin"
    mkdir -p "$deb_root/usr/lib"
    mkdir -p "$deb_root/usr/lib/$APP_NAME"
    mkdir -p "$deb_root/usr/share/$APP_NAME/tools"
    mkdir -p "$deb_root/usr/share/applications"
    mkdir -p "$deb_root/usr/share/icons/hicolor/256x256/apps"

    cp "$bundle_dir/$APP_NAME" "$deb_root/usr/bin/"
    cp "$bundle_dir/lib/"*.so "$deb_root/usr/lib/$APP_NAME/"
    cp "$bundle_dir/tools/"* "$deb_root/usr/share/$APP_NAME/tools/"

    cp "$SCRIPT_DIR/linux/format_conv.desktop" "$deb_root/usr/share/applications/"

    if [ -f "$FLUTTER_DIR/linux/runner/resources/app_icon.png" ]; then
        cp "$FLUTTER_DIR/linux/runner/resources/app_icon.png" \
            "$deb_root/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
    fi

    cat > "$deb_root/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $APP_VERSION
Section: utils
Priority: optional
Architecture: amd64
Maintainer: $PUBLISHER <dev@formatconv.app>
Description: Cross-platform format conversion tool
 Format Converter is a desktop application for converting between
 various video, audio, and image formats. Supports MP4, MKV, MOV,
 AVI, WebM, JPEG, PNG, WebP, TIFF, MP3, FLAC, WAV, and more.
Depends: libgtk-3-0, libglib2.0-0
EOF

    cat > "$deb_root/DEBIAN/postinst" <<'POSTINST'
#!/bin/bash
ldconfig
POSTINST
    chmod 755 "$deb_root/DEBIAN/postinst"

    dpkg-deb --build "$deb_root" "$FLUTTER_DIR/build/linux/${deb_name}.deb"
    rm -rf "$deb_root"

    echo "DEB package: $FLUTTER_DIR/build/linux/${deb_name}.deb"
}

build_appimage() {
    local bundle_dir="$1"
    local appdir="/tmp/${APP_NAME}.AppDir"
    cleanup_paths+=("$appdir")

    rm -rf "$appdir"
    mkdir -p "$appdir/usr/bin"
    mkdir -p "$appdir/usr/lib"
    mkdir -p "$appdir/usr/share/$APP_NAME/tools"
    mkdir -p "$appdir/usr/share/applications"
    mkdir -p "$appdir/usr/share/icons/hicolor/256x256/apps"

    cp "$bundle_dir/$APP_NAME" "$appdir/usr/bin/"
    cp "$bundle_dir/lib/"*.so "$appdir/usr/lib/"
    cp "$bundle_dir/tools/"* "$appdir/usr/share/$APP_NAME/tools/"

    cp "$SCRIPT_DIR/linux/format_conv.desktop" "$appdir/"

    if [ -f "$FLUTTER_DIR/linux/runner/resources/app_icon.png" ]; then
        cp "$FLUTTER_DIR/linux/runner/resources/app_icon.png" \
            "$appdir/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
        cp "$FLUTTER_DIR/linux/runner/resources/app_icon.png" \
            "$appdir/$APP_NAME.png"
    fi

    cat > "$appdir/AppRun" <<APPRUN
#!/bin/bash
HERE="\$(dirname "\$(readlink -f "\$0")")"
export LD_LIBRARY_PATH="\$HERE/usr/lib:\$LD_LIBRARY_PATH"
export FORMAT_CONV_TOOLS_DIR="\$HERE/usr/share/$APP_NAME/tools"
exec "\$HERE/usr/bin/$APP_NAME" "\$@"
APPRUN
    chmod +x "$appdir/AppRun"

    if command -v appimagetool &>/dev/null; then
        appimagetool "$appdir" "$FLUTTER_DIR/build/linux/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"
        echo "AppImage: $FLUTTER_DIR/build/linux/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"
    else
        echo "WARNING: appimagetool not found. Install from https://github.com/AppImage/AppImageKit"
        echo "  AppDir prepared at: $appdir"
    fi
    rm -rf "$appdir"
}

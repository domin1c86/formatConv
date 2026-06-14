#!/bin/bash
set -e

APP_NAME="format_conv"
APP_VERSION="1.0.0"
PUBLISHER="FormatConv"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FLUTTER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GO_DIR="$(cd "$FLUTTER_DIR/../format_conv_go" && pwd)"

echo "=== Format Conv Build Script ==="
echo "Version: $APP_VERSION"
echo ""

ensure_tool() {
    local cmd="$1"
    local pkg="$2"
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: '$cmd' not found. Install with: $pkg"
        return 1
    fi
}

download_ffmpeg_windows() {
    local dest="$1"
    echo "Downloading FFmpeg for Windows..."
    mkdir -p "$dest"
    local url="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    local tmpzip="/tmp/ffmpeg-win64.zip"
    curl -L -o "$tmpzip" "$url"
    unzip -q -o "$tmpzip" -d /tmp/ffmpeg-win64
    cp /tmp/ffmpeg-win64/ffmpeg-master-latest-win64-gpl/bin/ffmpeg.exe "$dest/"
    cp /tmp/ffmpeg-win64/ffmpeg-master-latest-win64-gpl/bin/ffprobe.exe "$dest/"
    rm -rf "$tmpzip" /tmp/ffmpeg-win64
}

download_imagemagick_windows() {
    local dest="$1"
    echo "Downloading ImageMagick for Windows..."
    mkdir -p "$dest"
    local url="https://imagemagick.org/archive/binaries/ImageMagick-7.1.1-portable-Q16-HDRI-x64-static.zip"
    local tmpzip="/tmp/imagemagick-win64.zip"
    curl -L -o "$tmpzip" "$url"
    unzip -q -o "$tmpzip" -d "$dest"
    rm -f "$tmpzip"
}

download_ffmpeg_linux() {
    local dest="$1"
    echo "Downloading FFmpeg static build for Linux..."
    mkdir -p "$dest"
    local url="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
    local tmptar="/tmp/ffmpeg-linux.tar.xz"
    curl -L -o "$tmptar" "$url"
    tar -xf "$tmptar" -C /tmp/ffmpeg-linux --strip-components=1
    cp /tmp/ffmpeg-linux/ffmpeg "$dest/"
    cp /tmp/ffmpeg-linux/ffprobe "$dest/"
    rm -rf "$tmptar" /tmp/ffmpeg-linux
}

download_imagemagick_linux() {
    local dest="$1"
    echo "Downloading ImageMagick static build for Linux..."
    mkdir -p "$dest"
    local url="https://imagemagick.org/download/binaries/magick"
    curl -L -o "$dest/magick" "$url"
    chmod +x "$dest/magick"
}

# ============================================================================
# Windows Build
# ============================================================================
build_windows() {
    echo ""
    echo "=== Building for Windows ==="

    echo "Step 1: Building Flutter Windows app..."
    flutter build windows --release
    local output_dir="$FLUTTER_DIR/build/windows/x64/runner/Release"

    echo "Step 2: Building Go shared library..."
    (cd "$GO_DIR" && GOOS=windows GOARCH=amd64 go build -buildmode=c-shared -o "$output_dir/format_conv.dll" .)

    echo "Step 3: Bundling external tools..."
    local tools_dir="$output_dir/tools"
    mkdir -p "$tools_dir"

    download_ffmpeg_windows "$tools_dir"
    download_imagemagick_windows "$tools_dir"

    echo "Step 4: Building MSIX package..."
    ensure_tool "dart" "Flutter SDK"

    local msix_dir="$FLUTTER_DIR/build/windows/msix"
    mkdir -p "$msix_dir"

    if flutter pub run msix:create \
        --display-name "$APP_NAME" \
        --publisher-display-name "$PUBLISHER" \
        --version "$APP_VERSION" \
        --output-path "$msix_dir"; then
        echo "MSIX package created in: $msix_dir"
    else
        echo "WARNING: MSIX creation failed. Attempting NSIS fallback..."
        build_nsis_installer "$output_dir"
    fi

    echo "Windows build complete!"
    echo "Output: $output_dir"
}

build_nsis_installer() {
    local source_dir="$1"
    local nsis_script="/tmp/format_conv.nsi"

    cat > "$nsis_script" <<NSISEOF
!include "MUI2.nsh"

Name "Format Converter"
OutFile "$FLUTTER_DIR/build/windows/FormatConverter-Setup.exe"
InstallDir "\$PROGRAMFILES\\FormatConverter"
RequestExecutionLevel admin

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

Section "Install"
    SetOutPath "\$INSTDIR"
    File /r "$source_dir\\*.*"
    WriteUninstaller "\$INSTDIR\\uninstall.exe"
    CreateShortCut "\$DESKTOP\\Format Converter.lnk" "\$INSTDIR\\format_conv.exe"
    CreateDirectory "\$SMPROGRAMS\\Format Converter"
    CreateShortCut "\$SMPROGRAMS\\Format Converter\\Format Converter.lnk" "\$INSTDIR\\format_conv.exe"
    CreateShortCut "\$SMPROGRAMS\\Format Converter\\Uninstall.lnk" "\$INSTDIR\\uninstall.exe"
    WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\FormatConverter" \
        "DisplayName" "Format Converter"
    WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\FormatConverter" \
        "UninstallString" "\$INSTDIR\\uninstall.exe"
SectionEnd

Section "Uninstall"
    Delete "\$INSTDIR\\uninstall.exe"
    RMDir /r "\$INSTDIR"
    Delete "\$DESKTOP\\Format Converter.lnk"
    RMDir /r "\$SMPROGRAMS\\Format Converter"
    DeleteRegKey HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\FormatConverter"
SectionEnd
NSISEOF

    if command -v makensis &>/dev/null; then
        makensis "$nsis_script"
        echo "NSIS installer created"
    else
        echo "WARNING: NSIS not found. Raw build output at: $source_dir"
        echo "Install NSIS (https://nsis.sourceforge.io) to create installer."
    fi
    rm -f "$nsis_script"
}

# ============================================================================
# macOS Build
# ============================================================================
build_macos() {
    echo ""
    echo "=== Building for macOS ==="

    flutter build macos --release
    local output_dir="$FLUTTER_DIR/build/macos/Build/Products/Release"

    (cd "$GO_DIR" && GOOS=darwin GOARCH=amd64 go build -buildmode=c-shared -o "$output_dir/format_conv.app/Contents/Frameworks/libformat_conv.dylib" .)

    local tools_dir="$output_dir/format_conv.app/Contents/Resources/tools"
    mkdir -p "$tools_dir"

    echo "NOTE: For macOS, bundle FFmpeg and ImageMagick via Homebrew at runtime"
    echo "  or include static builds in $tools_dir"

    echo "macOS build complete!"
    echo "Output: $output_dir"
}

# ============================================================================
# Linux Build
# ============================================================================
build_linux() {
    echo ""
    echo "=== Building for Linux ==="

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
    local appdir="/tmp/format_conv.AppDir"

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

    cat > "$appdir/AppRun" <<'APPRUN'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:$LD_LIBRARY_PATH"
export FORMAT_CONV_TOOLS_DIR="$HERE/usr/share/format_conv/tools"
exec "$HERE/usr/bin/format_conv" "$@"
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

# ============================================================================
# Main
# ============================================================================
case "${1:-all}" in
    windows)  build_windows ;;
    macos)    build_macos ;;
    linux)    build_linux ;;
    all)
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
echo "Builds stored in: $FLUTTER_DIR/build/"

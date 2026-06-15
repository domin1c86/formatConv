#!/bin/bash
# build_windows.sh - Windows build for FormatConv
source "$(cd "$(dirname "$0")" && pwd)/build_common.sh"

build_windows() {
    echo ""
    echo "=== Building for Windows ==="

    ensure_tool "flutter" "Flutter SDK"
    ensure_tool "go" "Go SDK"
    ensure_tool "curl" "curl (apt/brew/choco)"
    ensure_tool "unzip" "unzip (apt/brew/choco)"

    echo "Step 1: Building Flutter Windows app..."
    flutter build windows --release
    local output_dir="$FLUTTER_DIR/build/windows/x64/runner/Release"

    echo "Step 2: Building Go shared library..."
    (cd "$GO_DIR" && GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build -buildmode=c-shared -o "$output_dir/format_conv.dll" .)

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
    cleanup_paths+=("$nsis_script")

    local win_source_dir
    win_source_dir=$(to_windows_path "$source_dir")
    local win_flutter_dir
    win_flutter_dir=$(to_windows_path "$FLUTTER_DIR")

    cat > "$nsis_script" <<NSISEOF
!include "MUI2.nsh"

Name "Format Converter"
OutFile "${win_flutter_dir}\\build\\windows\\FormatConverter-Setup.exe"
InstallDir "\$PROGRAMFILES\\FormatConverter"
RequestExecutionLevel admin

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

Section "Install"
    SetOutPath "\$INSTDIR"
    File /r "${win_source_dir}\\*.*"
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

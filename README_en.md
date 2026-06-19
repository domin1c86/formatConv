<p align="right">
  English | <a href="./README.md">中文</a>
</p>

<p align="center">
  <h1 align="center">Format Converter</h1>
  <p align="center"><em>A local Windows video, audio, and image converter with batch drag-and-drop, stream copy, media split/merge, GPU encoding, and conversion history.</em></p>
  <p align="center"><em>For more function demos, please <a href="https://domin1c86.github.io/en/p/format-converter/" target="_blank">View My Blog</a>.</em></p>
</p>

---

## Overview

FormatConv is a Windows x64 desktop format conversion tool. The UI is built with Flutter, while a Go native library handles media probing, task orchestration, and conversion argument generation through FFI. FFmpeg and ImageMagick perform the actual conversions. Release builds can bundle every required tool, so files stay local and users do not need a separate FFmpeg or ImageMagick installation.

## Features

- **Video, audio, and image conversion**: Supports common formats including MP4, MKV, MOV, MP3, FLAC, WAV, JPEG/JPG, PNG, WebP, and GIF.
- **Drag-and-drop batches**: Import from Explorer, multi-select files, drag them onto compatible format cards, or run a conversion with the card's arrow button.
- **File preview and management**: Image/video previews, type filters, pagination, multi-selection, removal, and processed states.
- **Safe remuxing**: Copies compatible video and audio streams and re-encodes only incompatible or explicitly selected streams.
- **GPU video encoding**: Tries NVIDIA NVENC, Intel QSV, and AMD AMF, then falls back to CPU encoding.
- **Media splitting**: Extracts video and/or audio streams, validates audio duration, repairs timestamps, and falls back to MKA when required.
- **Media merging**: Combines one video with one external audio file, optionally keeping the original audio; long audio is trimmed and short audio is padded with silence.
- **Per-format controls**: Audio bitrate/sample rate/channels, image scale/color space/metadata, and video codec/resolution/bitrate/frame rate.
- **Tasks and results**: Progress estimates, cancellation, partial-output cleanup, default-app opening, and persistent history.
- **Desktop experience**: English/Chinese, light/dark themes, MiSans, high-DPI layouts, and developer theme controls.

## Usage

1. Click **Add Files** or drag files from Explorer.
2. Click file cards to multi-select them.
3. Open a target format's settings when needed.
4. Click the format card's arrow button or drag files onto the compatible card.
5. Use the task shelf to monitor progress, cancel work, or open completed output.
6. Open **Results** to review current and historical conversions.

New installers can be installed directly over an existing version. Close FormatConv before upgrading; uninstalling the old version first is not required.

## Project Structure

```text
apps/       Flutter Windows application
native/     Go FFI conversion engine
installer/  Inno Setup scripts
licenses/   License and third-party notices
third_party/ Local external tool cache
```

## Requirements

- Windows 10/11
- Flutter 3.44.2
- Dart SDK 3.12.2
- Go 1.21+
- Visual Studio 2022 with Desktop development with C++
- Inno Setup 6 or 7, only for installer generation

## Local Tool Cache

For local release builds, prepare:

```text
third_party/tools/windows/
  ffmpeg/
    ffmpeg.exe
    ffprobe.exe
    ffmpeg-git-essentials.7z.ver
    ffmpeg-git-essentials.7z.sha256
  imagemagick/
    magick.exe
    LICENSE.txt
    NOTICE.txt
    other ImageMagick portable files
```

The current tracked sources are:

- FFmpeg: <https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-essentials.7z>
- ImageMagick: <https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-25/ImageMagick-7.1.2-25-portable-Q16-x64.7z>
- MiSans license: <https://hyperos.mi.com/font-download/MiSans%E5%AD%97%E4%BD%93%E7%9F%A5%E8%AF%86%E4%BA%A7%E6%9D%83%E8%AE%B8%E5%8F%AF%E5%8D%8F%E8%AE%AE.pdf>

`third_party/tools/windows/` is not committed to Git by default.

## Windows Release Build

```powershell
cd D:\Coding\formatConv
.\apps\scripts\build_windows.ps1 -Mode release
```

The script builds the Go x64 DLL and Flutter Windows release, copies external tools, and writes license notices into:

```text
apps/build/windows/x64/runner/Release/
  tools/
  licenses/
```

## Build the Inno Setup Installer

Set the version and build paths in the same PowerShell session:

```powershell
cd D:\Coding\formatConv

$env:APP_VERSION = "0.1.2"
$env:FORMATCONV_RELEASE_DIR = (Resolve-Path ".\apps\build\windows\x64\runner\Release").Path
New-Item -ItemType Directory -Force ".\dist" | Out-Null
$env:FORMATCONV_DIST_DIR = (Resolve-Path ".\dist").Path

ISCC.exe ".\installer\formatconv.iss"
```

Use the full local path when `ISCC.exe` is not available through `PATH`. The installer is written to `dist/`.

`APP_VERSION` controls the installer version and filename. The Flutter application version comes from `apps/pubspec.yaml`; keep both values aligned.

## Run Locally

```powershell
cd D:\Coding\formatConv\apps
flutter pub get
flutter run -d windows
```

Rebuild `format_conv.dll` after changing the Go FFI interface.

## Checks and Tests

```powershell
cd D:\Coding\formatConv\apps
dart format lib test
flutter analyze
flutter test

cd D:\Coding\formatConv\native
gofmt -l .
gofmt -w .
go vet ./...
go test ./...
```

FFI, FFmpeg argument, and installer changes should also be tested on a Windows machine without system FFmpeg or ImageMagick in `PATH`.

## License

FormatConv source code is licensed under the MIT License. See [LICENSE](LICENSE).

## Third-Party Components

Windows installers may bundle external tools and fonts licensed separately:

- **FFmpeg**: gyan.dev `ffmpeg-git-essentials.7z`, treated as GPLv3.
- **ImageMagick**: `ImageMagick-7.1.2-25-portable-Q16-x64.7z`, licensed separately by ImageMagick Studio LLC.
- **MiSans**: third-party UI font licensed by Xiaomi Inc.; it is not part of the FormatConv MIT license and must not be redistributed as standalone font software.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) before publishing an installer.

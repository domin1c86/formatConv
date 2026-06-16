<p align="right">
  English | <a href="./README_zh.md">中文</a>
</p>

<p align="center">
  <h1 align="center">Layover Lens 中转助手</h1>
  <p align="center"><em>A Windows format conversion tool supporting video, image, and audio conversion with lossless/lossy options.</em></p>
</p>

---

## Features

- **Windows desktop**: Flutter Windows app with a Go native conversion engine
- **Multiple formats**: Video (MP4, MKV, MOV, AVI, WebM), Image (JPEG, PNG, WebP, TIFF, BMP), Audio (MP3, FLAC, WAV, AAC, OGG)
- **Lossless conversion**: Default lossless conversion with optional lossy compression
- **Batch conversion**: Convert multiple files at once
- **Drag and drop**: Easy file selection with drag and drop support
- **Progress tracking**: Real-time conversion progress

## Architecture

- **Frontend**: Flutter 3.x (Dart)
- **Backend**: Go 1.21+ compiled as shared library via CGO
- **Conversion engines**: FFmpeg (video/audio), ImageMagick (images)
- **Communication**: dart:ffi for direct function calls

## Getting Started

### Prerequisites

- Flutter 3.x
- Go 1.21+
- FFmpeg 6.x
- ImageMagick 7.x

### Building

1. Build Go shared library:
   ```bash
   cd native
   ./scripts/build_all.sh
   ```

2. Build Flutter application:
   ```powershell
   cd apps
   ./scripts/build_windows.ps1
   ```

The Flutter Windows application and native Go DLL are built for x64.

### Running

Run the Flutter application:
   ```bash
   cd apps
   flutter run
   ```

## Development

See [DEVELOPMENT.md](docs/DEVELOPMENT.md) for development setup and guidelines.

## User Guide

See [USER_GUIDE.md](docs/USER_GUIDE.md) for user instructions.

## License

FormatConv source code is licensed under the MIT License.

## Third-Party Components

Windows internal builds may bundle external tools under `Release/tools/`:

- FFmpeg: `ffmpeg.exe` and `ffprobe.exe`
  - Package: `ffmpeg-git-essentials.7z`
  - Source: <https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-essentials.7z>
  - Builds page: <https://www.gyan.dev/ffmpeg/builds/>
  - License: GPLv3 for the bundled gyan.dev build
- ImageMagick: `magick.exe` and its portable package files
  - Package: `ImageMagick-7.1.2-25-portable-Q16-x64.7z`
  - Source: <https://github.com/ImageMagick/ImageMagick/releases/tag/7.1.2-25>
  - License: ImageMagick License
- MiSans fonts are bundled as third-party font assets and are not covered by
  the FormatConv MIT License. FormatConv specifically indicates that it uses
  MiSans fonts, and the fonts must not be redistributed as standalone font
  software.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for release packaging
requirements. Installer builds copy notices into `Release/licenses/`.
For public releases, save the official MiSans license PDF as
`licenses/MiSans-License-Agreement.pdf` so the build script can include it in the
installer.

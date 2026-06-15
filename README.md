# FormatConv

A Windows format conversion tool supporting video, image, and audio conversion with lossless/lossy options.

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

MIT License

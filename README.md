# FormatConv

A cross-platform format conversion tool supporting video, image, and audio conversion with lossless/lossy options.

## Features

- **Cross-platform**: Supports Windows, macOS, and Linux
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
   cd format_conv_go
   ./scripts/build_all.sh
   ```

2. Build Flutter application:
   ```bash
   cd format_conv
   ./scripts/build_app.sh
   ```

### Running

1. Copy the built shared library to the Flutter application directory
2. Run the Flutter application:
   ```bash
   cd format_conv
   flutter run
   ```

## Development

See [DEVELOPMENT.md](docs/DEVELOPMENT.md) for development setup and guidelines.

## User Guide

See [USER_GUIDE.md](docs/USER_GUIDE.md) for user instructions.

## License

MIT License

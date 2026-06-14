# Development Guide

## Setup

### Prerequisites
1. Install Flutter 3.x
2. Install Go 1.21+
3. Install FFmpeg 6.x
4. Install ImageMagick 7.x

### Development Environment
1. Clone the repository
2. Install Flutter dependencies:
   ```bash
   cd format_conv
   flutter pub get
   ```
3. Install Go dependencies:
   ```bash
   cd format_conv_go
   go mod tidy
   ```

## Project Structure

### Flutter Frontend (`format_conv/`)
- `lib/`: Main application code
  - `models/`: Data models
  - `services/`: Business logic and FFI calls
  - `providers/`: State management
  - `screens/`: UI screens
  - `widgets/`: Reusable UI components
  - `utils/`: Utility functions
- `test/`: Test files
  - `unit/`: Unit tests
  - `widget/`: Widget tests
  - `integration/`: Integration tests

### Go Backend (`format_conv_go/`)
- `converter/`: Conversion logic
  - `format_detector.go`: File format detection
  - `converter.go`: Main conversion orchestrator
  - `ffmpeg.go`: FFmpeg integration
  - `imagemagick.go`: ImageMagick integration
- `models/`: Data structures
- `utils/`: Utility functions
- `tests/`: Test files

## Development Workflow

### Adding New Format Support
1. Add format to `FormatDetector.initFormats()` in Go
2. Add format to UI components in Flutter
3. Update documentation

### Testing
1. Run Flutter tests:
   ```bash
   cd format_conv
   flutter test
   ```
2. Run Go tests:
   ```bash
   cd format_conv_go
   go test ./...
   ```

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

## Code Style

### Flutter/Dart
- Follow Dart style guide
- Use `flutter analyze` to check for issues
- Format code with `dart format`

### Go
- Follow Go style guide
- Use `gofmt` to format code
- Use `go vet` to check for issues

## Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

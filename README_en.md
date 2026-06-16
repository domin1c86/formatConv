<p align="right">
  English | <a href="./README.md">中文</a>
</p>

<p align="center">
  <h1 align="center">Format Converter</h1>
  <p align="center"><em>A Windows format conversion tool supporting video, image, and audio conversion with lossless/lossy options.</em></p>
</p>

---

## Overview

FormatConv is a Windows desktop format conversion tool built with Flutter and a Go native backend. It supports local video, audio, and image conversion, drag-and-drop workflows, bilingual UI, theme settings, conversion history, and bundled FFmpeg/ImageMagick tools for installer builds.

## Features

- **Windows desktop app**: Flutter UI with a Go FFI conversion engine.
- **Video, audio, and image conversion**: Supports common formats such as MP4, MKV, MOV, MP3, FLAC, WAV, JPEG/JPG, PNG, WebP, GIF, and more.
- **Drag-and-drop workflow**: Add files from Explorer and drag compatible files onto target format cards.
- **Batch conversion**: Multi-select files and convert compatible groups together.
- **Local tool bundle**: Release builds can ship FFmpeg and ImageMagick, so users do not need to install them manually.
- **Bilingual UI**: English and Chinese interface support.

## Project Structure

```text
apps/       Flutter Windows application
native/     Go FFI conversion engine
licenses/   License and third-party notice templates
third_party/ Local external tool cache, not committed to Git
```

## Requirements

- Windows 10/11
- Flutter 3.44.2
- Dart SDK 3.12.2
- Go 1.21+
- Inno Setup 6, only for installer generation

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

`third_party/tools/windows/` is not committed to Git. For automated releases, a verified tool bundle is uploaded as a GitHub Release asset and let GitHub Actions download that fixed archive.

## Build

```powershell
cd D:\Coding\formatConv\apps
.\scripts\build_windows.ps1 -Mode release
```

The script builds the Go DLL, builds the Flutter Windows app, copies external tools, and writes license notices into:

```text
apps/build/windows/x64/runner/Release/
  tools/
  licenses/
```

## Run Locally

```powershell
cd D:\Coding\formatConv\apps
flutter run -d windows
```

## Tests

```powershell
cd D:\Coding\formatConv\apps
flutter analyze
flutter test

cd D:\Coding\formatConv\native
go test ./...
```

## License

FormatConv source code is licensed under the MIT License. See [LICENSE](LICENSE).

## Third-Party Components

Windows installers may bundle external tools and fonts licensed separately:

- **FFmpeg**: gyan.dev `ffmpeg-git-essentials.7z`, treated as GPLv3.
- **ImageMagick**: `ImageMagick-7.1.2-25-portable-Q16-x64.7z`, licensed separately by ImageMagick Studio LLC.
- **MiSans**: third-party UI font licensed by Xiaomi Inc.; it is not part of the FormatConv MIT license and must not be redistributed as standalone font software.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) before publishing an installer.

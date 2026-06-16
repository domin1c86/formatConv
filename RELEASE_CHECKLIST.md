# Release Checklist

Use this checklist before publishing a Windows installer.

## Build Inputs

- `third_party/tools/windows/ffmpeg/ffmpeg.exe` exists.
- `third_party/tools/windows/ffmpeg/ffprobe.exe` exists.
- `third_party/tools/windows/ffmpeg/ffmpeg-git-essentials.7z.ver` is saved for public releases.
- `third_party/tools/windows/ffmpeg/ffmpeg-git-essentials.7z.sha256` is saved for public releases.
- `third_party/tools/windows/imagemagick/magick.exe` exists.
- The full ImageMagick portable package contents are present, including `LICENSE.txt` and `NOTICE.txt` when available.

## Build Command

```powershell
cd D:\Coding\formatConv\apps
.\scripts\build_windows.ps1 -Mode release
```

## Release Directory

Confirm the release directory contains:

```text
apps/build/windows/x64/runner/Release/
  format_conv.exe
  format_conv.dll
  flutter_windows.dll
  data/
  tools/
    ffmpeg.exe
    ffprobe.exe
    magick.exe
  licenses/
    FormatConv-MIT.txt
    FFmpeg-GPLv3.txt
    FFmpeg-SOURCE.txt
    ImageMagick-LICENSE.txt
    THIRD_PARTY_NOTICES.txt
```

## Release Notes

Include this text in GitHub/Gitee release notes:

```text
This installer bundles FFmpeg and ImageMagick.
FormatConv source code is MIT licensed.
FFmpeg and ImageMagick are third-party components licensed separately.
The bundled gyan.dev FFmpeg build is licensed under GPLv3.
```

If the installer bundles `ffmpeg.exe` and `ffprobe.exe`, also include the exact
FFmpeg source commit or source archive link that matches the downloaded
`ffmpeg-git-essentials.7z` package.

## Manual Checks

- About page shows the third-party component notice.
- About page can open third-party notices from the installed app.
- The installer includes the complete `tools/` and `licenses/` directories.
- The app still works on a machine without system FFmpeg/ImageMagick in `PATH`.

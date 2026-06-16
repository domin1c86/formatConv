<p align="right">
  <a href="./README_en.md">English</a> | 中文
</p>

<p align="center">
  <h1 align="center">Format Converter</h1>
  <p align="center"><em>FormatConv 是一个面向 Windows 的本地格式转换工具，支持视频、音频和图片批量转换，并提供压缩率、编码格式、输出目录、历史记录和中英双语界面等功能。</em></p>
</p>

---

## 项目简介

FormatConv 是一个 Windows 桌面格式转换工具，前端使用 Flutter，转换后端使用 Go 原生库。软件支持视频、音频、图片本地转换，支持拖拽、多选、历史记录、中英双语、浅色/深色主题，并可在安装包中随附 FFmpeg 和 ImageMagick。

## 功能

- **Windows 桌面应用**：Flutter 构建界面，Go FFI 负责转换逻辑。
- **多类型转换**：支持 MP4、MKV、MOV、MP3、FLAC、WAV、JPEG/JPG、PNG、WebP、GIF 等常见格式。
- **拖拽工作流**：支持从资源管理器拖入文件，并将文件拖到兼容的格式卡片上转换。
- **批量转换**：支持多选文件，并只转换与目标格式兼容的文件。
- **本地工具打包**：发布版可随附 FFmpeg 和 ImageMagick，用户无需手动安装。
- **双语界面**：支持中文和 English。

## 项目结构

```text
apps/       Flutter Windows 应用
native/     Go FFI 转换引擎
licenses/   许可证和第三方声明模板
third_party/ 本地第三方工具缓存，不提交到 Git
```

## 环境要求

- Windows 10/11
- Flutter 3.44.2
- Dart SDK 3.12.2
- Go 1.21+
- Inno Setup 6，仅生成安装包时需要

## 本地工具缓存

本地 release 构建前准备：

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
    其他 ImageMagick portable 文件
```

当前记录的来源：

- FFmpeg: <https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-essentials.7z>
- ImageMagick: <https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-25/ImageMagick-7.1.2-25-portable-Q16-x64.7z>
- MiSans 许可协议: <https://hyperos.mi.com/font-download/MiSans%E5%AD%97%E4%BD%93%E7%9F%A5%E8%AF%86%E4%BA%A7%E6%9D%83%E8%AE%B8%E5%8F%AF%E5%8D%8F%E8%AE%AE.pdf>

`third_party/tools/windows/` 不提交到 Git。自动发布时，验证过的工具包上传为 GitHub Release 资产，再由 GitHub Actions 下载这份固定压缩包。

## 构建

```powershell
cd D:\Coding\formatConv\apps
.\scripts\build_windows.ps1 -Mode release
```

脚本会构建 Go DLL、构建 Flutter Windows 应用、复制外部工具，并生成许可证目录：

```text
apps/build/windows/x64/runner/Release/
  tools/
  licenses/
```

## 本地运行

```powershell
cd D:\Coding\formatConv\apps
flutter run -d windows
```

## 测试

```powershell
cd D:\Coding\formatConv\apps
flutter analyze
flutter test

cd D:\Coding\formatConv\native
go test ./...
```

## 许可证

FormatConv 源码采用 MIT License。详见 [LICENSE](LICENSE)。

## 第三方组件与许可证

Windows 安装包可能随附以下第三方组件，它们不属于 FormatConv 的 MIT 授权范围：

- **FFmpeg**：gyan.dev `ffmpeg-git-essentials.7z`，按 GPLv3 处理。
- **ImageMagick**：`ImageMagick-7.1.2-25-portable-Q16-x64.7z`，由 ImageMagick Studio LLC 单独授权。
- **MiSans**：小米授权的第三方界面字体，不属于 FormatConv 的 MIT 协议，不得作为独立字体软件再分发或售卖。

发布安装包前请检查 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 和 [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)。

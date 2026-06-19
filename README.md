<p align="right">
  <a href="./README_en.md">English</a> | 中文
</p>

<p align="center">
  <h1 align="center">Format Converter</h1>
  <p align="center"><em>面向 Windows 的本地视频、音频和图片转换工具，支持批量拖拽、流复制、音视频分离/合并、GPU 编码与历史记录。</em></p>
</p>

---

## 项目简介

FormatConv 是一个 Windows x64 桌面格式转换工具。前端使用 Flutter，Go 原生库通过 FFI 负责媒体探测、任务调度和转换参数生成，实际转换由 FFmpeg 与 ImageMagick 完成。发布版可以随附全部外部工具，用户无需单独安装，也不需要把文件上传到服务器。

## 功能

- **多类型转换**：支持 MP4、MKV、MOV、MP3、FLAC、WAV、JPEG/JPG、PNG、WebP、GIF 等常见格式。
- **拖拽与批量处理**：从资源管理器导入文件，多选后拖到兼容格式卡片，或点击卡片右箭头执行转换。
- **文件预览与管理**：图片和视频预览、类型筛选、分页、多选、删除和已处理状态。
- **安全重封装**：容器兼容时直接复制视频流和音频流，只重新编码不兼容或用户明确指定的流。
- **GPU 视频编码**：自动尝试 NVIDIA NVENC、Intel QSV 和 AMD AMF，失败后回退 CPU。
- **音视频分离**：提取视频流和/或音频流，并检查音频输出时长；异常时自动修复时间轴或回退 MKA。
- **音视频合并**：合并一个视频和一个外部音频，可保留或移除源音轨；音频过长截断，过短补静音。
- **格式参数**：音频码率、采样率、声道；图片尺寸、色彩空间、元数据；视频编码、分辨率、码率、帧率等。
- **任务与结果**：进度估算、任务取消、不完整文件清理、默认应用打开和历史记录。
- **桌面体验**：中文/English、浅色/深色主题、MiSans、高 DPI 布局和开发者主题设置。

## 使用方式

1. 点击“添加文件”，或从资源管理器拖入文件。
2. 点击文件卡进行多选。
3. 通过目标格式的设置按钮调整参数。
4. 点击格式卡右箭头，或将文件拖到兼容格式卡。
5. 在底部任务栏查看进度、取消任务或打开输出。
6. 在“结果显示”中查看本次结果和历史记录。

新版安装包可以直接覆盖旧版安装，无需先卸载；升级前请退出正在运行的 FormatConv。

## 项目结构

```text
apps/       Flutter Windows 应用
native/     Go FFI 转换引擎
installer/  Inno Setup 安装脚本
licenses/   许可证和第三方声明
third_party/ 本地第三方工具缓存
```

## 环境要求

- Windows 10/11
- Flutter 3.44.2
- Dart SDK 3.12.2
- Go 1.21+
- Visual Studio 2022（Desktop development with C++）
- Inno Setup 6 或 7，仅生成安装包时需要

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

`third_party/tools/windows/` 默认不提交到 Git。

## Windows Release 构建

```powershell
cd D:\Coding\formatConv
.\apps\scripts\build_windows.ps1 -Mode release
```

脚本会构建 Go x64 DLL、构建 Flutter Windows Release、复制外部工具，并生成许可证目录：

```text
apps/build/windows/x64/runner/Release/
  tools/
  licenses/
```

## 生成 Inno Setup 安装包

在同一个 PowerShell 会话中设置版本和路径：

```powershell
cd D:\Coding\formatConv

$env:APP_VERSION = "0.1.2"
$env:FORMATCONV_RELEASE_DIR = (Resolve-Path ".\apps\build\windows\x64\runner\Release").Path
New-Item -ItemType Directory -Force ".\dist" | Out-Null
$env:FORMATCONV_DIST_DIR = (Resolve-Path ".\dist").Path

ISCC.exe ".\installer\formatconv.iss"
```

如果 `ISCC.exe` 不在 `PATH`，请使用本机 Inno Setup 的完整路径。安装包输出到 `dist/`。

`APP_VERSION` 控制安装器显示版本和文件名；Flutter 应用版本来自 `apps/pubspec.yaml`。应保持两者一致。

## 本地运行

```powershell
cd D:\Coding\formatConv\apps
flutter pub get
flutter run -d windows
```

修改 Go FFI 接口后，需要重新构建 `format_conv.dll`。

## 检查与测试

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

涉及 FFI、FFmpeg 参数或安装包的修改，还应在未安装系统 FFmpeg/ImageMagick 的 Windows 机器上进行实际转换测试。

## 许可证

FormatConv 源码采用 MIT License。详见 [LICENSE](LICENSE)。

## 第三方组件与许可证

Windows 安装包可能随附以下第三方组件，它们不属于 FormatConv 的 MIT 授权范围：

- **FFmpeg**：gyan.dev `ffmpeg-git-essentials.7z`，按 GPLv3 处理。
- **ImageMagick**：`ImageMagick-7.1.2-25-portable-Q16-x64.7z`，由 ImageMagick Studio LLC 单独授权。
- **MiSans**：小米授权的第三方界面字体，不属于 FormatConv 的 MIT 协议，不得作为独立字体软件再分发或售卖。

发布安装包前请检查 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 和 [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)。

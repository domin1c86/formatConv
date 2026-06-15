# FormatConv

FormatConv 是一个面向 Windows 的本地格式转换工具，支持视频、图像和音频文件转换，并提供无损优先、可选有损压缩和批量转换能力。

## 功能特性

- **Windows 桌面应用**：使用 Flutter 构建界面，Go 原生库负责转换逻辑。
- **多类型格式支持**：视频（MP4、MKV、MOV、AVI、WebM）、图像（JPEG、PNG、WebP、TIFF、BMP）、音频（MP3、FLAC、WAV、AAC、OGG）。
- **无损优先**：默认使用无损转换，也可按需选择有损质量。
- **批量转换**：一次选择多个文件并统一转换。
- **拖拽选择**：支持拖放文件，也支持文件选择器。
- **实时进度**：转换过程中显示进度和结果状态。
- **中英双语界面**：应用内可在 English / 中文之间切换。

## 项目结构

```text
apps/       Flutter Windows 应用
native/     Go FFI 转换引擎
docs/       开发和用户文档
DESIGN.md   界面设计风格参考
```

`apps/lib/` 存放 Flutter 业务代码，包含 `screens/`、`widgets/`、`services/`、`providers/`、`models/` 和 `utils/`。`native/converter/` 存放格式检测和 FFmpeg/ImageMagick 调用逻辑。

## 环境要求

- Windows 10/11
- Flutter 3.44.2
- Dart SDK 3.12.2
- Go 1.21+
- FFmpeg 6.x
- ImageMagick 7.x

## 构建

推荐使用 Windows PowerShell：

```powershell
cd apps
.\scripts\build_windows.ps1 -Mode release
```

该脚本会先在 `native/` 构建 `format_conv.dll`，再构建 Flutter Windows 应用。

Flutter Windows 应用和 Go 原生 DLL 均构建为 x64。

## 本地运行

```powershell
cd apps
flutter run -d windows
```

如果只想构建 Go 动态库：

```powershell
cd native
make build-windows
```

## 测试

Flutter 测试：

```powershell
cd apps
flutter test
```

Go 测试：

```powershell
cd native
go test ./...
```

## 使用说明

1. 启动应用。
2. 在右上角选择 English 或 中文。
3. 点击“浏览文件”或拖入文件。
4. 选择目标格式。
5. 按需选择无损/有损、质量或编码器。
6. 等待进度完成，在结果区查看输出文件。

## 许可证

MIT License

# FormatConv

FormatConv 是一个面向 Windows 的本地格式转换工具，支持视频、音频和图片批量转换，并提供压缩率、编码格式、输出目录、历史记录和中英双语界面等功能。

## 功能

- **Windows 桌面应用**：Flutter 构建界面，Go 原生库负责转换逻辑。
- **多类型格式支持**：视频、音频、图片三类格式转换。
- **拖拽操作**：支持从资源管理器拖入文件，并将文件拖到目标格式卡片上转换。
- **批量转换**：支持多选文件和同类型批量处理。
- **本地工具打包**：内测安装包可随附 FFmpeg 和 ImageMagick，用户无需单独安装。
- **双语和主题**：支持中文/English、浅色/深色主题。

## 项目结构

```text
apps/       Flutter Windows 应用
native/     Go FFI 转换引擎
licenses/   安装包许可证和第三方声明模板
third_party/ 本地第三方工具缓存，不提交到仓库
```

`apps/lib/` 存放 Flutter 业务代码，包括 `screens/`、`widgets/`、`services/`、`providers/`、`models/` 和 `utils/`。`native/converter/` 存放格式检测和 FFmpeg/ImageMagick 调用逻辑。

## 环境要求

- Windows 10/11
- Flutter 3.44.2
- Dart SDK 3.12.2
- Go 1.21+

## 本地工具准备

内测版推荐随软件打包 FFmpeg 和 ImageMagick。构建前准备：

```text
third_party/tools/windows/
  ffmpeg/
    ffmpeg.exe
    ffprobe.exe
    ffmpeg-git-essentials.7z.ver      可选，正式发布建议保留
    ffmpeg-git-essentials.7z.sha256   可选，正式发布建议保留
  imagemagick/
    magick.exe
    LICENSE.txt
    NOTICE.txt
    其他 ImageMagick portable 文件
```

当前记录的下载来源：

- FFmpeg: <https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-essentials.7z>
- ImageMagick: <https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-25/ImageMagick-7.1.2-25-portable-Q16-x64.7z>

ImageMagick 应保留 portable 包内的完整文件集，不建议只复制 `magick.exe`。

## 构建

推荐使用 Windows PowerShell：

```powershell
cd D:\Coding\formatConv\apps
.\scripts\build_windows.ps1 -Mode release
```

脚本会构建 Go DLL、构建 Flutter Windows 应用，并复制：

```text
apps/build/windows/x64/runner/Release/
  tools/
    ffmpeg.exe
    ffprobe.exe
    magick.exe
    ImageMagick portable 其他文件
  licenses/
    FormatConv-MIT.txt
    FFmpeg-GPLv3.txt
    FFmpeg-SOURCE.txt
    ImageMagick-LICENSE.txt
    THIRD_PARTY_NOTICES.txt
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

## 第三方组件与许可证

FormatConv 项目源码使用 MIT License。Windows 安装包中随附的 FFmpeg、ImageMagick 和 MiSans 字体是第三方组件，不纳入 FormatConv 的 MIT 授权范围。

- FFmpeg：当前使用 gyan.dev `ffmpeg-git-essentials.7z`，按 GPLv3 处理。
- ImageMagick：当前使用 `ImageMagick-7.1.2-25-portable-Q16-x64.7z`，按 ImageMagick License 处理。
- MiSans：按字体上游授权处理，不默认归入 MIT。

发布安装包前请检查 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)，并确保安装目录中包含 `licenses/`。

## 许可证

FormatConv 源码采用 MIT License。详见 [LICENSE](LICENSE)。

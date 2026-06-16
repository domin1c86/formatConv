# Third-Party Notices

FormatConv source code is licensed under the MIT License. The Windows
installer may bundle third-party executable tools that are licensed separately
and are not part of the FormatConv MIT-licensed source code.

This notice is informational and is not legal advice.

## FormatConv

- License: MIT License
- Copyright: Copyright (c) 2026 Domin1c
- License file in installer: `licenses/FormatConv-MIT.txt`

## FFmpeg

- Component: `ffmpeg.exe`, `ffprobe.exe`
- Package used for current Windows internal builds: `ffmpeg-git-essentials.7z`
- Binary source: <https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-essentials.7z>
- Builds page: <https://www.gyan.dev/ffmpeg/builds/>
- License for gyan.dev Windows builds: GPLv3

The gyan.dev `ffmpeg-git-essentials.7z` package is a rolling git build. Before
each public release, keep the matching `.ver` and `.sha256` files together with
the downloaded archive and record the exact FFmpeg source commit in the release
notes. The gyan.dev builds page provides the current git build version and source
commit link.

Do not rename `ffmpeg.exe` or `ffprobe.exe` to obscure their origin.

## ImageMagick

- Component: `magick.exe` and the ImageMagick portable package files
- Version: 7.1.2-25
- Package: `ImageMagick-7.1.2-25-portable-Q16-x64.7z`
- Source release: <https://github.com/ImageMagick/ImageMagick/releases/tag/7.1.2-25>
- Binary source: <https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-25/ImageMagick-7.1.2-25-portable-Q16-x64.7z>
- License: ImageMagick License
- License URL: <https://imagemagick.org/license/>

The installer should preserve the full portable ImageMagick file set. Do not
ship only `magick.exe`, because ImageMagick may need its bundled configuration,
delegates, license, and notice files.

## MiSans

- Component: bundled MiSans font files under `apps/assets/fonts/`
- Licensor: Xiaomi Inc.
- License: MiSans Font Intellectual Property License Agreement
- License URL: <https://hyperos.mi.com/font-download/MiSans%E5%AD%97%E4%BD%93%E7%9F%A5%E8%AF%86%E4%BA%A7%E6%9D%83%E8%AE%B8%E5%8F%AF%E5%8D%8F%E8%AE%AE.pdf>

MiSans is bundled as a third-party font asset. It is not licensed under
FormatConv's MIT License.

FormatConv specifically indicates that it uses MiSans fonts. Do not adapt or
redevelop the MiSans font files or their components. Do not rent, sublicense,
give, loan, redistribute, or sell MiSans as standalone font software. Any copy of
the MiSans fonts should retain the copyright notice and the MiSans Font
Intellectual Property License Agreement. The bundled fonts are used only as UI
assets of FormatConv and should not be extracted and redistributed
independently.

## Release Notice Text

Use this text in GitHub/Gitee releases when publishing an installer:

```text
This installer bundles FFmpeg and ImageMagick.
FormatConv source code is MIT licensed.
FFmpeg and ImageMagick are third-party components licensed separately.
The bundled gyan.dev FFmpeg build is licensed under GPLv3.
```

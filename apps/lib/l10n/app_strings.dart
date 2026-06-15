import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { en, zh }

final appLanguageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.en);

final appStringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(appLanguageProvider));
});

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  bool get isZh => language == AppLanguage.zh;

  String get appTitle => isZh ? '格式转换器' : 'Format Converter';
  String get productName => isZh ? 'FormatConv' : 'FormatConv';
  String get navFiles => isZh ? '文件' : 'Files';
  String get navFormats => isZh ? '格式' : 'Formats';
  String get navResults => isZh ? '结果' : 'Results';
  String get languageEnglish => 'English';
  String get languageChinese => '中文';
  String get heroTitle => isZh ? '转换视频、图像与音频。' : 'Convert video, images, and audio.';
  String get heroSubtitle => isZh
      ? '面向 Windows 的本地转换工作台，支持批量文件、无损优先和实时进度。'
      : 'A native Windows conversion workspace for batch files, lossless-first output, and live progress.';
  String get selectFiles => isZh ? '选择文件' : 'Select Files';
  String get dropFiles => isZh ? '将文件拖放到这里' : 'Drag and drop files here';
  String get browseFiles => isZh ? '浏览文件' : 'Browse Files';
  String selectedCount(int count) => isZh ? '已选择 $count 个文件' : '$count files selected';
  String get noFiles => isZh ? '还没有选择文件' : 'No files selected yet';
  String get outputFormat => isZh ? '选择输出格式' : 'Select Output Format';
  String get emptyFormatHint => isZh
      ? '先选择文件，然后点击目标格式开始转换'
      : 'Select files first, then click a format to convert';
  String get overwrite => isZh ? '覆盖原输出' : 'Overwrite';
  String get videoFormats => isZh ? '视频格式' : 'Video Formats';
  String get imageFormats => isZh ? '图像格式' : 'Image Formats';
  String get audioFormats => isZh ? '音频格式' : 'Audio Formats';
  String get unsupportedFileType => isZh ? '不支持的文件类型' : 'Unsupported file type';
  String get selectedFiles => isZh ? '已选文件' : 'Selected Files';
  String get conversionResults => isZh ? '转换结果' : 'Conversion Results';
  String get converting => isZh ? '正在转换...' : 'Converting...';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get openFile => isZh ? '用系统默认应用打开' : 'Open with system default app';
  String get lossless => isZh ? '无损' : 'Lossless';
  String get lossy => isZh ? '有损' : 'Lossy';
  String get convertTo => isZh ? '转换为' : 'Convert to';
  String get quality => isZh ? '质量' : 'Quality';
}

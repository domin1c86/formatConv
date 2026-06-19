import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { en, zh }

final appLanguageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.en);

final appStringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(appLanguageProvider));
});

class AppStrings {
  final AppLanguage appLanguage;

  const AppStrings(this.appLanguage);

  bool get isZh => appLanguage == AppLanguage.zh;

  String get appTitle => isZh ? '格式转换器' : 'Format Converter';
  String get productName => 'FormatConv';
  String get addFiles => isZh ? '添加文件' : 'Add Files';
  String get addedFiles => isZh ? '已添加文件' : 'Added Files';
  String get settings => isZh ? '设置' : 'Settings';
  String get dropFiles => isZh ? '拖入文件或点击选择' : 'Drop files or click to browse';
  String get browseFiles => isZh ? '选择文件' : 'Browse';
  String selectedCount(int count) =>
      isZh ? '已添加 $count 个文件' : '$count files added';
  String selectedCardCount(int count) =>
      isZh ? '已选择 $count 个文件' : '$count files selected';
  String get noFiles => isZh ? '还没有添加文件' : 'No files added';
  String get all => isZh ? '全部' : 'All';
  String get video => isZh ? '视频' : 'Video';
  String get audio => isZh ? '音频' : 'Audio';
  String get image => isZh ? '图片' : 'Image';
  String get formatSelection => isZh ? '格式选择' : 'Format Selection';
  String get resultDisplay => isZh ? '结果显示' : 'Results';
  String get completedThisRun => isZh ? '本次已完成' : 'Completed';
  String get historyHint => isZh ? '历史记录' : 'History';
  String get historyHintBody =>
      isZh ? '点击查看历史转换记录' : 'Click to view conversion history';
  String get emptyFormatHint => isZh
      ? '添加文件后选择目标格式，或将文件拖到对应格式上转换'
      : 'Add files, then choose a target format or drag files onto a compatible format.';
  String get unsupportedFileType =>
      isZh ? '未检测到可转换的文件类型' : 'No supported file types detected';
  String get videoFormats => isZh ? '视频' : 'Video';
  String get imageFormats => isZh ? '图片' : 'Image';
  String get audioFormats => isZh ? '音频' : 'Audio';
  String get mediaOperations => isZh ? '分离/合并' : 'Split/Merge';
  String get splitAudioVideo => isZh ? '音视频分离' : 'Split';
  String get mergeAudioVideo => isZh ? '音视频合并' : 'Merge';
  String get splitVideoTrack => isZh ? '视频' : 'Video';
  String get splitAudioTrack => isZh ? '音频' : 'Audio';
  String get autoMerge => isZh ? '自动合并' : 'Auto merge';
  String get removeSourceAudio => isZh ? '去除源视频音轨' : 'Remove source audio';
  String get importedFileList => isZh ? '已导入的文件列表' : 'Imported files';
  String get mergeValidationTitle => isZh ? '无法执行合并' : 'Cannot merge';
  String get mergeNeedsOneVideoOneAudio =>
      isZh ? '需要且只能包含 1 个视频文件和 1 个音频文件。' : 'Add exactly one video file and one audio file.';
  String get removeFromList => isZh ? '从列表移除' : 'Remove from list';
  String get openFile => isZh ? '默认应用打开' : 'Open';
  String get sourceFile => isZh ? '源文件' : 'Source';
  String get outputFile => isZh ? '输出文件' : 'Output';
  String get duration => isZh ? '耗时' : 'Duration';
  String get operationTime => isZh ? '操作时间' : 'Time';
  String get conversionFailed => isZh ? '转换失败' : 'Conversion failed';
  String get converting => isZh ? '正在转换...' : 'Converting...';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get removeFile => isZh ? '移除文件' : 'Remove file';
  String get confirm => isZh ? '确定' : 'OK';
  String get common => isZh ? '常规' : 'General';
  String get preferences => isZh ? '偏好' : 'Preferences';
  String get advanced => isZh ? '高级' : 'Advanced';
  String get about => isZh ? '关于' : 'About';
  String get clickSupport => isZh ? '点击支持' : 'Support';
  String get github => 'GitHub';
  String get gitee => 'Gitee';
  String get defaultOutputDirectory =>
      isZh ? '默认输出目录' : 'Default output directory';
  String get askBeforeConvert =>
      isZh ? '每次转换前询问保存地址' : 'Ask before each conversion';
  String get namingTemplate => isZh ? '转换后命名' : 'Output naming';
  String get namingTemplatePrefix => 'name[';
  String get namingTemplateSuffix => ']';
  String get namingTemplateRule =>
      isZh ? r'仅能有一个 $num' : r'Only contain $num once';
  String get overwriteSource => isZh ? '是否覆盖源文件' : 'Overwrite source file';
  String get gpuAcceleration => isZh ? '启用 GPU 加速' : 'Enable GPU acceleration';
  String get language => isZh ? '语言' : 'Language';
  String get languageEnglish => 'English';
  String get languageChinese => '中文';
  String get theme => isZh ? '主题' : 'Theme';
  String get lightTheme => isZh ? '浅色' : 'Light';
  String get darkTheme => isZh ? '深色' : 'Dark';
  String get font => isZh ? '字体' : 'Font';
  String get leftPaneFont => isZh ? '左侧区域字体' : 'Left pane font';
  String get rightPaneFont => isZh ? '右侧区域字体' : 'Right pane font';
  String get settingsFont => isZh ? '设置弹窗字体' : 'Settings dialog font';
  String get cardRadius => isZh ? '卡片圆角' : 'Card radius';
  String get appIconPath =>
      isZh ? '开发/打包图标路径' : 'Development/package icon path';
  String get appIconTip => isZh
      ? '选择 .ico 文件后保存路径；已构建 exe 的图标仍需要替换项目 app_icon.ico 并重新构建。'
      : 'Choose an .ico file path. Built exe icons still require replacing app_icon.ico and rebuilding.';
  String get themeColors => isZh ? '主题颜色' : 'Theme colors';
  String get appearance => isZh ? '外观设置' : 'Appearance';
  String get visibleFormats => isZh ? '格式选择' : 'Visible formats';
  String get developerMode => isZh ? '开发者模式' : 'Developer mode';
  String get developerWarning => isZh
      ? '开发者模式会允许修改界面主题配置。错误配置可能导致界面显示异常，确认开启？'
      : 'Developer mode allows editing theme tokens. Invalid values may break the UI. Continue?';
  String get edit => isZh ? '编辑' : 'Edit';
  String get save => isZh ? '保存' : 'Save';
  String get reset => isZh ? '重置' : 'Reset';
  String get resetWarning =>
      isZh ? '确认重置所有设置和历史记录？' : 'Reset all settings and history?';
  String get aboutBody => isZh
      ? 'FormatConv 是面向 Windows 的本地格式转换工具，支持视频、音频与图片的批量转换。'
      : 'FormatConv is a local Windows conversion tool for video, audio, and image batches.';
  String get thirdPartyLicenses => isZh ? '第三方组件与许可证' : 'Third-party licenses';
  String get ffmpegThirdPartyNotice => isZh
      ? '本软件使用 FFmpeg 项目的 FFmpeg。随包提供的 gyan.dev 构建版本按 GPLv3 授权。'
      : 'This software uses FFmpeg from the FFmpeg project. The bundled gyan.dev build is licensed under GPLv3.';
  String get imageMagickThirdPartyNotice => isZh
      ? '本软件使用 ImageMagick。ImageMagick 由 ImageMagick Studio LLC 单独授权。'
      : 'This software uses ImageMagick, licensed separately by ImageMagick Studio LLC.';
  String get miSansThirdPartyNotice => isZh
      ? '本软件使用 MiSans 字体。MiSans 由小米科技有限责任公司单独授权。'
      : 'This software uses MiSans fonts, licensed separately by Xiaomi Inc.';
  String get openThirdPartyNotices =>
      isZh ? '打开第三方声明' : 'Open third-party notices';
  String get compressionRatio => isZh ? '压缩率' : 'Compression';
  String get bitrate => isZh ? '码率' : 'Bitrate';
  String get codec => isZh ? '编码格式' : 'Codec';
  String get compressionAlgorithm => isZh ? '压缩算法' : 'Compression algorithm';
  String get sameAsSource => isZh ? '与源保持相同' : 'Same as source';
  String get audioBitrate => isZh ? '音频码率' : 'Audio bitrate';
  String get sampleRate => isZh ? '采样率' : 'Sample rate';
  String get channels => isZh ? '声道数' : 'Channels';
  String get mono => isZh ? '单声道' : 'Mono';
  String get stereo => isZh ? '立体声' : 'Stereo';
  String get imageScale => isZh ? '尺寸比例' : 'Image scale';
  String get colorSpace => isZh ? '色彩空间' : 'Color space';
  String get preserveMetadata => isZh ? '保留元数据' : 'Preserve metadata';
  String get forceVideoReencode => isZh ? '强制视频流重新编码' : 'Force video re-encode';
  String get forceAudioReencode => isZh ? '强制音频流重新编码' : 'Force audio re-encode';
  String get videoCompression => isZh ? '视频压缩率' : 'Video compression';
  String get audioCompression => isZh ? '音频压缩率' : 'Audio compression';
  String get videoCodec => isZh ? '视频编码' : 'Video codec';
  String get audioCodec => isZh ? '音频编码' : 'Audio codec';
  String get resolution => isZh ? '分辨率' : 'Resolution';
  String get videoBitrate => isZh ? '视频码率' : 'Video bitrate';
  String get frameRate => isZh ? '帧率' : 'Frame rate';
  String get aspectRatio => isZh ? '宽高比' : 'Aspect ratio';
  String get custom => isZh ? '自定义' : 'Custom';
  String get customFrameRate => isZh ? '自定义帧率' : 'Custom frame rate';
  String get gifScale => isZh ? '画面尺寸' : 'Frame size';
  String get gifMaxColors => isZh ? '最大颜色数' : 'Max colors';
  String get gifDitherAlgorithm => isZh ? '抖动算法' : 'Dither algorithm';
  String get gifLoopMode => isZh ? '循环模式' : 'Loop mode';
  String get loopInfinite => isZh ? '无限循环' : 'Infinite';
  String get none => isZh ? '无' : 'None';
  String get formatSettings => isZh ? '格式设置' : 'Format settings';
  String get defaultOption => isZh ? '默认' : 'Default';
  String get typeMismatchTitle =>
      isZh ? '部分文件类型不匹配' : 'Some files were skipped';
  String typeMismatchMessage(List<String> names) {
    final joined = names.join(isZh ? '、' : ', ');
    return isZh
        ? '以下文件不适合当前目标格式，已跳过：$joined'
        : 'These files are not compatible with the target format and were skipped: $joined';
  }

  // Compatibility labels used by older tests/widgets during refactors.
  String get selectFiles => addFiles;
  String get outputFormat => formatSelection;
  String get overwrite => isZh ? '覆盖原输出' : 'Overwrite';
  String get selectedFiles => addedFiles;
  String get conversionResults => resultDisplay;
  String get lossless => isZh ? '无损' : 'Lossless';
  String get lossy => isZh ? '有损' : 'Lossy';
  String get convertTo => isZh ? '转换为' : 'Convert to';
  String get quality => isZh ? '质量' : 'Quality';
  String get navFiles => isZh ? '文件' : 'Files';
  String get navFormats => isZh ? '格式' : 'Formats';
  String get navResults => isZh ? '结果' : 'Results';
  String get heroTitle =>
      isZh ? '转换视频、图片与音频。' : 'Convert video, images, and audio.';
  String get heroSubtitle =>
      isZh ? '面向 Windows 的本地转换工作台。' : 'A native Windows conversion workspace.';
}

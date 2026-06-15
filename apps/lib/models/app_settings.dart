import 'dart:convert';

import '../l10n/app_strings.dart';

enum AppThemeChoice { light, dark }

const supportedVideoFormats = [
  'MP4',
  'MKV',
  'MOV',
  'AVI',
  'WebM',
  'FLV',
  'WMV',
  'MPEG',
  '3GP'
];
const supportedImageFormats = [
  'JPEG',
  'PNG',
  'WebP',
  'TIFF',
  'BMP',
  'GIF',
  'ICO',
  'SVG'
];
const supportedAudioFormats = [
  'MP3',
  'FLAC',
  'WAV',
  'AAC',
  'OGG',
  'WMA',
  'M4A',
  'OPUS'
];

const defaultThemeTokens = {
  'background': '#F5F5F7',
  'surface': '#FFFFFF',
  'surfaceMuted': '#FAFAFC',
  'ink': '#1D1D1F',
  'muted': '#6E6E73',
  'primary': '#0066CC',
  'border': '#E0E0E0',
  'cardRadius': 14,
};

class AppSettings {
  final AppLanguage language;
  final AppThemeChoice theme;
  final String fontFamily;
  final String defaultOutputDirectory;
  final bool askBeforeConvert;
  final String namingTemplate;
  final bool overwriteSource;
  final bool gpuAcceleration;
  final Set<String> visibleVideoFormats;
  final Set<String> visibleImageFormats;
  final Set<String> visibleAudioFormats;
  final bool developerMode;
  final String themeJson;

  const AppSettings({
    this.language = AppLanguage.en,
    this.theme = AppThemeChoice.light,
    this.fontFamily = 'MiSans',
    this.defaultOutputDirectory = '',
    this.askBeforeConvert = false,
    this.namingTemplate = r'$name$_1',
    this.overwriteSource = false,
    this.gpuAcceleration = false,
    this.visibleVideoFormats = const {...supportedVideoFormats},
    this.visibleImageFormats = const {...supportedImageFormats},
    this.visibleAudioFormats = const {...supportedAudioFormats},
    this.developerMode = false,
    this.themeJson = '',
  });

  String get effectiveThemeJson => themeJson.isEmpty
      ? const JsonEncoder.withIndent('  ').convert(defaultThemeTokens)
      : themeJson;

  AppSettings copyWith({
    AppLanguage? language,
    AppThemeChoice? theme,
    String? fontFamily,
    String? defaultOutputDirectory,
    bool? askBeforeConvert,
    String? namingTemplate,
    bool? overwriteSource,
    bool? gpuAcceleration,
    Set<String>? visibleVideoFormats,
    Set<String>? visibleImageFormats,
    Set<String>? visibleAudioFormats,
    bool? developerMode,
    String? themeJson,
  }) {
    return AppSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      fontFamily: fontFamily ?? this.fontFamily,
      defaultOutputDirectory:
          defaultOutputDirectory ?? this.defaultOutputDirectory,
      askBeforeConvert: askBeforeConvert ?? this.askBeforeConvert,
      namingTemplate: namingTemplate ?? this.namingTemplate,
      overwriteSource: overwriteSource ?? this.overwriteSource,
      gpuAcceleration: gpuAcceleration ?? this.gpuAcceleration,
      visibleVideoFormats: visibleVideoFormats ?? this.visibleVideoFormats,
      visibleImageFormats: visibleImageFormats ?? this.visibleImageFormats,
      visibleAudioFormats: visibleAudioFormats ?? this.visibleAudioFormats,
      developerMode: developerMode ?? this.developerMode,
      themeJson: themeJson ?? this.themeJson,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language.name,
        'theme': theme.name,
        'fontFamily': fontFamily,
        'defaultOutputDirectory': defaultOutputDirectory,
        'askBeforeConvert': askBeforeConvert,
        'namingTemplate': namingTemplate,
        'overwriteSource': overwriteSource,
        'gpuAcceleration': gpuAcceleration,
        'visibleVideoFormats': visibleVideoFormats.toList(),
        'visibleImageFormats': visibleImageFormats.toList(),
        'visibleAudioFormats': visibleAudioFormats.toList(),
        'developerMode': developerMode,
        'themeJson': themeJson,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    Set<String> readSet(String key, List<String> fallback) {
      final raw = json[key];
      if (raw is List) {
        return raw.whereType<String>().toSet();
      }
      return fallback.toSet();
    }

    return AppSettings(
      language: AppLanguage.values.firstWhere(
        (v) => v.name == json['language'],
        orElse: () => AppLanguage.en,
      ),
      theme: AppThemeChoice.values.firstWhere(
        (v) => v.name == json['theme'],
        orElse: () => AppThemeChoice.light,
      ),
      fontFamily: json['fontFamily'] as String? ?? 'MiSans',
      defaultOutputDirectory: json['defaultOutputDirectory'] as String? ?? '',
      askBeforeConvert: json['askBeforeConvert'] as bool? ?? false,
      namingTemplate: json['namingTemplate'] as String? ?? r'$name$_1',
      overwriteSource: json['overwriteSource'] as bool? ?? false,
      gpuAcceleration: json['gpuAcceleration'] as bool? ?? false,
      visibleVideoFormats:
          readSet('visibleVideoFormats', supportedVideoFormats),
      visibleImageFormats:
          readSet('visibleImageFormats', supportedImageFormats),
      visibleAudioFormats:
          readSet('visibleAudioFormats', supportedAudioFormats),
      developerMode: json['developerMode'] as bool? ?? false,
      themeJson: json['themeJson'] as String? ?? '',
    );
  }
}

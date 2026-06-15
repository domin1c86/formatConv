class FormatInfo {
  final String format;
  final String type; // video, image, audio
  final String extension;
  final String mimeType;
  final Map<String, String> properties;

  FormatInfo({
    required this.format,
    required this.type,
    required this.extension,
    required this.mimeType,
    this.properties = const {},
  });

  factory FormatInfo.fromJson(Map<String, dynamic> json) {
    return FormatInfo(
      format: json['format'] ?? '',
      type: json['type'] ?? '',
      extension: json['extension'] ?? '',
      mimeType: json['mime_type'] ?? '',
      properties: Map<String, String>.from(json['properties'] ?? {}),
    );
  }
}

class FormatList {
  final List<FormatInfo> videoFormats;
  final List<FormatInfo> imageFormats;
  final List<FormatInfo> audioFormats;

  FormatList({
    required this.videoFormats,
    required this.imageFormats,
    required this.audioFormats,
  });

  factory FormatList.fromJson(Map<String, dynamic> json) {
    return FormatList(
      videoFormats: (json['video_formats'] as List? ?? [])
          .map((e) => FormatInfo.fromJson(e))
          .toList(),
      imageFormats: (json['image_formats'] as List? ?? [])
          .map((e) => FormatInfo.fromJson(e))
          .toList(),
      audioFormats: (json['audio_formats'] as List? ?? [])
          .map((e) => FormatInfo.fromJson(e))
          .toList(),
    );
  }
}

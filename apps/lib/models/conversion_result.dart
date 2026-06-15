import 'package:path/path.dart' as p;

class ConversionResult {
  final String inputPath;
  final String outputPath;
  final bool success;
  final String? error;
  final DateTime startedAt;
  final DateTime finishedAt;

  const ConversionResult({
    required this.inputPath,
    required this.outputPath,
    required this.success,
    required this.startedAt,
    required this.finishedAt,
    this.error,
  });

  String get inputName => p.basename(inputPath);
  String get outputName => outputPath.isEmpty ? '' : p.basename(outputPath);
  Duration get duration => finishedAt.difference(startedAt);

  Map<String, dynamic> toJson() => {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'success': success,
        'error': error,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
      };

  factory ConversionResult.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return ConversionResult(
      inputPath: json['inputPath'] as String? ?? '',
      outputPath: json['outputPath'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      error: json['error'] as String?,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? now,
      finishedAt: DateTime.tryParse(json['finishedAt'] as String? ?? '') ?? now,
    );
  }
}

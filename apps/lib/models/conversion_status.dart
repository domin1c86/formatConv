class ConversionStatus {
  final int conversionId;
  final String status; // pending, processing, completed, failed, cancelled
  final double progress; // 0.0 - 1.0
  final int processedBytes;
  final int totalBytes;
  final String? error;
  final String outputPath;

  ConversionStatus({
    required this.conversionId,
    required this.status,
    required this.progress,
    this.processedBytes = 0,
    this.totalBytes = 0,
    this.error,
    required this.outputPath,
  });

  factory ConversionStatus.fromJson(Map<String, dynamic> json) {
    return ConversionStatus(
      conversionId: json['conversion_id'] ?? 0,
      status: json['status'] ?? 'pending',
      progress: (json['progress'] ?? 0.0).toDouble(),
      processedBytes: json['processed_bytes'] ?? 0,
      totalBytes: json['total_bytes'] ?? 0,
      error: json['error'],
      outputPath: json['output_path'] ?? '',
    );
  }
}

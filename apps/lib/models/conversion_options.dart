class ConversionOptions {
  final bool lossless;
  final int quality; // 0-100, only for lossy
  final String? codec;
  final String? bitrate;
  final String? compressionAlgorithm;
  final bool overwrite;
  final bool gpuAcceleration;

  ConversionOptions({
    this.lossless = true,
    this.quality = 100,
    this.codec,
    this.bitrate,
    this.compressionAlgorithm,
    this.overwrite = false,
    this.gpuAcceleration = false,
  });

  ConversionOptions copyWith({
    bool? lossless,
    int? quality,
    String? codec,
    String? bitrate,
    String? compressionAlgorithm,
    bool? overwrite,
    bool? gpuAcceleration,
  }) {
    return ConversionOptions(
      lossless: lossless ?? this.lossless,
      quality: quality ?? this.quality,
      codec: codec ?? this.codec,
      bitrate: bitrate ?? this.bitrate,
      compressionAlgorithm: compressionAlgorithm ?? this.compressionAlgorithm,
      overwrite: overwrite ?? this.overwrite,
      gpuAcceleration: gpuAcceleration ?? this.gpuAcceleration,
    );
  }

  Map<String, dynamic> toJson() => {
        'lossless': lossless,
        'quality': quality,
        'codec': codec,
        'bitrate': bitrate,
        'compression_algorithm': compressionAlgorithm,
        'overwrite': overwrite,
        'gpu_acceleration': gpuAcceleration,
      };
}

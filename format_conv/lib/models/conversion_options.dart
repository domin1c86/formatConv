class ConversionOptions {
  final bool lossless;
  final int quality; // 0-100, only for lossy
  final String? codec;
  final bool overwrite;

  ConversionOptions({
    this.lossless = true,
    this.quality = 100,
    this.codec,
    this.overwrite = false,
  });

  Map<String, dynamic> toJson() => {
    'lossless': lossless,
    'quality': quality,
    'codec': codec,
    'overwrite': overwrite,
  };
}

class ConversionOptions {
  static const source = 'source';

  final bool lossless;
  final int quality; // 0-100, only for lossy
  final String? codec;
  final String? bitrate;
  final String? compressionAlgorithm;
  final bool overwrite;
  final bool gpuAcceleration;
  final int audioQuality;
  final String audioCodec;
  final String audioBitrate;
  final String sampleRate;
  final String channels;
  final int imageQuality;
  final int imageScalePercent;
  final String colorSpace;
  final bool preserveMetadata;
  final bool forceVideoReencode;
  final bool forceAudioReencode;
  final int videoQuality;
  final String videoCodec;
  final String resolution;
  final String videoBitrate;
  final String frameRate;
  final String gifFrameRate;
  final String? gifFrameRateCustom;
  final String gifScale;
  final String gifMaxColors;
  final String gifDitherAlgorithm;
  final String gifLoopMode;

  ConversionOptions({
    this.lossless = true,
    this.quality = 100,
    this.codec,
    this.bitrate,
    this.compressionAlgorithm,
    this.overwrite = false,
    this.gpuAcceleration = false,
    this.audioQuality = 100,
    this.audioCodec = source,
    this.audioBitrate = source,
    this.sampleRate = source,
    this.channels = source,
    this.imageQuality = 100,
    this.imageScalePercent = 100,
    this.colorSpace = source,
    this.preserveMetadata = true,
    this.forceVideoReencode = false,
    this.forceAudioReencode = false,
    this.videoQuality = 100,
    this.videoCodec = source,
    this.resolution = source,
    this.videoBitrate = source,
    this.frameRate = source,
    this.gifFrameRate = source,
    this.gifFrameRateCustom,
    this.gifScale = source,
    this.gifMaxColors = source,
    this.gifDitherAlgorithm = source,
    this.gifLoopMode = source,
  });

  ConversionOptions copyWith({
    bool? lossless,
    int? quality,
    String? codec,
    String? bitrate,
    String? compressionAlgorithm,
    bool? overwrite,
    bool? gpuAcceleration,
    int? audioQuality,
    String? audioCodec,
    String? audioBitrate,
    String? sampleRate,
    String? channels,
    int? imageQuality,
    int? imageScalePercent,
    String? colorSpace,
    bool? preserveMetadata,
    bool? forceVideoReencode,
    bool? forceAudioReencode,
    int? videoQuality,
    String? videoCodec,
    String? resolution,
    String? videoBitrate,
    String? frameRate,
    String? gifFrameRate,
    String? gifFrameRateCustom,
    String? gifScale,
    String? gifMaxColors,
    String? gifDitherAlgorithm,
    String? gifLoopMode,
  }) {
    return ConversionOptions(
      lossless: lossless ?? this.lossless,
      quality: quality ?? this.quality,
      codec: codec ?? this.codec,
      bitrate: bitrate ?? this.bitrate,
      compressionAlgorithm: compressionAlgorithm ?? this.compressionAlgorithm,
      overwrite: overwrite ?? this.overwrite,
      gpuAcceleration: gpuAcceleration ?? this.gpuAcceleration,
      audioQuality: audioQuality ?? this.audioQuality,
      audioCodec: audioCodec ?? this.audioCodec,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      imageQuality: imageQuality ?? this.imageQuality,
      imageScalePercent: imageScalePercent ?? this.imageScalePercent,
      colorSpace: colorSpace ?? this.colorSpace,
      preserveMetadata: preserveMetadata ?? this.preserveMetadata,
      forceVideoReencode: forceVideoReencode ?? this.forceVideoReencode,
      forceAudioReencode: forceAudioReencode ?? this.forceAudioReencode,
      videoQuality: videoQuality ?? this.videoQuality,
      videoCodec: videoCodec ?? this.videoCodec,
      resolution: resolution ?? this.resolution,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      frameRate: frameRate ?? this.frameRate,
      gifFrameRate: gifFrameRate ?? this.gifFrameRate,
      gifFrameRateCustom: gifFrameRateCustom ?? this.gifFrameRateCustom,
      gifScale: gifScale ?? this.gifScale,
      gifMaxColors: gifMaxColors ?? this.gifMaxColors,
      gifDitherAlgorithm: gifDitherAlgorithm ?? this.gifDitherAlgorithm,
      gifLoopMode: gifLoopMode ?? this.gifLoopMode,
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
        'audio_quality': audioQuality,
        'audio_codec': audioCodec,
        'audio_bitrate': audioBitrate,
        'sample_rate': sampleRate,
        'channels': channels,
        'image_quality': imageQuality,
        'image_scale_percent': imageScalePercent,
        'color_space': colorSpace,
        'preserve_metadata': preserveMetadata,
        'force_video_reencode': forceVideoReencode,
        'force_audio_reencode': forceAudioReencode,
        'video_quality': videoQuality,
        'video_codec': videoCodec,
        'resolution': resolution,
        'video_bitrate': videoBitrate,
        'frame_rate': frameRate,
        'gif_frame_rate': gifFrameRate,
        'gif_frame_rate_custom': gifFrameRateCustom,
        'gif_scale': gifScale,
        'gif_max_colors': gifMaxColors,
        'gif_dither_algorithm': gifDitherAlgorithm,
        'gif_loop_mode': gifLoopMode,
      };
}

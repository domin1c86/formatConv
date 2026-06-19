class MediaOperationOptions {
  final String operation;
  final bool splitVideo;
  final bool splitAudio;
  final bool autoMerge;
  final bool removeSourceAudio;
  final List<String> inputs;
  final String outputDirectory;
  final String outputPath;
  final bool overwrite;

  const MediaOperationOptions({
    required this.operation,
    this.splitVideo = false,
    this.splitAudio = false,
    this.autoMerge = false,
    this.removeSourceAudio = false,
    required this.inputs,
    this.outputDirectory = '',
    this.outputPath = '',
    this.overwrite = false,
  });

  Map<String, dynamic> toJson() => {
        'operation': operation,
        'split_video': splitVideo,
        'split_audio': splitAudio,
        'auto_merge': autoMerge,
        'remove_source_audio': removeSourceAudio,
        'inputs': inputs,
        'output_directory': outputDirectory,
        'output_path': outputPath,
        'overwrite': overwrite,
      };
}

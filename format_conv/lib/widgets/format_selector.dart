import 'package:flutter/material.dart';

import '../models/conversion_options.dart';
import 'format_card.dart';

const _videoExtensions = {'.mp4', '.mkv', '.mov', '.avi', '.webm', '.flv', '.wmv', '.mpeg', '.3gp'};
const _imageExtensions = {'.jpeg', '.jpg', '.png', '.webp', '.tiff', '.tif', '.bmp', '.gif', '.ico', '.svg'};
const _audioExtensions = {'.mp3', '.flac', '.wav', '.aac', '.ogg', '.wma', '.m4a', '.opus'};

const _videoFormats = ['MP4', 'MKV', 'MOV', 'AVI', 'WebM', 'FLV', 'WMV', 'MPEG', '3GP'];
const _imageFormats = ['JPEG', 'PNG', 'WebP', 'TIFF', 'BMP', 'GIF', 'ICO', 'SVG'];
const _audioFormats = ['MP3', 'FLAC', 'WAV', 'AAC', 'OGG', 'WMA', 'M4A', 'OPUS'];

class FormatSelector extends StatefulWidget {
  final List<String> selectedFiles;
  final Function(String format, ConversionOptions options) onConvert;

  const FormatSelector({
    super.key,
    required this.selectedFiles,
    required this.onConvert,
  });

  @override
  State<FormatSelector> createState() => _FormatSelectorState();
}

class _FormatSelectorState extends State<FormatSelector> {
  final Map<String, ConversionOptions> _formatOptions = {};
  bool _overwrite = false;

  ConversionOptions _getOptions(String format) {
    return _formatOptions[format] ?? ConversionOptions(overwrite: _overwrite);
  }

  void _updateOptions(String format, ConversionOptions options) {
    setState(() {
      _formatOptions[format] = options.copyWith(overwrite: _overwrite);
    });
  }

  bool _hasType(Set<String> extensions) {
    return widget.selectedFiles.any((f) {
      final lower = f.toLowerCase();
      return extensions.any((ext) => lower.endsWith(ext));
    });
  }

  void _handleConvert(String format) {
    if (widget.selectedFiles.isEmpty) return;
    final options = _getOptions(format);
    widget.onConvert(format, options);
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _hasType(_videoExtensions);
    final hasImage = _hasType(_imageExtensions);
    final hasAudio = _hasType(_audioExtensions);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Select Output Format',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _overwrite,
                      onChanged: (v) {
                        setState(() {
                          _overwrite = v ?? false;
                          _formatOptions.updateAll(
                            (_, opts) => opts.copyWith(overwrite: _overwrite),
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Overwrite', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.selectedFiles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Select files first, then click a format to convert',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          if (hasVideo) ...[
            const Text('Video Formats:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _videoFormats.map((f) => SizedBox(
                width: 200,
                child: FormatCard(
                  format: f,
                  draggedFiles: widget.selectedFiles,
                  options: _getOptions(f),
                  onTap: () => _handleConvert(f),
                  onOptionsChanged: (opts) => _updateOptions(f, opts),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (hasImage) ...[
            const Text('Image Formats:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _imageFormats.map((f) => SizedBox(
                width: 200,
                child: FormatCard(
                  format: f,
                  draggedFiles: widget.selectedFiles,
                  options: _getOptions(f),
                  onTap: () => _handleConvert(f),
                  onOptionsChanged: (opts) => _updateOptions(f, opts),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (hasAudio) ...[
            const Text('Audio Formats:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _audioFormats.map((f) => SizedBox(
                width: 200,
                child: FormatCard(
                  format: f,
                  draggedFiles: widget.selectedFiles,
                  options: _getOptions(f),
                  onTap: () => _handleConvert(f),
                  onOptionsChanged: (opts) => _updateOptions(f, opts),
                ),
              )).toList(),
            ),
          ],
          if (!hasVideo && !hasImage && !hasAudio && widget.selectedFiles.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Unsupported file type',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

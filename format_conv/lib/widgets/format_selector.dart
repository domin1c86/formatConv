import 'package:flutter/material.dart';
import 'format_card.dart';

const _videoExtensions = {'.mp4', '.mkv', '.mov', '.avi', '.webm', '.flv', '.wmv', '.mpeg', '.3gp'};
const _imageExtensions = {'.jpeg', '.jpg', '.png', '.webp', '.tiff', '.tif', '.bmp', '.gif', '.ico', '.svg'};
const _audioExtensions = {'.mp3', '.flac', '.wav', '.aac', '.ogg', '.wma', '.m4a', '.opus'};

const _videoFormats = ['MP4', 'MKV', 'MOV', 'AVI', 'WebM', 'FLV', 'WMV', 'MPEG', '3GP'];
const _imageFormats = ['JPEG', 'PNG', 'WebP', 'TIFF', 'BMP', 'GIF', 'ICO', 'SVG'];
const _audioFormats = ['MP3', 'FLAC', 'WAV', 'AAC', 'OGG', 'WMA', 'M4A', 'OPUS'];

class FormatSelector extends StatelessWidget {
  final List<String> selectedFiles;
  final Function(String) onFormatSelected;

  const FormatSelector({
    super.key,
    required this.selectedFiles,
    required this.onFormatSelected,
  });

  bool _hasType(Set<String> extensions) {
    return selectedFiles.any((f) {
      final lower = f.toLowerCase();
      return extensions.any((ext) => lower.endsWith(ext));
    });
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
          const Text(
            'Select Output Format',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (hasVideo) ...[
            const Text('Video Formats:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _videoFormats
                  .map((f) => FormatCard(format: f, isSelected: false, onTap: () => onFormatSelected(f)))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (hasImage) ...[
            const Text('Image Formats:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _imageFormats
                  .map((f) => FormatCard(format: f, isSelected: false, onTap: () => onFormatSelected(f)))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (hasAudio) ...[
            const Text('Audio Formats:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _audioFormats
                  .map((f) => FormatCard(format: f, isSelected: false, onTap: () => onFormatSelected(f)))
                  .toList(),
            ),
          ],
          if (!hasVideo && !hasImage && !hasAudio)
            const Text(
              'Select files to see available output formats',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

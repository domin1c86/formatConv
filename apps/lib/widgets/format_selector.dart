import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/conversion_options.dart';
import 'format_card.dart';

const _videoExtensions = {'.mp4', '.mkv', '.mov', '.avi', '.webm', '.flv', '.wmv', '.mpeg', '.3gp'};
const _imageExtensions = {'.jpeg', '.jpg', '.png', '.webp', '.tiff', '.tif', '.bmp', '.gif', '.ico', '.svg'};
const _audioExtensions = {'.mp3', '.flac', '.wav', '.aac', '.ogg', '.wma', '.m4a', '.opus'};

const _videoFormats = ['MP4', 'MKV', 'MOV', 'AVI', 'WebM', 'FLV', 'WMV', 'MPEG', '3GP'];
const _imageFormats = ['JPEG', 'PNG', 'WebP', 'TIFF', 'BMP', 'GIF', 'ICO', 'SVG'];
const _audioFormats = ['MP3', 'FLAC', 'WAV', 'AAC', 'OGG', 'WMA', 'M4A', 'OPUS'];

class FormatSelector extends StatefulWidget {
  final AppStrings strings;
  final List<String> selectedFiles;
  final Function(String format, ConversionOptions options) onConvert;

  const FormatSelector({
    super.key,
    required this.strings,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = _cardWidth(constraints.maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 240, maxWidth: 560),
                  child: Text(
                    widget.strings.outputFormat,
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _OverwriteToggle(
                  label: widget.strings.overwrite,
                  value: _overwrite,
                  onChanged: (value) {
                    setState(() {
                      _overwrite = value;
                      _formatOptions.updateAll(
                        (_, opts) => opts.copyWith(overwrite: _overwrite),
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.selectedFiles.isEmpty)
              Text(
                widget.strings.emptyFormatHint,
                style: const TextStyle(
                  color: Color(0xFF7A7A7A),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            const SizedBox(height: 20),
            if (hasVideo)
              _FormatGroup(
                title: widget.strings.videoFormats,
                formats: _videoFormats,
                cardWidth: cardWidth,
                strings: widget.strings,
                getOptions: _getOptions,
                onConvert: _handleConvert,
                onOptionsChanged: _updateOptions,
                selectedFiles: widget.selectedFiles,
              ),
            if (hasImage)
              _FormatGroup(
                title: widget.strings.imageFormats,
                formats: _imageFormats,
                cardWidth: cardWidth,
                strings: widget.strings,
                getOptions: _getOptions,
                onConvert: _handleConvert,
                onOptionsChanged: _updateOptions,
                selectedFiles: widget.selectedFiles,
              ),
            if (hasAudio)
              _FormatGroup(
                title: widget.strings.audioFormats,
                formats: _audioFormats,
                cardWidth: cardWidth,
                strings: widget.strings,
                getOptions: _getOptions,
                onConvert: _handleConvert,
                onOptionsChanged: _updateOptions,
                selectedFiles: widget.selectedFiles,
              ),
            if (!hasVideo && !hasImage && !hasAudio && widget.selectedFiles.isNotEmpty)
              Text(
                widget.strings.unsupportedFileType,
                style: const TextStyle(color: Color(0xFFB35A00), fontSize: 14),
              ),
          ],
        );
      },
    );
  }

  double _cardWidth(double width) {
    if (width < 520) return width;
    if (width < 760) return (width - 12) / 2;
    final columns = width >= 1160 ? 4 : 3;
    return math.max(190, (width - (columns - 1) * 12) / columns);
  }
}

class _OverwriteToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OverwriteToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onChanged(!value),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: (changed) => onChanged(changed ?? false),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatGroup extends StatelessWidget {
  final String title;
  final List<String> formats;
  final double cardWidth;
  final AppStrings strings;
  final ConversionOptions Function(String format) getOptions;
  final ValueChanged<String> onConvert;
  final void Function(String format, ConversionOptions options) onOptionsChanged;
  final List<String> selectedFiles;

  const _FormatGroup({
    required this.title,
    required this.formats,
    required this.cardWidth,
    required this.strings,
    required this.getOptions,
    required this.onConvert,
    required this.onOptionsChanged,
    required this.selectedFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: formats.map((format) {
              return SizedBox(
                width: cardWidth,
                child: FormatCard(
                  strings: strings,
                  format: format,
                  draggedFiles: selectedFiles,
                  options: getOptions(format),
                  onTap: () => onConvert(format),
                  onOptionsChanged: (opts) => onOptionsChanged(format, opts),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

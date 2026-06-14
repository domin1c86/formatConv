import 'package:flutter/material.dart';

import '../models/conversion_options.dart';
import '../utils/format_descriptions.dart';

class FormatCard extends StatelessWidget {
  final String format;
  final List<String> draggedFiles;
  final ConversionOptions options;
  final VoidCallback onTap;
  final ValueChanged<ConversionOptions> onOptionsChanged;

  const FormatCard({
    super.key,
    required this.format,
    required this.draggedFiles,
    required this.options,
    required this.onTap,
    required this.onOptionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final desc = formatDescriptions[format];
    final codecs = formatCodecs[format];
    final tooltipText = desc != null
        ? '${desc.description}\n\nFeatures:\n${desc.features.map((f) => '• $f').join('\n')}'
        : format;

    return DragTarget<List<String>>(
      onWillAcceptWithDetails: (details) => details.data.isNotEmpty,
      onAcceptWithDetails: (details) => onTap(),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Tooltip(
          message: tooltipText,
          waitDuration: const Duration(milliseconds: 400),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isHovering ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHovering ? Colors.blue : Colors.grey[300]!,
                width: isHovering ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      '-> $format',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _QualityChip(
                            label: 'Lossless',
                            selected: options.lossless,
                            onTap: () => onOptionsChanged(
                              options.copyWith(lossless: true, quality: 100),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _QualityChip(
                            label: 'Lossy',
                            selected: !options.lossless,
                            onTap: () => onOptionsChanged(
                              options.copyWith(lossless: false),
                            ),
                          ),
                        ],
                      ),
                      if (!options.lossless) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: Colors.blue,
                                  thumbColor: Colors.blue,
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14,
                                  ),
                                ),
                                child: Slider(
                                  value: options.quality.toDouble(),
                                  min: 0,
                                  max: 100,
                                  divisions: 10,
                                  onChanged: (v) => onOptionsChanged(
                                    options.copyWith(quality: v.round()),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${options.quality}%',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (codecs != null && codecs.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: codecs.map((codec) {
                              final selected = options.codec == codec;
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _QualityChip(
                                  label: codec,
                                  selected: selected,
                                  onTap: () => onOptionsChanged(
                                    options.copyWith(
                                      codec: selected ? null : codec,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QualityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QualityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

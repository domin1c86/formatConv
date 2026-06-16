import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/conversion_options.dart';
import '../utils/format_descriptions.dart';

class FormatCard extends StatelessWidget {
  final AppStrings strings;
  final String format;
  final List<String> draggedFiles;
  final ConversionOptions options;
  final VoidCallback onTap;
  final ValueChanged<ConversionOptions> onOptionsChanged;

  const FormatCard({
    super.key,
    required this.strings,
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
        ? '${desc.description}\n\nFeatures:\n${desc.features.map((f) => '- $f').join('\n')}'
        : format;

    return DragTarget<List<String>>(
      onWillAcceptWithDetails: (details) => details.data.isNotEmpty,
      onAcceptWithDetails: (details) => onTap(),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final primary = Theme.of(context).colorScheme.primary;

        return Tooltip(
          message: tooltipText,
          waitDuration: const Duration(milliseconds: 400),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isHovering ? primary : const Color(0xFFE0E0E0),
                width: isHovering ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  hoverColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            format,
                            style: const TextStyle(
                              fontSize: 21,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${strings.convertTo} $format',
                  style: const TextStyle(
                    color: Color(0xFF7A7A7A),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _QualityChip(
                      label: strings.lossless,
                      selected: options.lossless,
                      onTap: () => onOptionsChanged(
                        options.copyWith(lossless: true, quality: 100),
                      ),
                    ),
                    _QualityChip(
                      label: strings.lossy,
                      selected: !options.lossless,
                      onTap: () => onOptionsChanged(
                        options.copyWith(lossless: false),
                      ),
                    ),
                  ],
                ),
                if (!options.lossless) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
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
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${options.quality}%',
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
                if (codecs != null && codecs.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: codecs.map((codec) {
                        final selected = options.codec == codec;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _QualityChip(
                            label: codec,
                            selected: selected,
                            onTap: () => onOptionsChanged(
                              options.copyWith(codec: selected ? null : codec),
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
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      hoverColor: primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? primary : const Color(0xFFFAFAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? primary : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: selected ? Colors.white : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

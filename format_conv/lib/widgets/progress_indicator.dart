import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

class ConversionProgress extends StatelessWidget {
  final AppStrings strings;
  final double progress;
  final VoidCallback onCancel;

  const ConversionProgress({
    super.key,
    required this.strings,
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xEAF5F5F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final progressInfo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    strings.converting,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(clampedProgress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: clampedProgress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
              ),
            ],
          );

          final cancelButton = OutlinedButton(
            onPressed: onCancel,
            child: Text(strings.cancel),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                progressInfo,
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: cancelButton,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: progressInfo),
              const SizedBox(width: 16),
              cancelButton,
            ],
          );
        },
      ),
    );
  }
}

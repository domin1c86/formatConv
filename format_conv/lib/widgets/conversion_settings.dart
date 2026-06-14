import 'package:flutter/material.dart';

class ConversionSettings extends StatefulWidget {
  final String? selectedFormat;
  final VoidCallback onConvert;

  const ConversionSettings({
    super.key,
    required this.selectedFormat,
    required this.onConvert,
  });

  @override
  State<ConversionSettings> createState() => _ConversionSettingsState();
}

class _ConversionSettingsState extends State<ConversionSettings> {
  bool lossless = true;
  int quality = 100;
  bool overwrite = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conversion Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Quality:'),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Lossless'),
                selected: lossless,
                onSelected: (selected) {
                  setState(() {
                    lossless = true;
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Lossy'),
                selected: !lossless,
                onSelected: (selected) {
                  setState(() {
                    lossless = false;
                  });
                },
              ),
            ],
          ),
          if (!lossless) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Quality Level:'),
                Expanded(
                  child: Slider(
                    value: quality.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: quality.toString(),
                    onChanged: (value) {
                      setState(() {
                        quality = value.round();
                      });
                    },
                  ),
                ),
                Text('$quality%'),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: overwrite,
                onChanged: (value) {
                  setState(() {
                    overwrite = value ?? false;
                  });
                },
              ),
              const Text('Overwrite existing files'),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.selectedFormat != null ? widget.onConvert : null,
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }
}

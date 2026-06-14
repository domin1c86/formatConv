import 'package:flutter/material.dart';

class ConversionProgress extends StatelessWidget {
  final double progress;
  final VoidCallback onCancel;

  const ConversionProgress({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Converting...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
          ),
          const SizedBox(height: 8),
          Text('${(progress * 100).toStringAsFixed(1)}%'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

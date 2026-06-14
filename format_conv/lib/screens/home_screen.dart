import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/conversion_provider.dart';
import '../widgets/file_selector.dart';
import '../widgets/format_selector.dart';
import '../widgets/preview_panel.dart';
import '../widgets/progress_indicator.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(conversionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Format Converter'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: FileSelector(
              onFilesSelected: provider.selectFiles,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: FormatSelector(
                      selectedFiles: provider.selectedFiles,
                      onConvert: provider.startConversion,
                    ),
                  ),
                ),
                if (provider.selectedFiles.isNotEmpty ||
                    provider.results.isNotEmpty)
                  FilePreviewPanel(
                    selectedFiles: provider.selectedFiles,
                    results: provider.results,
                  ),
                if (provider.isConverting)
                  ConversionProgress(
                    progress: provider.progress,
                    onCancel: provider.cancelConversion,
                  ),
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.error!,
                              style: TextStyle(color: Colors.red[700], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

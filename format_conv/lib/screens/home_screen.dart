import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/conversion_provider.dart';
import '../widgets/file_selector.dart';
import '../widgets/format_selector.dart';
import '../widgets/preview_panel.dart';
import '../widgets/progress_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConversionProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Format Converter'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Consumer<ConversionProvider>(
          builder: (context, provider, child) {
            return Row(
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
                          child: Text(
                            'Error: ${provider.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

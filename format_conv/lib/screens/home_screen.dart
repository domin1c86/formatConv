import 'package:flutter/material.dart';
import '../widgets/file_selector.dart';
import '../widgets/format_selector.dart';
import '../widgets/conversion_settings.dart';
import '../widgets/progress_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> selectedFiles = [];
  String? selectedFormat;
  bool isConverting = false;
  double progress = 0.0;

  @override
  Widget build(BuildContext context) {
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
              onFilesSelected: (files) {
                setState(() {
                  selectedFiles = files;
                });
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                FormatSelector(
                  selectedFiles: selectedFiles,
                  onFormatSelected: (format) {
                    setState(() {
                      selectedFormat = format;
                    });
                  },
                ),
                ConversionSettings(
                  selectedFormat: selectedFormat,
                  onConvert: () {
                    // TODO: Start conversion
                  },
                ),
                if (isConverting)
                  ConversionProgress(
                    progress: progress,
                    onCancel: () {
                      // TODO: Cancel conversion
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

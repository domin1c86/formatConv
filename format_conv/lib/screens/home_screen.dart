import 'package:flutter/material.dart';

import '../models/conversion_options.dart';
import '../models/conversion_status.dart';
import '../services/conversion_service.dart';
import '../widgets/file_selector.dart';
import '../widgets/format_selector.dart';
import '../widgets/preview_panel.dart';
import '../widgets/progress_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ConversionService _conversionService = ConversionService();
  List<String> selectedFiles = [];
  bool isConverting = false;
  double progress = 0.0;
  final Map<String, ConversionResult> results = {};

  Future<void> _startConversion(String format, ConversionOptions options) async {
    if (selectedFiles.isEmpty) return;

    setState(() {
      isConverting = true;
      progress = 0.0;
      results.clear();
    });

    try {
      for (final file in selectedFiles) {
        final outputPath = _generateOutputPath(file, format);
        try {
          final conversionId = await _conversionService.convertFile(
            file,
            outputPath,
            options,
            (id, p, processed, total, status, error) {
              if (mounted) {
                setState(() => progress = p);
              }
            },
          );

          ConversionStatus? conversionStatus;
          do {
            await Future.delayed(const Duration(milliseconds: 100));
            conversionStatus = await _conversionService.getConversionStatus(conversionId);
            if (conversionStatus != null && mounted) {
              setState(() => progress = conversionStatus!.progress);
            }
          } while (conversionStatus != null &&
              conversionStatus.status == 'processing');

          if (mounted) {
            results[file] = ConversionResult(
              outputPath: outputPath,
              success: conversionStatus?.status == 'completed',
              error: conversionStatus?.error,
            );
          }
        } catch (e) {
          if (mounted) {
            results[file] = ConversionResult(
              outputPath: outputPath,
              success: false,
              error: e.toString(),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => isConverting = false);
      }
    }
  }

  String _generateOutputPath(String inputPath, String format) {
    final lastDot = inputPath.lastIndexOf('.');
    final basePath = lastDot > 0 ? inputPath.substring(0, lastDot) : inputPath;
    return '$basePath.${format.toLowerCase()}';
  }

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
            child: Column(
              children: [
                Expanded(
                  child: FileSelector(
                    onFilesSelected: (files) {
                      setState(() {
                        selectedFiles = files;
                        results.clear();
                      });
                    },
                  ),
                ),
                if (selectedFiles.isNotEmpty || results.isNotEmpty)
                  Expanded(
                    child: FilePreviewPanel(
                      selectedFiles: selectedFiles,
                      results: results,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: FormatSelector(
                      selectedFiles: selectedFiles,
                      onConvert: _startConversion,
                    ),
                  ),
                ),
                if (isConverting)
                  ConversionProgress(
                    progress: progress,
                    onCancel: () {
                      // TODO: Cancel conversion via service
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

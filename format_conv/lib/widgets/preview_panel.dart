import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../utils/format_descriptions.dart';

class FilePreviewPanel extends StatelessWidget {
  final List<String> selectedFiles;
  final Map<String, ConversionResult> results;

  const FilePreviewPanel({
    super.key,
    required this.selectedFiles,
    this.results = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (selectedFiles.isEmpty && results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedFiles.isNotEmpty) ...[
            Text(
              'Selected Files',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...selectedFiles.map((f) => _FileInfoCard(filePath: f)),
          ],
          if (results.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Conversion Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...results.entries.map((e) => _ResultCard(
              inputPath: e.key,
              result: e.value,
            )),
          ],
        ],
      ),
    );
  }
}

class ConversionResult {
  final String outputPath;
  final bool success;
  final String? error;

  const ConversionResult({
    required this.outputPath,
    required this.success,
    this.error,
  });
}

class _FileInfoCard extends StatelessWidget {
  final String filePath;

  const _FileInfoCard({required this.filePath});

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final exists = file.existsSync();
    final size = exists ? file.lengthSync() : 0;
    final sizeStr = _formatSize(size);
    final ext = p.extension(filePath).replaceFirst('.', '').toUpperCase();
    final name = p.basename(filePath);

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insert_drive_file, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$ext  •  $sizeStr',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _ResultCard extends StatelessWidget {
  final String inputPath;
  final ConversionResult result;

  const _ResultCard({required this.inputPath, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.basename(inputPath),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!result.success && result.error != null)
                    Text(
                      result.error!,
                      style: TextStyle(fontSize: 12, color: Colors.red[600]),
                    ),
                ],
              ),
            ),
            if (result.success)
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                tooltip: 'Open with system default app',
                onPressed: () => _openFile(result.outputPath),
              ),
          ],
        ),
      ),
    );
  }

  void _openFile(String path) {
    if (Platform.isWindows) {
      Process.run('start', ['', path], runInShell: true);
    } else if (Platform.isMacOS) {
      Process.run('open', [path]);
    } else {
      Process.run('xdg-open', [path]);
    }
  }
}

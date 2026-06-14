import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/format_info.dart';
import '../services/conversion_service.dart';

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

class _FileInfoCard extends StatefulWidget {
  final String filePath;

  const _FileInfoCard({required this.filePath});

  @override
  State<_FileInfoCard> createState() => _FileInfoCardState();
}

class _FileInfoCardState extends State<_FileInfoCard> {
  FormatInfo? _formatInfo;

  @override
  void initState() {
    super.initState();
    _detectFormat();
  }

  Future<void> _detectFormat() async {
    try {
      final service = ConversionService();
      final info = await service.detectFormat(widget.filePath);
      if (mounted && info != null) {
        setState(() => _formatInfo = info);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.filePath);
    final exists = file.existsSync();
    final size = exists ? file.lengthSync() : 0;
    final sizeStr = _formatSize(size);
    final ext = p.extension(widget.filePath).replaceFirst('.', '').toUpperCase();
    final name = p.basename(widget.filePath);

    final width = _formatInfo?.properties['width'];
    final height = _formatInfo?.properties['height'];
    final duration = _formatInfo?.properties['duration'];
    final resolution = (width != null && height != null) ? '${width}x$height' : null;
    final durationStr = duration != null ? _formatDuration(duration) : null;

    return Draggable<List<String>>(
      data: [widget.filePath],
      feedback: Material(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.blue[100],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 6),
              Text(name, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildCard(name, ext, sizeStr, resolution, durationStr),
      ),
      child: _buildCard(name, ext, sizeStr, resolution, durationStr),
    );
  }

  Widget _buildCard(String name, String ext, String sizeStr, String? resolution, String? durationStr) {
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
              [ext, sizeStr, if (resolution != null) resolution, if (durationStr != null) durationStr].join('  •  '),
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

  String _formatDuration(String seconds) {
    final totalSeconds = double.tryParse(seconds);
    if (totalSeconds == null) return seconds;
    final mins = totalSeconds ~/ 60;
    final secs = (totalSeconds % 60).round();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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

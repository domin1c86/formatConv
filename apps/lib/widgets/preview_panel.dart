import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_strings.dart';
import '../models/format_info.dart';
import '../services/conversion_service.dart';

class FilePreviewPanel extends StatelessWidget {
  final AppStrings strings;
  final List<String> selectedFiles;
  final Map<String, ConversionResult> results;

  const FilePreviewPanel({
    super.key,
    required this.strings,
    required this.selectedFiles,
    this.results = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (selectedFiles.isEmpty && results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedFiles.isNotEmpty) ...[
          Text(
            strings.selectedFiles,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          ...selectedFiles.map((f) => _FileInfoCard(filePath: f)),
        ],
        if (results.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            strings.conversionResults,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          ...results.entries.map((e) => _ResultCard(
                strings: strings,
                inputPath: e.key,
                result: e.value,
              )),
        ],
      ],
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
        color: Colors.transparent,
        child: _PreviewCard(
          name: name,
          details: _details(ext, sizeStr, resolution, durationStr),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.45,
        child: _PreviewCard(
          name: name,
          details: _details(ext, sizeStr, resolution, durationStr),
        ),
      ),
      child: _PreviewCard(
        name: name,
        details: _details(ext, sizeStr, resolution, durationStr),
      ),
    );
  }

  String _details(String ext, String sizeStr, String? resolution, String? durationStr) {
    return [
      ext,
      sizeStr,
      if (resolution != null) resolution,
      if (durationStr != null) durationStr,
    ].join(' - ');
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

class _PreviewCard extends StatelessWidget {
  final String name;
  final String details;

  const _PreviewCard({
    required this.name,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file, size: 20, color: Color(0xFF7A7A7A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            details,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7A7A7A)),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final AppStrings strings;
  final String inputPath;
  final ConversionResult result;

  const _ResultCard({
    required this.strings,
    required this.inputPath,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Icon(
            result.success ? Icons.check_circle : Icons.error,
            color: result.success ? const Color(0xFF15803D) : const Color(0xFFB00020),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.basename(inputPath),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!result.success && result.error != null)
                  Text(
                    result.error!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB00020)),
                  ),
              ],
            ),
          ),
          if (result.success)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              tooltip: strings.openFile,
              onPressed: () => _openFile(result.outputPath),
            ),
        ],
      ),
    );
  }

  void _openFile(String path) {
    if (Platform.isWindows) {
      Process.run('start', ['', path], runInShell: true);
    }
  }
}

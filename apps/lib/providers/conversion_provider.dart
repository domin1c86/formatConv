import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../models/conversion_options.dart';
import '../models/conversion_result.dart';
import '../models/conversion_status.dart';
import '../services/conversion_service.dart';
import '../utils/format_descriptions.dart';

final conversionProvider = ChangeNotifierProvider<ConversionProvider>((ref) {
  return ConversionProvider();
});

class ConversionProvider extends ChangeNotifier {
  final ConversionService _service = ConversionService();

  List<String> _selectedFiles = [];
  String? _selectedFormat;
  bool _isConverting = false;
  double _progress = 0.0;
  ConversionStatus? _currentStatus;
  String? _error;
  final Map<String, ConversionResult> _results = {};

  List<String> get selectedFiles => _selectedFiles;
  String? get selectedFormat => _selectedFormat;
  bool get isConverting => _isConverting;
  double get progress => _progress;
  ConversionStatus? get currentStatus => _currentStatus;
  String? get error => _error;
  Map<String, ConversionResult> get results => _results;

  static final Set<String> supportedFormats =
      formatDescriptions.keys.map((k) => k.toUpperCase()).toSet();

  void selectFiles(List<String> files) {
    addFiles(files, replace: true);
  }

  void addFiles(List<String> files, {bool replace = false}) {
    final normalized = files.where((file) => file.trim().isNotEmpty).toList();
    if (replace) {
      _selectedFiles = [];
    }
    _selectedFiles = [
      ..._selectedFiles,
      ...normalized.where((file) => !_selectedFiles.contains(file)),
    ];
    _results.clear();
    notifyListeners();
  }

  void selectFormat(String format) {
    _selectedFormat = format;
    notifyListeners();
  }

  bool _validateFile(String file) {
    final f = File(file);
    if (!f.existsSync()) {
      return false;
    }
    try {
      f.statSync();
      f.openSync(mode: FileMode.read).closeSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _checkOutputWritable(String outputPath) {
    final dir = p.dirname(outputPath);
    final testFile = File(p.join(dir, '.formatconv_write_test'));
    try {
      Directory(dir).createSync(recursive: true);
      testFile.writeAsStringSync('');
      testFile.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkDiskSpace(String outputPath, int inputSizeBytes) async {
    try {
      final dir = p.dirname(outputPath);
      ProcessResult result;
      if (Platform.isWindows) {
        final drive = p.rootPrefix(dir);
        result = await Process.run('wmic', [
          'logicaldisk',
          'where',
          'DeviceID="$drive"',
          'get',
          'FreeSpace',
          '/value',
        ]);
        final output = result.stdout.toString();
        final match = RegExp(r'FreeSpace=(\d+)').firstMatch(output);
        if (match != null) {
          final freeSpace = int.parse(match.group(1)!);
          return freeSpace > inputSizeBytes;
        }
      } else {
        result = await Process.run('df', ['-B1', dir]);
        final lines = result.stdout.toString().split('\n');
        if (lines.length >= 2) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final freeSpace = int.parse(parts[3]);
            return freeSpace > inputSizeBytes;
          }
        }
      }
    } catch (_) {}
    return true;
  }

  String _friendlyError(String file, String type) {
    switch (type) {
      case 'not_found':
        return 'File not found: ${p.basename(file)}\n'
            'Suggestion: The file may have been moved or deleted. '
            'Re-select the file and try again.';
      case 'permission_read':
        return 'Cannot read file: ${p.basename(file)}\n'
            'Suggestion: Close any applications using this file, '
            'then check that you have read permission.';
      case 'permission_write':
        return 'Cannot write to the output folder.\n'
            'Suggestion: Choose a different output location or '
            'run the application with write permissions.';
      case 'no_space':
        return 'Not enough disk space for conversion.\n'
            'Suggestion: Free up disk space or choose an output '
            'folder on a drive with more available space.';
      case 'unsupported_format':
        return 'Unsupported output format: $file\n'
            'Suggestion: Choose one of the supported formats '
            '(${supportedFormats.take(5).join(", ")}, ...).';
      default:
        return file;
    }
  }

  Future<void> startConversion(
    String format,
    ConversionOptions options, {
    List<String>? files,
    AppSettings? settings,
    ValueChanged<ConversionResult>? onResult,
  }) async {
    final targetFiles = files ?? _selectedFiles;
    if (targetFiles.isEmpty) return;

    final normalizedFormat = format.toUpperCase();
    if (!supportedFormats.contains(normalizedFormat)) {
      _error = _friendlyError(format, 'unsupported_format');
      notifyListeners();
      return;
    }

    _selectedFormat = normalizedFormat;
    _isConverting = true;
    _error = null;
    _results.clear();
    notifyListeners();

    try {
      for (final file in targetFiles) {
        final startedAt = DateTime.now();
        if (!File(file).existsSync()) {
          final result = ConversionResult(
            inputPath: file,
            outputPath: '',
            success: false,
            startedAt: startedAt,
            finishedAt: DateTime.now(),
            error: _friendlyError(file, 'not_found'),
          );
          _results[file] = ConversionResult(
            inputPath: result.inputPath,
            outputPath: result.outputPath,
            success: result.success,
            startedAt: result.startedAt,
            finishedAt: result.finishedAt,
            error: result.error,
          );
          onResult?.call(result);
          continue;
        }

        if (!_validateFile(file)) {
          final result = ConversionResult(
            inputPath: file,
            outputPath: '',
            success: false,
            startedAt: startedAt,
            finishedAt: DateTime.now(),
            error: _friendlyError(file, 'permission_read'),
          );
          _results[file] = result;
          onResult?.call(result);
          continue;
        }

        final outputPath = _generateOutputPath(
          file,
          normalizedFormat,
          options.overwrite || (settings?.overwriteSource ?? false),
          settings,
        );

        if (!_checkOutputWritable(outputPath)) {
          final result = ConversionResult(
            inputPath: file,
            outputPath: outputPath,
            success: false,
            startedAt: startedAt,
            finishedAt: DateTime.now(),
            error: _friendlyError('', 'permission_write'),
          );
          _results[file] = result;
          onResult?.call(result);
          continue;
        }

        final inputSize = File(file).lengthSync();
        if (!await _checkDiskSpace(outputPath, inputSize)) {
          final result = ConversionResult(
            inputPath: file,
            outputPath: outputPath,
            success: false,
            startedAt: startedAt,
            finishedAt: DateTime.now(),
            error: _friendlyError('', 'no_space'),
          );
          _results[file] = result;
          onResult?.call(result);
          continue;
        }

        try {
          final conversionId = await _service.convertFile(
            file,
            outputPath,
            options,
            (id, progress, processed, total, status, error) {
              _progress = progress;
              notifyListeners();
            },
          );

          try {
            ConversionStatus? conversionStatus;
            do {
              await Future.delayed(const Duration(milliseconds: 100));
              conversionStatus = await _service.getConversionStatus(conversionId);
              if (conversionStatus != null) {
                _currentStatus = conversionStatus;
                _progress = conversionStatus.progress;
                notifyListeners();
              }
            } while (conversionStatus != null &&
                conversionStatus.status == 'processing');

            final failed = conversionStatus?.status != 'completed';
            final result = ConversionResult(
              inputPath: file,
              outputPath: outputPath,
              success: !failed,
              startedAt: startedAt,
              finishedAt: DateTime.now(),
              error: failed
                  ? _mapBackendError(conversionStatus?.error)
                  : null,
            );
            _results[file] = result;
            onResult?.call(result);
          } finally {
            ConversionService.disposeProgressCallback(conversionId);
          }
        } catch (e) {
          final result = ConversionResult(
            inputPath: file,
            outputPath: outputPath,
            success: false,
            startedAt: startedAt,
            finishedAt: DateTime.now(),
            error: _mapBackendError(e.toString()),
          );
          _results[file] = result;
          onResult?.call(result);
        }
      }
    } catch (e) {
      _error = _mapBackendError(e.toString());
    } finally {
      _isConverting = false;
      notifyListeners();
    }
  }

  String _mapBackendError(String? raw) {
    if (raw == null) return 'Unknown error occurred.';
    if (raw.contains('permission') || raw.contains('Permission')) {
      return 'Permission denied.\n'
          'Suggestion: Ensure you have read/write access to both '
          'the input file and output folder.';
    }
    if (raw.contains('No space') || raw.contains('disk full')) {
      return 'Not enough disk space.\n'
          'Suggestion: Free up disk space or choose an output '
          'folder on a drive with more available space.';
    }
    if (raw.contains('codec') || raw.contains('not supported')) {
      return 'The selected codec is not available for this format.\n'
          'Suggestion: Try a different codec or use the default codec.';
    }
    if (raw.contains('corrupt') || raw.contains('invalid')) {
      return 'The input file appears to be corrupt or invalid.\n'
          'Suggestion: Try opening the file in another application to verify it works.';
    }
    return 'Conversion failed: $raw\n'
        'Suggestion: Try again with different settings, or '
        'check that the input file is valid.';
  }

  Future<void> cancelConversion() async {
    if (_currentStatus != null) {
      await _service.cancelConversion(_currentStatus!.conversionId);
      _isConverting = false;
      notifyListeners();
    }
  }

  String _generateOutputPath(
    String inputPath,
    String format,
    bool overwrite,
    AppSettings? settings,
  ) {
    final configuredDir = settings?.defaultOutputDirectory ?? '';
    final dir = configuredDir.isEmpty ? p.dirname(inputPath) : configuredDir;
    final baseName = p.basenameWithoutExtension(inputPath);
    final ext = format.toLowerCase();
    final template = settings?.namingTemplate ?? r'$name$_1';
    final outputBaseName = template.contains(r'$name$')
        ? template.replaceAll(r'$name$', baseName).replaceAll(r'$num$', '1')
        : baseName;
    var outputPath = p.join(dir, '$outputBaseName.$ext');

    if (overwrite) return outputPath;

    int suffix = 1;
    while (File(outputPath).existsSync()) {
      final generatedName = template.contains(r'$name$')
          ? template.replaceAll(r'$name$', baseName).replaceAll(r'$num$', '$suffix')
          : '${baseName}_$suffix';
      outputPath = p.join(dir, '$generatedName.$ext');
      suffix++;
    }
    return outputPath;
  }
}

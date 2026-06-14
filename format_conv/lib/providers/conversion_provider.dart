import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/conversion_options.dart';
import '../models/conversion_status.dart';
import '../services/conversion_service.dart';
import '../widgets/preview_panel.dart';

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

  void selectFiles(List<String> files) {
    _selectedFiles = files;
    _results.clear();
    notifyListeners();
  }

  void selectFormat(String format) {
    _selectedFormat = format;
    notifyListeners();
  }

  Future<void> startConversion(String format, ConversionOptions options) async {
    if (_selectedFiles.isEmpty) return;

    _selectedFormat = format;
    _isConverting = true;
    _error = null;
    _results.clear();
    notifyListeners();

    try {
      for (final file in _selectedFiles) {
        final outputPath = _generateOutputPath(file, format, options.overwrite);
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

          _results[file] = ConversionResult(
            outputPath: outputPath,
            success: conversionStatus?.status == 'completed',
            error: conversionStatus?.error,
          );
        } catch (e) {
          _results[file] = ConversionResult(
            outputPath: outputPath,
            success: false,
            error: e.toString(),
          );
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isConverting = false;
      notifyListeners();
    }
  }

  Future<void> cancelConversion() async {
    if (_currentStatus != null) {
      await _service.cancelConversion(_currentStatus!.conversionId);
      _isConverting = false;
      notifyListeners();
    }
  }

  String _generateOutputPath(String inputPath, String format, bool overwrite) {
    final dir = p.dirname(inputPath);
    final baseName = p.basenameWithoutExtension(inputPath);
    final ext = format.toLowerCase();
    var outputPath = p.join(dir, '$baseName.$ext');

    if (overwrite) return outputPath;

    int suffix = 1;
    while (File(outputPath).existsSync()) {
      outputPath = p.join(dir, '${baseName}_$suffix.$ext');
      suffix++;
    }
    return outputPath;
  }
}

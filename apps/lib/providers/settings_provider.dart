import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/conversion_result.dart';

final settingsProvider = ChangeNotifierProvider<SettingsController>((ref) {
  return SettingsController()..load();
});

class SettingsController extends ChangeNotifier {
  static const _settingsFileName = 'settings.json';
  static const _historyFileName = 'history.json';
  static const _historyLimit = 100;

  AppSettings _settings = const AppSettings();
  List<ConversionResult> _history = [];
  bool _loaded = false;

  AppSettings get settings => _settings;
  List<ConversionResult> get history => List.unmodifiable(_history);
  bool get loaded => _loaded;

  Future<void> load() async {
    final settingsRaw = await _readFile(_settingsFileName);
    final historyRaw = await _readFile(_historyFileName);

    if (settingsRaw != null) {
      try {
        _settings = AppSettings.fromJson(
            jsonDecode(settingsRaw) as Map<String, dynamic>);
      } catch (_) {
        _settings = const AppSettings();
      }
    }

    if (historyRaw != null) {
      try {
        final decoded = jsonDecode(historyRaw) as List<dynamic>;
        _history = decoded
            .whereType<Map<String, dynamic>>()
            .map(ConversionResult.fromJson)
            .toList();
      } catch (_) {
        _history = [];
      }
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> update(AppSettings settings) async {
    _settings = settings;
    // Defer the listener notification off the current synchronous continuation.
    // Native pickers (e.g. file_picker's Win32 folder dialog) finish tearing
    // down their modal window/message pump exactly when the awaiter resumes;
    // notifying synchronously here forces a full widget rebuild inside that
    // unsafe teardown window, which can crash the engine when mounted video
    // previews are driving ffmpeg subprocesses / Image decoders. Letting the
    // native modal close first (one microtask later) avoids the race.
    Future.microtask(notifyListeners);
    await _writeFile(_settingsFileName, jsonEncode(_settings.toJson()));
  }

  Future<void> toggleFormat(String type, String format, bool enabled) async {
    Set<String> next(Set<String> current) {
      final result = {...current};
      enabled ? result.add(format) : result.remove(format);
      return result;
    }

    if (type == 'video') {
      await update(_settings.copyWith(
          visibleVideoFormats: next(_settings.visibleVideoFormats)));
    } else if (type == 'image') {
      await update(_settings.copyWith(
          visibleImageFormats: next(_settings.visibleImageFormats)));
    } else {
      await update(_settings.copyWith(
          visibleAudioFormats: next(_settings.visibleAudioFormats)));
    }
  }

  Future<String?> saveThemeJson(String source, AppStrings strings) async {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        return strings.isZh
            ? '主题 JSON 必须是一个对象。'
            : 'Theme JSON must be an object.';
      }
      await update(_settings.copyWith(
        themeJson: const JsonEncoder.withIndent('  ').convert(decoded),
        cardRadius: (decoded['cardRadius'] as num?)?.toDouble(),
      ));
      return null;
    } catch (e) {
      return strings.isZh ? 'JSON 无效：$e' : 'Invalid JSON: $e';
    }
  }

  Future<void> addHistory(ConversionResult result) async {
    _history = [result, ..._history].take(_historyLimit).toList();
    notifyListeners();
    await _writeFile(
      _historyFileName,
      jsonEncode(_history.map((result) => result.toJson()).toList()),
    );
  }

  Future<void> resetAll() async {
    _settings = const AppSettings();
    _history = [];
    notifyListeners();
    await _deleteFile(_settingsFileName);
    await _deleteFile(_historyFileName);
  }

  Future<String?> _readFile(String fileName) async {
    try {
      final file = File(await _storagePath(fileName));
      if (!await file.exists()) return null;
      return file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeFile(String fileName, String content) async {
    final file = File(await _storagePath(fileName));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  Future<void> _deleteFile(String fileName) async {
    try {
      final file = File(await _storagePath(fileName));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<String> _storagePath(String fileName) async {
    final baseDir = Platform.environment['APPDATA'] ??
        Platform.environment['LOCALAPPDATA'] ??
        Directory.current.path;
    return p.join(baseDir, 'FormatConv', fileName);
  }
}

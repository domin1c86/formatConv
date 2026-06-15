import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/conversion_result.dart';

final settingsProvider = ChangeNotifierProvider<SettingsController>((ref) {
  return SettingsController()..load();
});

class SettingsController extends ChangeNotifier {
  static const _settingsKey = 'formatconv.settings.v1';
  static const _historyKey = 'formatconv.history.v1';
  static const _historyLimit = 100;

  AppSettings _settings = const AppSettings();
  List<ConversionResult> _history = [];
  bool _loaded = false;

  AppSettings get settings => _settings;
  List<ConversionResult> get history => List.unmodifiable(_history);
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsRaw = prefs.getString(_settingsKey);
    final historyRaw = prefs.getString(_historyKey);

    if (settingsRaw != null) {
      try {
        _settings = AppSettings.fromJson(jsonDecode(settingsRaw) as Map<String, dynamic>);
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
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
  }

  Future<void> toggleFormat(String type, String format, bool enabled) async {
    Set<String> next(Set<String> current) {
      final result = {...current};
      enabled ? result.add(format) : result.remove(format);
      return result;
    }

    if (type == 'video') {
      await update(_settings.copyWith(visibleVideoFormats: next(_settings.visibleVideoFormats)));
    } else if (type == 'image') {
      await update(_settings.copyWith(visibleImageFormats: next(_settings.visibleImageFormats)));
    } else {
      await update(_settings.copyWith(visibleAudioFormats: next(_settings.visibleAudioFormats)));
    }
  }

  Future<String?> saveThemeJson(String source) async {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        return 'Theme JSON must be an object.';
      }
      await update(_settings.copyWith(themeJson: const JsonEncoder.withIndent('  ').convert(decoded)));
      return null;
    } catch (e) {
      return 'Invalid JSON: $e';
    }
  }

  Future<void> addHistory(ConversionResult result) async {
    _history = [result, ..._history].take(_historyLimit).toList();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(_history.map((result) => result.toJson()).toList()),
    );
  }

  Future<void> resetAll() async {
    _settings = const AppSettings();
    _history = [];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    await prefs.remove(_historyKey);
  }
}

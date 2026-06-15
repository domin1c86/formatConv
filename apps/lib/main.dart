import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_strings.dart';
import 'models/app_settings.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/conversion_service.dart';

final versionProvider = Provider<String>((ref) {
  try {
    return ConversionService().getVersion();
  } catch (_) {
    return 'unavailable';
  }
});

void main() {
  runApp(const ProviderScope(child: FormatConvApp()));
}

class FormatConvApp extends ConsumerWidget {
  const FormatConvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(versionProvider);
    final settings = ref.watch(settingsProvider).settings;
    final strings = AppStrings(settings.language);
    return MaterialApp(
      title: strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(settings),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme(AppSettings settings) {
    final tokens = _themeTokens(settings);
    final actionBlue = _readColor(tokens, 'primary', const Color(0xFF0066CC));
    final ink = _readColor(tokens, 'ink', const Color(0xFF1D1D1F));
    final background = settings.theme == AppThemeChoice.dark
        ? const Color(0xFF111113)
        : _readColor(tokens, 'background', const Color(0xFFF5F5F7));
    final surface = settings.theme == AppThemeChoice.dark
        ? const Color(0xFF1E1E21)
        : _readColor(tokens, 'surface', Colors.white);
    final border = _readColor(tokens, 'border', const Color(0xFFE0E0E0));
    final surfaceMuted =
        _readColor(tokens, 'surfaceMuted', const Color(0xFFFAFAFC));
    final hover = _readColor(tokens, 'hover', const Color(0xFFF0F7FF));
    final muted = _readColor(tokens, 'muted', const Color(0xFF6E6E73));
    final radius = settings.cardRadius > 0
        ? settings.cardRadius
        : (tokens['cardRadius'] as num?)?.toDouble() ?? 14;
    final hoverBlue = actionBlue.withValues(alpha: 0.08);
    final pressedBlue = actionBlue.withValues(alpha: 0.14);
    final clickCursor = WidgetStateProperty.all(SystemMouseCursors.click);

    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: actionBlue,
        primary: actionBlue,
        surface: surface,
        brightness: settings.theme == AppThemeChoice.dark
            ? Brightness.dark
            : Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: settings.fontFamily.isEmpty ? 'MiSans' : settings.fontFamily,
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
        fontFamily:
            settings.fontFamily.isEmpty ? 'MiSans' : settings.fontFamily,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: actionBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          shape: const StadiumBorder(),
          elevation: 0,
        ).copyWith(
          mouseCursor: clickCursor,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return Colors.white24;
            if (states.contains(WidgetState.hovered)) return Colors.white12;
            return null;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: actionBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          shape: const StadiumBorder(),
        ).copyWith(
          mouseCursor: clickCursor,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return Colors.white24;
            if (states.contains(WidgetState.hovered)) return Colors.white12;
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: actionBlue,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          side: BorderSide(color: actionBlue),
          shape: const StadiumBorder(),
        ).copyWith(
          mouseCursor: clickCursor,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return pressedBlue;
            if (states.contains(WidgetState.hovered)) return hoverBlue;
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: actionBlue,
          shape: const StadiumBorder(),
        ).copyWith(
          mouseCursor: clickCursor,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return pressedBlue;
            if (states.contains(WidgetState.hovered)) return hoverBlue;
            return null;
          }),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ink,
          hoverColor: hoverBlue,
          highlightColor: pressedBlue,
        ).copyWith(
          mouseCursor: clickCursor,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return actionBlue;
          return Colors.white;
        }),
        side: BorderSide(color: border),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: actionBlue,
        thumbColor: actionBlue,
        overlayColor: const Color(0x220066CC),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border),
        ),
      ),
      extensions: [
        AppThemeTokens(
          background: background,
          surface: surface,
          surfaceMuted: surfaceMuted,
          hover: hover,
          ink: ink,
          muted: muted,
          primary: actionBlue,
          border: border,
          cardRadius: radius,
        ),
      ],
    );
  }

  Map<String, dynamic> _themeTokens(AppSettings settings) {
    try {
      final decoded = jsonDecode(settings.effectiveThemeJson);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return defaultThemeTokens;
  }

  Color _readColor(Map<String, dynamic> tokens, String key, Color fallback) {
    final value = tokens[key];
    if (value is! String || !value.startsWith('#')) return fallback;
    final hex = value.substring(1);
    if (hex.length != 6 && hex.length != 8) return fallback;
    final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}

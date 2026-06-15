import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_strings.dart';
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
    final strings = ref.watch(appStringsProvider);
    return MaterialApp(
      title: strings.appTitle,
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    const actionBlue = Color(0xFF0066CC);
    const ink = Color(0xFF1D1D1F);

    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: actionBlue,
        primary: actionBlue,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
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
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: actionBlue,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          side: const BorderSide(color: actionBlue),
          shape: const StadiumBorder(),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return actionBlue;
          return Colors.white;
        }),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: actionBlue,
        thumbColor: actionBlue,
        overlayColor: Color(0x220066CC),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
    );
  }
}

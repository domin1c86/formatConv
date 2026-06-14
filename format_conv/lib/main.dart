import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'services/conversion_service.dart';

final versionProvider = Provider<String>((ref) {
  return ConversionService().getVersion();
});

void main() {
  runApp(const ProviderScope(child: FormatConvApp()));
}

class FormatConvApp extends ConsumerWidget {
  const FormatConvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(versionProvider);
    return MaterialApp(
      title: 'Format Converter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066CC)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

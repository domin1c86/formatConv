import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ffi_bridge.dart';

final versionProvider = Provider<String>((ref) {
  return FormatConvBridge().getVersion();
});

void main() {
  runApp(const ProviderScope(child: FormatConvApp()));
}

class FormatConvApp extends ConsumerWidget {
  const FormatConvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(versionProvider);
    return MaterialApp(
      title: 'Format Converter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066CC)),
        useMaterial3: true,
      ),
      home: HomePage(version: version),
    );
  }
}

class HomePage extends StatelessWidget {
  final String version;
  const HomePage({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Format Converter'),
      ),
      body: Center(
        child: Text('Format Converter v$version - Coming Soon'),
      ),
    );
  }
}

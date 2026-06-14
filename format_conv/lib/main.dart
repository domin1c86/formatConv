import 'package:flutter/material.dart';

void main() {
  runApp(const FormatConvApp());
}

class FormatConvApp extends StatelessWidget {
  const FormatConvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Format Converter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066CC)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Format Converter'),
      ),
      body: const Center(
        child: Text('Format Converter - Coming Soon'),
      ),
    );
  }
}

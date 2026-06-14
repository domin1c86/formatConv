import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:format_conv/providers/conversion_provider.dart';

void main() {
  group('ConversionProvider', () {
    test('initial state is correct', () {
      final provider = ConversionProvider();
      expect(provider.isConverting, false);
      expect(provider.progress, 0.0);
      expect(provider.selectedFiles, isEmpty);
    });

    test('supportedFormats contains expected formats', () {
      expect(ConversionProvider.supportedFormats, contains('MP4'));
      expect(ConversionProvider.supportedFormats, contains('PNG'));
      expect(ConversionProvider.supportedFormats, contains('MP3'));
      expect(ConversionProvider.supportedFormats, contains('JPEG'));
      expect(ConversionProvider.supportedFormats, contains('FLAC'));
    });

    test('conversionProvider is a valid Riverpod provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = container.read(conversionProvider);
      expect(provider, isNotNull);
      expect(provider.isConverting, false);
    });
  });
}

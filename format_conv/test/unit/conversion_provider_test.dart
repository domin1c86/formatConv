import 'package:flutter_test/flutter_test.dart';
import 'package:format_conv/providers/conversion_provider.dart';

void main() {
  group('ConversionProvider', () {
    test('initial state is correct', () {
      final provider = ConversionProvider();
      expect(provider.isConverting, false);
      expect(provider.progress, 0.0);
      expect(provider.selectedFiles, isEmpty);
    });
  });
}

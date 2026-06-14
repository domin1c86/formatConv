import 'package:flutter_test/flutter_test.dart';
import 'package:format_conv/services/conversion_service.dart';

void main() {
  group('ConversionService', () {
    test('getSupportedFormats returns valid JSON', () async {
      final service = ConversionService();
      final formats = await service.getSupportedFormats();
      expect(formats, isNotNull);
      expect(formats.videoFormats, isNotEmpty);
    });
  });
}

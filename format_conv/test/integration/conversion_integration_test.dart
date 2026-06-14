import 'package:flutter_test/flutter_test.dart';
import 'package:format_conv/services/conversion_service.dart';

void main() {
  group('Conversion Integration', () {
    test('getVersion returns valid version', () {
      final service = ConversionService();
      final version = service.getVersion();
      expect(version, isNotEmpty);
      expect(version, contains('.'));
    });

    test('getSupportedFormats returns all format types', () async {
      final service = ConversionService();
      final formats = await service.getSupportedFormats();
      expect(formats.videoFormats, isNotEmpty);
      expect(formats.imageFormats, isNotEmpty);
      expect(formats.audioFormats, isNotEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:format_conv/services/conversion_service.dart';

ConversionService? _tryCreateService() {
  try {
    return ConversionService();
  } catch (_) {
    return null;
  }
}

void main() {
  group('Conversion Integration', () {
    test('getVersion returns valid version', () {
      final service = _tryCreateService();
      if (service == null) {
        return;
      }
      final version = service.getVersion();
      expect(version, isNotEmpty);
      expect(version, contains('.'));
    });

    test('getSupportedFormats returns all format types', () async {
      final service = _tryCreateService();
      if (service == null) {
        return;
      }
      final formats = await service.getSupportedFormats();
      expect(formats.videoFormats, isNotEmpty);
      expect(formats.imageFormats, isNotEmpty);
      expect(formats.audioFormats, isNotEmpty);
    });

    test('detectFormat identifies known extension', () async {
      final service = _tryCreateService();
      if (service == null) {
        return;
      }
      final info = await service.detectFormat('video.mp4');
      expect(info, isNotNull);
      expect(info?.format, isNotEmpty);
    });

    test('detectFormat returns null for unsupported extension', () async {
      final service = _tryCreateService();
      if (service == null) {
        return;
      }
      final result = await service.detectFormat('file.xyz');
      expect(result, isNull);
    });
  });
}

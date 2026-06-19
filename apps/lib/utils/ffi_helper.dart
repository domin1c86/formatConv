import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef GetVersionNative = Pointer<Utf8> Function();
typedef GetVersionDart = Pointer<Utf8> Function();

typedef GetSupportedFormatsNative = Pointer<Utf8> Function();
typedef GetSupportedFormatsDart = Pointer<Utf8> Function();

typedef DetectFormatNative = Pointer<Utf8> Function(Pointer<Utf8> filePath);
typedef DetectFormatDart = Pointer<Utf8> Function(Pointer<Utf8> filePath);

typedef ConvertFileNative = Int64 Function(
  Pointer<Utf8> inputPath,
  Pointer<Utf8> outputPath,
  Pointer<Utf8> optionsJSON,
  Pointer<Void> callback,
);
typedef ConvertFileDart = int Function(
  Pointer<Utf8> inputPath,
  Pointer<Utf8> outputPath,
  Pointer<Utf8> optionsJSON,
  Pointer<Void> callback,
);

typedef RunMediaOperationNative = Int64 Function(
  Pointer<Utf8> optionsJSON,
  Pointer<Void> callback,
);
typedef RunMediaOperationDart = int Function(
  Pointer<Utf8> optionsJSON,
  Pointer<Void> callback,
);

typedef GetConversionStatusNative = Pointer<Utf8> Function(Int64 conversionID);
typedef GetConversionStatusDart = Pointer<Utf8> Function(int conversionID);

typedef CancelConversionNative = Int32 Function(Int64 conversionID);
typedef CancelConversionDart = int Function(int conversionID);

typedef FreeStringNative = Void Function(Pointer<Utf8> str);
typedef FreeStringDart = void Function(Pointer<Utf8> str);

class FFIHelper {
  static DynamicLibrary? _lib;

  static DynamicLibrary get lib {
    if (_lib != null) return _lib!;

    if (Platform.isWindows) {
      _lib = DynamicLibrary.open('format_conv.dll');
    } else {
      throw UnsupportedError('Only Windows is supported');
    }

    return _lib!;
  }

  static final GetVersionDart getVersion =
      lib.lookupFunction<GetVersionNative, GetVersionDart>('getVersion');

  static final GetSupportedFormatsDart getSupportedFormats =
      lib.lookupFunction<GetSupportedFormatsNative, GetSupportedFormatsDart>(
          'getSupportedFormats');

  static final DetectFormatDart detectFormat =
      lib.lookupFunction<DetectFormatNative, DetectFormatDart>('detectFormat');

  static final ConvertFileDart convertFile =
      lib.lookupFunction<ConvertFileNative, ConvertFileDart>('convertFile');

  static final RunMediaOperationDart runMediaOperation =
      lib.lookupFunction<RunMediaOperationNative, RunMediaOperationDart>(
          'runMediaOperation');

  static final GetConversionStatusDart getConversionStatus =
      lib.lookupFunction<GetConversionStatusNative, GetConversionStatusDart>(
          'getConversionStatus');

  static final CancelConversionDart cancelConversion =
      lib.lookupFunction<CancelConversionNative, CancelConversionDart>(
          'cancelConversion');

  static final FreeStringDart freeString =
      lib.lookupFunction<FreeStringNative, FreeStringDart>('freeString');
}

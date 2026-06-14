import 'dart:ffi';
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';

// Typedefs for the C functions
typedef GetVersionC = Pointer<Utf8> Function();
typedef GetVersionDart = Pointer<Utf8> Function();

class FormatConvBridge {
  static FormatConvBridge? _instance;
  late final DynamicLibrary _lib;
  late final GetVersionDart _getVersion;

  FormatConvBridge._() {
    _lib = _loadLibrary();
    _getVersion = _lib
        .lookupFunction<GetVersionC, GetVersionDart>('getVersion');
  }

  factory FormatConvBridge() {
    _instance ??= FormatConvBridge._();
    return _instance!;
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) {
      return DynamicLibrary.open('format_conv.dll');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libformat_conv.so');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libformat_conv.dylib');
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  String getVersion() {
    final ptr = _getVersion();
    return ptr.toDartString();
  }
}

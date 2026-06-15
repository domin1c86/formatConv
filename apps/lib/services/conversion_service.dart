import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../models/conversion_options.dart';
import '../models/format_info.dart';
import '../models/conversion_status.dart';
import '../utils/ffi_helper.dart';

typedef _ProgressCallbackNative = Void Function(
  Int64 id,
  Double progress,
  Int64 processed,
  Int64 total,
  Int32 status,
  Pointer<Utf8> error,
);

class ConversionService {
  static final Map<int, NativeCallable<_ProgressCallbackNative>>
      _activeCallbacks = {};
  String getVersion() {
    final ptr = FFIHelper.getVersion();
    final version = ptr.toDartString();
    FFIHelper.freeString(ptr);
    return version;
  }

  Future<FormatList> getSupportedFormats() async {
    final ptr = FFIHelper.getSupportedFormats();
    final jsonStr = ptr.toDartString();
    FFIHelper.freeString(ptr);

    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return FormatList.fromJson(json);
  }

  Future<FormatInfo?> detectFormat(String filePath) async {
    final pathPtr = filePath.toNativeUtf8();
    final ptr = FFIHelper.detectFormat(pathPtr);
    final jsonStr = ptr.toDartString();
    FFIHelper.freeString(ptr);
    calloc.free(pathPtr);

    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (json.isEmpty) return null;
    return FormatInfo.fromJson(json);
  }

  Future<int> convertFile(
    String inputPath,
    String outputPath,
    ConversionOptions options,
    Function(int id, double progress, int processed, int total, int status,
            String? error)?
        onProgress,
  ) async {
    final inputPtr = inputPath.toNativeUtf8();
    final outputPtr = outputPath.toNativeUtf8();
    final optionsPtr = jsonEncode(options.toJson()).toNativeUtf8();

    Pointer<Void> callbackPtr = nullptr;
    NativeCallable<_ProgressCallbackNative>? nativeCallable;

    if (onProgress != null) {
      nativeCallable = NativeCallable<_ProgressCallbackNative>.listener(
        (int id, double progress, int processed, int total, int status,
            Pointer<Utf8> error) {
          String? errorStr;
          if (error != nullptr) {
            try {
              errorStr = error.toDartString();
            } catch (_) {
              errorStr = 'Unknown error';
            }
          }
          onProgress(id, progress, processed, total, status, errorStr);
        },
      );
      callbackPtr = nativeCallable.nativeFunction.cast<Void>();
    }

    final result =
        FFIHelper.convertFile(inputPtr, outputPtr, optionsPtr, callbackPtr);

    calloc.free(inputPtr);
    calloc.free(outputPtr);
    calloc.free(optionsPtr);

    if (nativeCallable != null && result > 0) {
      _activeCallbacks[result] = nativeCallable;
    } else {
      nativeCallable?.close();
    }

    return result;
  }

  static void disposeProgressCallback(int conversionId) {
    _activeCallbacks.remove(conversionId)?.close();
  }

  Future<ConversionStatus?> getConversionStatus(int conversionId) async {
    final ptr = FFIHelper.getConversionStatus(conversionId);
    final jsonStr = ptr.toDartString();
    FFIHelper.freeString(ptr);

    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (json.isEmpty) return null;
    return ConversionStatus.fromJson(json);
  }

  Future<bool> cancelConversion(int conversionId) async {
    final result = FFIHelper.cancelConversion(conversionId);
    return result == 1;
  }
}

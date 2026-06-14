import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../models/conversion_options.dart';
import '../models/format_info.dart';
import '../models/conversion_status.dart';
import '../utils/ffi_helper.dart';

class ConversionService {
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
    Function(int id, double progress, int processed, int total, int status, String? error)? onProgress,
  ) async {
    final inputPtr = inputPath.toNativeUtf8();
    final outputPtr = outputPath.toNativeUtf8();
    final optionsPtr = jsonEncode(options.toJson()).toNativeUtf8();
    
    // For now, pass null callback - will be implemented later with NativeCallable
    final result = FFIHelper.convertFile(inputPtr, outputPtr, optionsPtr, nullptr);
    
    calloc.free(inputPtr);
    calloc.free(outputPtr);
    calloc.free(optionsPtr);
    
    return result;
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

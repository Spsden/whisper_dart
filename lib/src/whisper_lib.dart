import 'dart:ffi';
import 'dart:io';
import 'generated_whisper.dart';

WhisperBindings? _bindings;

WhisperBindings get bindings {
  if (_bindings != null) return _bindings!;
  
  DynamicLibrary dylib;
  if (Platform.isAndroid) {
    dylib = DynamicLibrary.open('libwhisper.so');
  } else if (Platform.isIOS) {
    dylib = DynamicLibrary.process();
  } else if (Platform.isMacOS) {
    dylib = DynamicLibrary.process(); 
  } else if (Platform.isWindows) {
    dylib = DynamicLibrary.open('whisper.dll');
  } else if (Platform.isLinux) {
    dylib = DynamicLibrary.open('libwhisper.so');
  } else {
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }
  
  _bindings = WhisperBindings(dylib);
  return _bindings!;
}

import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'src/whisper_lib.dart';
import 'src/generated_whisper.dart';

export 'src/generated_whisper.dart' show whisper_sampling_strategy;

class Whisper {
  Pointer<whisper_context>? _ctx;

  bool get isInitialized => _ctx != null && _ctx != nullptr;

  Whisper({required String modelPath}) {
    final pathPtr = modelPath.toNativeUtf8();


    _ctx = bindings.whisper_init_from_file(pathPtr.cast());
    calloc.free(pathPtr);
    
    if (_ctx == nullptr) {
      throw Exception("Failed to initialize whisper model from $modelPath");
    }
  }
  
  static String? get version {
     try {
       return bindings.whisper_version().cast<Utf8>().toDartString();
     } catch (e) {
       return null;
     }
  }

  /// Transcribes the audio samples.
  /// [samples] must be 16kHz mono PCM normalzed to [-1, 1].
  /// This method blocks the calling thread (usually UI thread if not in internal isolate).
  /// Consider running this in a separate Isolate for long audio.
  String transcribe(List<double> samples) {
    if (!isInitialized) throw Exception("Model not initialized");
    if (samples.isEmpty) return "";

    var params = bindings.whisper_full_default_params(
        whisper_sampling_strategy.WHISPER_SAMPLING_GREEDY
    );
    params.print_progress = false;
    params.print_realtime = false;
    params.print_timestamps = false;
    
    // Allocate audio buffer in native memory
    final audioPtr = calloc<Float>(samples.length);
    final audioList = audioPtr.asTypedList(samples.length);
    audioList.setAll(0, samples);
    
    int result = bindings.whisper_full(_ctx!, params, audioPtr, samples.length);
    
    calloc.free(audioPtr);
    
    if (result != 0) {
      throw Exception("Whisper failed to process audio: code $result");
    }
    
    int nSegments = bindings.whisper_full_n_segments(_ctx!);
    StringBuffer sb = StringBuffer();
    
    for (int i = 0; i < nSegments; i++) {
        Pointer<Char> text = bindings.whisper_full_get_segment_text(_ctx!, i);
        sb.write(text.cast<Utf8>().toDartString());
    }
    
    return sb.toString();
  }

  void dispose() {
    if (isInitialized) {
      bindings.whisper_free(_ctx!);
      _ctx = null;
    }
    // Also free params if we stored them, but here we used stack struct which dart cleans?
    // Actually params is struct by value in C, but ffi passes it how?
    // In generated bindings:
    // whisper_full(..., whisper_full_params params, ...)
    // Structs by value are supported in Dart FFI.
    // But `whisper_full_default_params` returns `whisper_full_params` struct.
    // So `params` is a DART object representing the struct.
  }
}

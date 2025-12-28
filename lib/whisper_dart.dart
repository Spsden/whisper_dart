import 'dart:ffi';
import 'dart:typed_data'; // ✅ Correct import for Float32List
import 'package:ffi/ffi.dart';
import 'src/whisper_lib.dart';
import 'src/generated_whisper.dart';
import 'src/wav_util.dart';

export 'src/whisper_dart_isolate.dart';
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
  /// [samples] must be 16kHz mono PCM normalized to [-1, 1].
  /// [nThreads] number of threads to use. Defaults to 4.
  ///
  ///  OPTIMIZATION NOTE:
  /// Using Float32List here allows for faster memory copying to C++
  /// than a standard List<double>.
  String transcribe({required Float32List samples, int nThreads = 4}) {
    if (!isInitialized) throw Exception("Model not initialized");
    if (samples.isEmpty) return "";

    // 1. Configure Parameters
    var params = bindings.whisper_full_default_params(
        whisper_sampling_strategy.WHISPER_SAMPLING_GREEDY
    );

    // --- Performance Optimizations ---

    // Don't calculate token timestamps (Saves CPU)
    params.no_timestamps = true;

    // Skip processing silence/non-speech (Big speedup on empty audio)
    // Note: If your generated bindings call this 'suppress_nst', use that instead.
    params.suppress_nst = true;

    // Disable all printing to stdout (Reduces I/O overhead)
    params.print_progress = false;
    params.print_realtime = false;
    params.print_timestamps = false;
    params.print_special = false;

    params.n_threads = nThreads;

    // 2. Efficient Memory Allocation
    // Allocate native float array
    final audioPtr = calloc<Float>(samples.length);

    // Create a Dart view of the native memory
    final audioList = audioPtr.asTypedList(samples.length);

    // BLOCK COPY: Since 'samples' is Float32List, this is extremely fast
    audioList.setAll(0, samples);

    // 3. Run Inference
    int result = bindings.whisper_full(_ctx!, params, audioPtr, samples.length);

    // 4. Cleanup Native Memory immediately
    calloc.free(audioPtr);

    if (result != 0) {
      throw Exception("Whisper failed to process audio: code $result");
    }

    // 5. Extract Text
    int nSegments = bindings.whisper_full_n_segments(_ctx!);
    StringBuffer sb = StringBuffer();

    for (int i = 0; i < nSegments; i++) {
      Pointer<Char> text = bindings.whisper_full_get_segment_text(_ctx!, i);
      sb.write(text.cast<Utf8>().toDartString());
    }

    return sb.toString();
  }

  /// Transcribes a WAV file (16kHz mono).
  Future<String> transcribeWavFile({required String path, int nThreads = 4}) async {
    final samples = await WavUtil.decodeWavFile(path);
    return transcribe(samples: samples, nThreads: nThreads);
  }

  void dispose() {
    if (isInitialized) {
      bindings.whisper_free(_ctx!);
      _ctx = null;
    }
  }
}
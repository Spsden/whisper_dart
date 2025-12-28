import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import '../whisper_dart.dart';

class WhisperIsolate {
  final Isolate _isolate;
  final SendPort _sendPort;
  final ReceivePort _receivePort;

  WhisperIsolate._(this._isolate, this._sendPort, this._receivePort);

  /// Spawns an isolate and initializes the Whisper model.
  static Future<WhisperIsolate> create({required String modelPath}) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _InitMessage(receivePort.sendPort, modelPath),
    );

    final sendPort = await receivePort.first as SendPort;
    return WhisperIsolate._(isolate, sendPort, receivePort);
  }

  /// Transcribes audio samples in the background isolate.
  /// [samples] - 16kHz mono PCM data. MUST be Float32List for performance.
  /// [nThreads] - number of threads to use. Defaults to 4.
  Future<String> transcribe({required Float32List samples, int nThreads = 4}) async {
    final responsePort = ReceivePort();

    // OPTIMIZATION: Wrap data in TransferableTypedData.
    // This allows passing the large audio buffer to the isolate
    // without copying the memory, significantly reducing UI jank.
    final transferable = TransferableTypedData.fromList([samples]);

    _sendPort.send(_TranscribeMessage(responsePort.sendPort, transferable, nThreads));
    final result = await responsePort.first;

    if (result is String) {
      return result;
    } else if (result is Object) {
      throw Exception(result.toString());
    } else {
      throw Exception("Unknown error from isolate");
    }
  }

  /// Disposes the isolate.
  void dispose() {
    _isolate.kill();
    _receivePort.close();
  }
}

// Messages

class _InitMessage {
  final SendPort sendPort;
  final String modelPath;
  _InitMessage(this.sendPort, this.modelPath);
}

class _TranscribeMessage {
  final SendPort sendPort;
  // Use TransferableTypedData instead of List/Float32List for transport
  final TransferableTypedData audioData;
  final int nThreads;
  _TranscribeMessage(this.sendPort, this.audioData, this.nThreads);
}

// Entry Point

void _isolateEntryPoint(_InitMessage initMessage) {
  final receivePort = ReceivePort();
  // Send our sendPort back to the main isolate
  initMessage.sendPort.send(receivePort.sendPort);

  Whisper? whisper;

  try {
    whisper = Whisper(modelPath: initMessage.modelPath);
  } catch (e) {
    print("WhisperIsolate init failed: $e");
    // Ideally send an error back, but for now we just log/return
    return;
  }

  receivePort.listen((message) {
    if (message is _TranscribeMessage) {
      try {
        // UNPACK: Materialize the transferable data back into a usable Float32List
        final Float32List samples = message.audioData.materialize().asFloat32List();

        // Pass to the optimized Whisper class
        final result = whisper!.transcribe(
            samples: samples,
            nThreads: message.nThreads
        );
        message.sendPort.send(result);
      } catch (e) {
        message.sendPort.send(e.toString());
      }
    }
  });
}
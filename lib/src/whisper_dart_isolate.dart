import 'dart:async';
import 'dart:isolate';

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
  /// [nThreads] - number of threads to use for transcription. Defaults to 4.
  Future<String> transcribe({required List<double> samples, int nThreads = 4}) async {
    final responsePort = ReceivePort();
    _sendPort.send(_TranscribeMessage(responsePort.sendPort, samples, nThreads));
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
  final List<double> samples;
  final int nThreads;
  _TranscribeMessage(this.sendPort, this.samples, this.nThreads);
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
     return;
  }

  receivePort.listen((message) {
    if (message is _TranscribeMessage) {
      try {
        final result = whisper!.transcribe(
            samples: message.samples, 
            nThreads: message.nThreads
        );
        message.sendPort.send(result);
      } catch (e) {
        message.sendPort.send(e.toString());
      }
    }
  });
}

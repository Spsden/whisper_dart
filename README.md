# whisper_dart

Dart FFI bindings for [whisper.cpp](https://github.com/ggml-org/whisper.cpp).
Supported platforms:
- [x] Android (Tested and ready)
- [ ] iOS (Not ready)
- [ ] macOS
- [ ] Windows
- [ ] Linux


## Features
- Hardware accelerated batch transcription (via NEON/Simd).
- Supports all GGML (Whisper) models.
- Strictly typed FFI generation.

## Usage

### 1. Project Setup
Add `whisper_dart` to your `pubspec.yaml`.

### 2. Prepare Model
Download a quantified model (e.g. `ggml-tiny.bin`) and place it on the device file system (e.g. from assets).

```dart
// Helper to copy asset to local file
Future<String> copyModel(String assetPath) async {
  final byteData = await rootBundle.load(assetPath);
  final file = File('${(await getApplicationDocumentsDirectory()).path}/model.bin');
  await file.writeAsBytes(byteData.buffer.asUint8List());
  return file.path;
}
```

### 3. Transcribe

The recommended way is to use `WhisperIsolate` to keep the UI thread responsive.

```dart
import 'package:whisper_dart/whisper_dart.dart';

// 1. Initialize Isolate (ideally once for the app)
final whisperIsolate = await WhisperIsolate.create(modelPath: modelPath);

// 2. Transcribe a WAV file directly (16kHz mono)
// Decoding and transcription happen in the background isolate.
final String text = await whisperIsolate.transcribe(
  audioFile: 'path/to/audio.wav',
  nThreads: 4,
);

print("Transcription: $text");

// 3. Dispose when done
whisperIsolate.dispose();
```

For advanced use cases, you can also pass `Float32List` samples directly using `whisperIsolate.transcribe(samples: mySamples)`.

## Build Configuration

### Android
Automatic via CMake.

### iOS
Automatic via CocoaPods. Requires iOS 12.0+.

## Performance
For medium-end Android devices, use **quantized models** (e.g. `q8_0` or `tiny`) and avoid real-time streaming for now.

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

```dart
import 'package:whisper_dart/whisper_dart.dart';

// Initialize
final whisper = Whisper(modelPath: modelPath);

print(Whisper.version);

// Transcribe (16kHz mono PCM)
final res = whisper.transcribe(audioSamples);
print(res);

// Dispose
whisper.dispose();
```

## Build Configuration

### Android
Automatic via CMake.

### iOS
Automatic via CocoaPods. Requires iOS 12.0+.

## Performance
For medium-end Android devices, use **quantized models** (e.g. `q8_0` or `tiny`) and avoid real-time streaming for now.

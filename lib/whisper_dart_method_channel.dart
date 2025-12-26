import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'whisper_dart_platform_interface.dart';

/// An implementation of [WhisperDartPlatform] that uses method channels.
class MethodChannelWhisperDart extends WhisperDartPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('whisper_dart');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

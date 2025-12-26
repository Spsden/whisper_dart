import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'whisper_dart_method_channel.dart';

abstract class WhisperDartPlatform extends PlatformInterface {
  /// Constructs a WhisperDartPlatform.
  WhisperDartPlatform() : super(token: _token);

  static final Object _token = Object();

  static WhisperDartPlatform _instance = MethodChannelWhisperDart();

  /// The default instance of [WhisperDartPlatform] to use.
  ///
  /// Defaults to [MethodChannelWhisperDart].
  static WhisperDartPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WhisperDartPlatform] when
  /// they register themselves.
  static set instance(WhisperDartPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

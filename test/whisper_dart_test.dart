import 'package:flutter_test/flutter_test.dart';
import 'package:whisper_dart/whisper_dart.dart';
import 'package:whisper_dart/whisper_dart_platform_interface.dart';
import 'package:whisper_dart/whisper_dart_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWhisperDartPlatform
    with MockPlatformInterfaceMixin
    implements WhisperDartPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final WhisperDartPlatform initialPlatform = WhisperDartPlatform.instance;

  test('$MethodChannelWhisperDart is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWhisperDart>());
  });

  test('getPlatformVersion', () async {
    WhisperDart whisperDartPlugin = WhisperDart();
    MockWhisperDartPlatform fakePlatform = MockWhisperDartPlatform();
    WhisperDartPlatform.instance = fakePlatform;

    expect(await whisperDartPlugin.getPlatformVersion(), '42');
  });
}

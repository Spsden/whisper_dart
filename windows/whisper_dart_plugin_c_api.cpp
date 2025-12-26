#include "include/whisper_dart/whisper_dart_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "whisper_dart_plugin.h"

void WhisperDartPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  whisper_dart::WhisperDartPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

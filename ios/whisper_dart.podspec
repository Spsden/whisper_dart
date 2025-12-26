#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint whisper_dart.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'whisper_dart'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*', '../native/whisper.cpp/src/whisper.cpp', '../native/whisper.cpp/include/whisper.h', '../native/whisper.cpp/ggml/src/ggml.c', '../native/whisper.cpp/ggml/src/ggml.cpp', '../native/whisper.cpp/ggml/src/ggml-alloc.c', '../native/whisper.cpp/ggml/src/ggml-backend.cpp', '../native/whisper.cpp/ggml/src/ggml-opt.cpp', '../native/whisper.cpp/ggml/src/ggml-threading.cpp', '../native/whisper.cpp/ggml/src/ggml-quants.c', '../native/whisper.cpp/ggml/src/gguf.cpp'
  
  s.compiler_flags = '-O3 -D_GNU_SOURCE'

  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/../native/whisper.cpp/include" "$(PODS_TARGET_SRCROOT)/../native/whisper.cpp/ggml/include" "$(PODS_TARGET_SRCROOT)/../native/whisper.cpp/ggml/src"',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'GCC_PREPROCESSOR_DEFINITIONS' => 'GGML_USE_CPU=1'
  }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'whisper_dart_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end

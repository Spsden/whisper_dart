cmake_minimum_required(VERSION 3.10)

project(whisper_dart_plugin)

set(WHISPER_ROOT "../native/whisper.cpp")
set(GGML_ROOT "${WHISPER_ROOT}/ggml")

# Add Whisper and GGML sources
add_library(whisper SHARED
    # GGML
    "${GGML_ROOT}/src/ggml.c"
    "${GGML_ROOT}/src/ggml.cpp"
    "${GGML_ROOT}/src/ggml-alloc.c"
    "${GGML_ROOT}/src/ggml-backend.cpp"
    "${GGML_ROOT}/src/ggml-opt.cpp"
    "${GGML_ROOT}/src/ggml-threading.cpp"
    "${GGML_ROOT}/src/ggml-quants.c"
    "${GGML_ROOT}/src/gguf.cpp"

    # Whisper
    "${WHISPER_ROOT}/src/whisper.cpp"
)

# Include directories
target_include_directories(whisper PUBLIC
    "${WHISPER_ROOT}/include"
    "${GGML_ROOT}/include"
    "${GGML_ROOT}/src"
)

# Compiler definitions
target_compile_definitions(whisper PRIVATE
    _GNU_SOURCE
    GGML_USE_CPU
)

# Compilation features
target_compile_features(whisper PUBLIC cxx_std_17)

# Libraries
find_library(log-lib log)
target_link_libraries(whisper
    ${log-lib}
    dl
)

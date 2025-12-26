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
    "${GGML_ROOT}/src/ggml-backend-reg.cpp"
    
    # GGML CPU Backend
    "${GGML_ROOT}/src/ggml-cpu/ggml-cpu.c"
    "${GGML_ROOT}/src/ggml-cpu/ggml-cpu.cpp"
    "${GGML_ROOT}/src/ggml-cpu/repack.cpp"
    "${GGML_ROOT}/src/ggml-cpu/hbm.cpp"
    "${GGML_ROOT}/src/ggml-cpu/quants.c"
    "${GGML_ROOT}/src/ggml-cpu/traits.cpp"
    "${GGML_ROOT}/src/ggml-cpu/amx/amx.cpp"
    "${GGML_ROOT}/src/ggml-cpu/amx/mmq.cpp"
    "${GGML_ROOT}/src/ggml-cpu/binary-ops.cpp"
    "${GGML_ROOT}/src/ggml-cpu/unary-ops.cpp"
    "${GGML_ROOT}/src/ggml-cpu/vec.cpp"
    "${GGML_ROOT}/src/ggml-cpu/ops.cpp"

    # Whisper
    "${WHISPER_ROOT}/src/whisper.cpp"
)

if(${ANDROID_ABI} MATCHES "^arm")
    target_sources(whisper PRIVATE
        "${GGML_ROOT}/src/ggml-cpu/arch/arm/quants.c"
        "${GGML_ROOT}/src/ggml-cpu/arch/arm/repack.cpp"
    )
endif()

if(${ANDROID_ABI} MATCHES "^x86")
    target_sources(whisper PRIVATE
        "${GGML_ROOT}/src/ggml-cpu/arch/x86/quants.c"
        "${GGML_ROOT}/src/ggml-cpu/arch/x86/repack.cpp"
    )
endif()

# Include directories
target_include_directories(whisper PUBLIC
    "${WHISPER_ROOT}/include"
    "${GGML_ROOT}/include"
    "${GGML_ROOT}/src"
    "${GGML_ROOT}/src/ggml-cpu"
)

# Compiler definitions
target_compile_definitions(whisper PRIVATE
    _GNU_SOURCE
    GGML_USE_CPU
    "GGML_VERSION=\"unversioned\""
    "GGML_COMMIT=\"unknown\""
    "WHISPER_VERSION=\"1.0.0\""
)

# Compilation features
target_compile_features(whisper PUBLIC cxx_std_17)

# Libraries
find_library(log-lib log)
target_link_libraries(whisper
    ${log-lib}
    dl
)

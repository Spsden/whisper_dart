#!/bin/bash
set -e

# Directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$DIR/.."
NATIVE_DIR="$REPO_ROOT/native/whisper.cpp"
BUILD_DIR="$REPO_ROOT/build_macos_libs"
OUTPUT_DIR="$REPO_ROOT/macos"

echo "Building libwhisper.dylib for macOS..."

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure CMake
# - BUILD_SHARED_LIBS=ON: Build dylib
# - WHISPER_BUILD_TESTS=OFF: Skip tests
# - WHISPER_BUILD_EXAMPLES=OFF: Skip examples
# - GGML_USE_ACCELERATE=ON: Enable Accelerate framework
cmake "$NATIVE_DIR" \
    -DBUILD_SHARED_LIBS=ON \
    -DWHISPER_BUILD_TESTS=OFF \
    -DWHISPER_BUILD_EXAMPLES=OFF \
    -DGGML_USE_ACCELERATE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15

# Build
make -j$(sysctl -n hw.ncpu)

# Copy dylib to macos folder
echo "Copying dylibs to $OUTPUT_DIR"
find . -name "*.dylib" -exec cp {} "$OUTPUT_DIR" \;

echo "Build complete. Output files:"
ls -lh "$OUTPUT_DIR/"*.dylib

echo "Checking libwhisper.dylib dependencies:"
otool -L "$OUTPUT_DIR/libwhisper.dylib"

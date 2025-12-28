import 'dart:io';
import 'dart:typed_data';

class WavUtil {
  /// Decodes a 16kHz mono WAV file into a Float32List of normalized samples.
  static Future<Float32List> decodeWavFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception("File not found: $path");
    }

    final bytes = await file.readAsBytes();
    final data = ByteData.sublistView(bytes);

    // Basic WAV Header check (simplified)
    if (bytes.length < 44) {
      throw Exception("Invalid WAV file: too small");
    }

    // Check RIFF header
    if (data.getUint32(0, Endian.big) != 0x52494646) { // "RIFF"
      throw Exception("Not a RIFF file");
    }

    // Check WAVE header
    if (data.getUint32(8, Endian.big) != 0x57415645) { // "WAVE"
      throw Exception("Not a WAVE file");
    }

    // Find "fmt " chunk
    int offset = 12;
    int? fmtOffset;
    while (offset < bytes.length - 8) {
      final chunkId = data.getUint32(offset, Endian.big);
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      if (chunkId == 0x666D7420) { // "fmt "
        fmtOffset = offset + 8;
        break;
      }
      offset += 8 + chunkSize;
    }

    if (fmtOffset == null) {
      throw Exception("fmt chunk not found");
    }

    final audioFormat = data.getUint16(fmtOffset, Endian.little);
    final numChannels = data.getUint16(fmtOffset + 2, Endian.little);
    final sampleRate = data.getUint32(fmtOffset + 4, Endian.little);
    final bitsPerSample = data.getUint16(fmtOffset + 14, Endian.little);

    if (audioFormat != 1) {
      throw Exception("Only PCM WAV files are supported (got format $audioFormat)");
    }

    if (sampleRate != 16000) {
      // Whisper expects 16kHz. 
      // We could resample here, but for now we'll require 16kHz to keep it simple.
      throw Exception("Whisper requires 16000Hz audio (got $sampleRate)");
    }

    if (numChannels != 1) {
       throw Exception("Whisper requires Mono audio (got $numChannels channels)");
    }

    if (bitsPerSample != 16) {
       throw Exception("Whisper requires 16-bit audio (got $bitsPerSample bits)");
    }

    // Find "data" chunk
    offset = 12;
    int? dataOffset;
    int? dataSize;
    while (offset < bytes.length - 8) {
      final chunkId = data.getUint32(offset, Endian.big);
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      if (chunkId == 0x64617461) { // "data"
        dataOffset = offset + 8;
        dataSize = chunkSize;
        break;
      }
      offset += 8 + chunkSize;
    }

    if (dataOffset == null || dataSize == null) {
      throw Exception("data chunk not found");
    }

    final int numSamples = dataSize ~/ 2;
    final samples = Float32List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final int sample = data.getInt16(dataOffset + (i * 2), Endian.little);
      samples[i] = sample / 32768.0;
    }

    return samples;
  }
}

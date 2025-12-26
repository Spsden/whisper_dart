import 'package:flutter/foundation.dart'; // For compute
import 'package:flutter/material.dart';
import 'dart:async';

import 'dart:io';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:path_provider/path_provider.dart';
import 'package:whisper_dart/whisper_dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _whisperVersion = 'Unknown';
  String _transcription = '';
  bool _isTranscribing = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String version;
    try {
      version = Whisper.version ?? 'Failed to get version';
      
      // Copy model from assets to app documents directory
      final ByteData data = await rootBundle.load('assets/ggml-tiny.bin');
      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File('${dir.path}/ggml-tiny.bin');
      
      if (!await file.exists()) {
          await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      
      print("Model path: ${file.path}");
      final whisper = Whisper(modelPath: file.path);
      print("Initialized: ${whisper.isInitialized}");

    } catch (e) {
      print(e);
      version = 'Failed to get version: $e';
    }
    
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _whisperVersion = version;
    });

  }

  Future<void> _transcribeFile() async {
      setState(() {
          _isTranscribing = true;
          _transcription = "Reading file...";
      });
      
      try {
          // Load audio file from assets
          final ByteData data = await rootBundle.load('assets/jfk.wav');
          
          setState(() {
             _transcription = "Decoding WAV...";
          });

          // Parse WAV - assumes 16-bit mono 16kHz
          // Skip 44 byte header
          final headerSize = 44;
          if (data.lengthInBytes < headerSize) {
               throw Exception("File too small");
          }
          
          final bytes = data.buffer.asUint8List(headerSize);
          final samples = <double>[];
          
          // Convert Int16 to Float32 [-1.0, 1.0]
          // data is ByteData. getInt16 handles endianness (default big, we need little for WAV usually?)
          // WAV is Little Endian usually.
          for (var i = 0; i < bytes.length; i += 2) {
              if (i + 1 < bytes.length) {
                  // asInt16 is not available on Uint8List directly, use ByteData
                  // But creating ByteData for every sample is slow.
                  // Better: view
                  // Actually the whole `data` is ByteData.
                  // Just use it.
                  final sample = data.getInt16(i + headerSize, Endian.little);
                  samples.add(sample / 32768.0);
              }
          }
          
          setState(() {
             _transcription = "Transcribing (${samples.length} samples)...";
          });

          setState(() {
             _transcription = "Transcribing (${samples.length} samples)...";
          });

          final dir = await getApplicationDocumentsDirectory();
          final modelPath = '${dir.path}/ggml-tiny.bin';
          
          // Run in background isolate
          final text = await compute(_transcribeBackground, _TranscriptionRequest(modelPath, samples));
          
          setState(() {
              _transcription = text;
          });

      } catch (e) {
          setState(() {
              _transcription = "Error: $e";
          });
      } finally {
          setState(() {
              _isTranscribing = false;
          });
      }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Whisper.dart Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Whisper.cpp Version: $_whisperVersion\n'),
              const SizedBox(height: 20),
              if (_isTranscribing)
                  const CircularProgressIndicator()
              else
                  ElevatedButton(
                      onPressed: _transcribeFile, 
                      child: const Text("Transcribe 'jfk.wav'"),
                  ),
              const SizedBox(height: 20),
              Expanded(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(_transcription),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranscriptionRequest {
  final String modelPath;
  final List<double> samples;

  _TranscriptionRequest(this.modelPath, this.samples);
}

// Top-level function for isolate
String _transcribeBackground(_TranscriptionRequest request) {
    final whisper = Whisper(modelPath: request.modelPath);
    final text = whisper.transcribe(request.samples);
    whisper.dispose();
    return text;
}

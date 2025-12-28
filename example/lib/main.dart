import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';

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
  WhisperIsolate? _whisperIsolate;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _initIsolate();
  }

  Future<void> _initIsolate() async {
    try {
      // Wait for file to exist if not already?
      // Actually initPlatformState copies it.
      // We can't init isolate until we are sure model is there.
      // So let's defer init.
    } catch (e) {
      print("Error initing isolate: $e");
    }
  }

  @override
  void dispose() {
    _whisperIsolate?.dispose();
    super.dispose();
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
      whisper
          .dispose(); // Only checking init for main thread logic, but we want Isolate for work.

      // Init isolate now that model exists
      _whisperIsolate = await WhisperIsolate.create(modelPath: file.path);
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
      _transcription = "Preparing audio...";
    });

    try {
      // 1. Copy jfk.wav from assets to local file system
      final ByteData data = await rootBundle.load('assets/jfk.wav');
      final Directory dir = await getApplicationDocumentsDirectory();
      final File wavFile = File('${dir.path}/jfk.wav');
      
      if (!await wavFile.exists()) {
        await wavFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }

      setState(() {
        _transcription = "Transcribing...";
      });

      // 2. Pass file path to Isolate
      final text = await _whisperIsolate!.transcribe(
        audioFile: wavFile.path,
        nThreads: 4,
      );

      setState(() {
        _transcription = text;
      });
    } catch (e) {
      setState(() {
        _transcription = "Error: $e";
      });
      print(e);
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
        appBar: AppBar(title: const Text('Whisper.dart Example')),
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

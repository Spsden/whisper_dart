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
              const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      "To test actual transcription, you need to copy a 'ggml-tiny.bin' model to the device and initialize Whisper(modelPath: ...)",
                      textAlign: TextAlign.center,
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

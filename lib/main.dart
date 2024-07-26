import 'dart:io';
import 'package:flutter/material.dart';
import 'package:model_testing/image_processor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grimace Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImageProcessor _imageProcessor = ImageProcessor();
  File? _filePath;
  String _result = '';
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _imageProcessor.initModel();
  }

  @override
  void dispose() {
    _imageProcessor.dispose();
    super.dispose();
  }

  void _updateImage(File image, String result, double confidence) {
    setState(() {
      _filePath = image;
      _result = result;
      _confidence = confidence;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grimace Detection Mode"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Card(
                elevation: 20,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: 300,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 18),
                        Container(
                          height: 280,
                          width: 280,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                              image: AssetImage('assets/upload.jpg'),
                            ),
                          ),
                          child: _filePath == null
                              ? const Text('')
                              : Image.file(
                            _filePath!,
                            fit: BoxFit.fill,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                _result,
                                style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (_confidence > 0)
                            const SizedBox(height: 12),
                          if (_confidence > 0)
                            Text(
                              "Confidence: ${_confidence.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                        ],
                      ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _imageProcessor.pickImageFromCamera(_updateImage);
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    foregroundColor: Colors.black),
                child: const Text("Take a Photo"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _imageProcessor.pickImageFromGallery(_updateImage);
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    foregroundColor: Colors.black),
                child: const Text("Choose from Gallery"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

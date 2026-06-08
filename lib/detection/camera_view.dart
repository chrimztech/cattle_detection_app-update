// detection/camera_view.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'detection_service.dart';
import 'yolo_parser.dart';
import 'results_page.dart';

class CameraView extends StatefulWidget {
  final List<CameraDescription> cameras;
  final DetectionService detectionService;

  const CameraView({
    super.key,
    required this.cameras,
    required this.detectionService,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late CameraController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureAndDetect() async {
    if (!_controller.value.isInitialized) return;

    final XFile file = await _controller.takePicture();
    final bytes = await file.readAsBytes();

    // Run YOLO detection
    final List<DetectionResult> results = widget.detectionService.runModel(
      bytes,
      _controller.value.previewSize!.width.toInt(),
      _controller.value.previewSize!.height.toInt(),
    );

    // Navigate to results page (which now fetches cattle info)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetectionResultsPage(
          results: results,
          imageBytes: bytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cattle Detection')),
      body: CameraPreview(_controller),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureAndDetect,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

// detection/detection_service.dart
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'yolo_parser.dart';
import 'package:flutter/material.dart';

class DetectionService {
  late Interpreter _interpreter;
  late YoloParser _parser;

  final int inputSize = 320;
  late int numValuesPerBox;

  DetectionService({
    required List<String> labels,
  }) {
    _parser = YoloParser(labels: labels, threshold: 0.5);
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('best.tflite');
      debugPrint("✅ YOLO model loaded");

      for (var i = 0; i < _interpreter.getInputTensors().length; i++) {
        debugPrint("Input[$i] shape: ${_interpreter.getInputTensor(i).shape}");
        debugPrint("Input[$i] type: ${_interpreter.getInputTensor(i).type}");
      }

      var outputShape = _interpreter.getOutputTensor(0).shape;
      if (outputShape.length >= 3) {
        numValuesPerBox = outputShape[2];
      } else {
        throw Exception("Invalid output tensor shape. Expected 3 dimensions.");
      }
      debugPrint("Output[0] shape: $outputShape");
      debugPrint("Output[0] type: ${_interpreter.getOutputTensor(0).type}");
      debugPrint("Dynamically set numValuesPerBox to: $numValuesPerBox");
    } catch (e) {
      debugPrint("❌ Error loading model: $e");
      rethrow;
    }
  }

  /// Preprocess image: resize to [inputSize, inputSize] and normalize [0,1]
  Float32List preprocessCameraImage(Uint8List bytes, int width, int height) {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception("Unable to decode image");

    img.Image resized = img.copyResize(image, width: inputSize, height: inputSize);

    var buffer = Float32List(inputSize * inputSize * 3);
    int index = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[index++] = pixel.r / 255.0;
        buffer[index++] = pixel.g / 255.0;
        buffer[index++] = pixel.b / 255.0;
      }
    }

    return buffer;
  }

  /// Run inference and return parsed detections
  List<DetectionResult> runModel(Uint8List imageBytes, int width, int height) {
    try {
      var preprocessedImage = preprocessCameraImage(imageBytes, width, height);
      
      // Reshape the Float32List into the required tensor shape [1, 320, 320, 3]
      // This is a more efficient and correct way to prepare the input
      var input = preprocessedImage.reshape([1, inputSize, inputSize, 3]);

      var output = List.generate(
        1,
        (_) => List.generate(25200, (_) => List.filled(numValuesPerBox, 0.0)),
      );

      _interpreter.run(input, output);

      return _parser.parse(
        output[0],
        Size(width.toDouble(), height.toDouble()),
      );
    } catch (e, stack) {
      debugPrint("❌ Error running model: $e");
      debugPrint(stack.toString());
      return [];
    }
  }

  /// Crop a detected bounding box from the original image
  img.Image cropDetection(img.Image original, DetectionResult r) {
    int x = r.x.toInt();
    int y = r.y.toInt();
    int w = r.width.toInt();
    int h = r.height.toInt();

    x = x.clamp(0, original.width - 1);
    y = y.clamp(0, original.height - 1);
    w = w.clamp(1, original.width - x);
    h = h.clamp(1, original.height - y);

    return img.copyCrop(
      original,
      x: x,
      y: y,
      width: w,
      height: h,
    );
  }
}
// detection/yolo_parser.dart
import 'dart:math';
import 'package:flutter/material.dart';

class DetectionResult {
  final String label;
  final double confidence;
  final Rect rect;

  DetectionResult({required this.label, required this.confidence, required this.rect});

  // Added getters to match old usage
  double get x => rect.left;
  double get y => rect.top;
  double get width => rect.width;
  double get height => rect.height;
}

class YoloParser {
  final List<String> labels;
  final double threshold;

  YoloParser({required this.labels, this.threshold = 0.5});

  /// Parse YOLOv8 TFLite output
  List<DetectionResult> parse(List<dynamic> output, Size imageSize) {
    List<DetectionResult> results = [];

    for (var detection in output) {
      double confidence = detection[4]; // objectness
      if (confidence < threshold) continue;

      int classIndex = detection.sublist(5).indexWhere(
        (x) => x == detection.sublist(5).reduce(max),
      );
      double classProb = detection[5 + classIndex] * confidence;
      if (classProb < threshold) continue;

      double cx = detection[0];
      double cy = detection[1];
      double w = detection[2];
      double h = detection[3];

      Rect rect = Rect.fromCenter(
        center: Offset(cx * imageSize.width, cy * imageSize.height),
        width: w * imageSize.width,
        height: h * imageSize.height,
      );

      results.add(DetectionResult(
        label: labels[classIndex],
        confidence: classProb,
        rect: rect,
      ));
    }

    return results;
  }
}

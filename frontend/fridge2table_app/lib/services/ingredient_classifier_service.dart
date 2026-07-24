import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassificationResult {
  final String label;
  final double confidence;

  ClassificationResult(this.label, this.confidence);
}

class IngredientClassifierService {
  static const String _modelAsset =
      'assets/models/ingredient_classifier_v4.tflite';
  static const String _classNamesAsset = 'assets/models/class_names_v4.json';
  static const int _inputSize = 224;

  static Interpreter? _interpreter;
  static List<String>? _classNames;

  static Future<void> initialize() async {
    if (_interpreter != null && _classNames != null) return;

    _interpreter = await Interpreter.fromAsset(_modelAsset);

    final jsonStr = await rootBundle.loadString(_classNamesAsset);
    _classNames = List<String>.from(jsonDecode(jsonStr));
  }

  static Future<List<ClassificationResult>> classify(
    String imagePath, {
    int topK = 5,
  }) async {
    final interpreter = _interpreter;
    final classNames = _classNames;

    if (interpreter == null || classNames == null) {
      throw StateError(
        "IngredientClassifierService.initialize() must be called first",
      );
    }

    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception("Could not decode captured image");
    }

    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
    );

    final input = [
      List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            pixel.r.toDouble(),
            pixel.g.toDouble(),
            pixel.b.toDouble(),
          ];
        }),
      ),
    ];

    final output = [List.filled(classNames.length, 0.0)];

    interpreter.run(input, output);

    final scores = output[0];

    final indices = List.generate(scores.length, (i) => i);
    indices.sort((a, b) => scores[b].compareTo(scores[a]));

    return indices
        .take(topK)
        .map((i) => ClassificationResult(classNames[i], scores[i]))
        .toList();
  }
}

import 'dart:io';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image/image.dart' as img;

class QualityGateResult {
  final bool brightnessOk;
  final bool bodyVisible;
  final bool poseConfidenceOk;
  final String? message;

  const QualityGateResult({
    required this.brightnessOk,
    required this.bodyVisible,
    required this.poseConfidenceOk,
    this.message,
  });
}

class QualityGateService {
  const QualityGateService();

  Future<QualityGateResult> evaluate({
    required String imagePath,
    required PoseDetector poseDetector,
  }) async {
    final brightnessOk = await _estimateBrightnessOk(imagePath);

    // Pose analysis on the still frame
    final input = InputImage.fromFilePath(imagePath);
    final poses = await poseDetector.processImage(input);
    bool bodyVisible = false;
    double avgConf = 0.0;
    if (poses.isNotEmpty) {
      final lm = poses.first.landmarks.values.toList();
      bodyVisible = lm.length >= 33; // all landmarks present
      if (lm.isNotEmpty) {
        avgConf = lm.map((e) => e.likelihood).reduce((a, b) => a + b) / lm.length;
      }
    }
    final confidenceOk = avgConf >= 0.7;

    String? msg;
    if (!brightnessOk) {
      msg = 'The lighting is a bit low. Please find a brighter area to get the best analysis.';
    } else if (!bodyVisible) {
      msg = 'Please stand further back. We need to see your whole body to analyze your performance.';
    } else if (!confidenceOk) {
      msg = 'The app is having trouble seeing you clearly. Please try again with a better camera angle or lighting.';
    }

    return QualityGateResult(
      brightnessOk: brightnessOk,
      bodyVisible: bodyVisible,
      poseConfidenceOk: confidenceOk,
      message: msg,
    );
  }

  Future<bool> _estimateBrightnessOk(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return true; // don't block if decode failed
      // Downscale for speed
      final small = img.copyResize(decoded, width: 64);
      final data = small.getBytes(order: img.ChannelOrder.rgb);
      int sum = 0;
      for (int i = 0; i < data.length; i += 3) {
        final r = data[i];
        final g = data[i + 1];
        final b = data[i + 2];
        final lum = (0.2126 * r + 0.7152 * g + 0.0722 * b).round();
        sum += lum;
      }
      final avg = sum / (data.length / 3);
      return avg >= 50.0; // threshold per spec
    } catch (_) {
      return true; // avoid blocking recording if something goes wrong
    }
  }
}


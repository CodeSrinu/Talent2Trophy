import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseUtils {
  static double angleBetween(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final v1x = a.x - b.x; final v1y = a.y - b.y;
    final v2x = c.x - b.x; final v2y = c.y - b.y;
    final dot = v1x * v2x + v1y * v2y;
    final m1 = math.sqrt(v1x * v1x + v1y * v1y);
    final m2 = math.sqrt(v2x * v2x + v2y * v2y);
    final cosT = (m1 == 0 || m2 == 0) ? 1.0 : (dot / (m1 * m2)).clamp(-1.0, 1.0);
    return math.acos(cosT) * 180 / math.pi;
  }

  static double distance(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x; final dy = a.y - b.y;
    return math.sqrt(dx*dx + dy*dy);
  }

  // Head-to-ankle size proxy, robust to partial occlusion by using available foot
  static double personSize(Pose p) {
    final head = p.landmarks[PoseLandmarkType.nose] ?? p.landmarks[PoseLandmarkType.leftEye];
    final a1 = p.landmarks[PoseLandmarkType.leftAnkle];
    final a2 = p.landmarks[PoseLandmarkType.rightAnkle];
    if (head == null || (a1 == null && a2 == null)) return 1.0;
    final ankle = a1 ?? a2!;
    return distance(head, ankle).clamp(1.0, 1e6);
  }
}


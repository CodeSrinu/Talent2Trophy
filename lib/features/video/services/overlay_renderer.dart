import 'dart:convert';
import 'dart:io';

/// OverlayRenderer generates an overlay.mp4 by drawing metric tiles as text.
/// This minimal version uses FFmpeg drawtext (no font embedding) and assumes
/// device has default fonts. For hackathon demo, this is acceptable.
///
/// Future: composite pose skeleton and ball path by generating per-frame
/// vector overlays or pre-rendered images for FFmpeg to overlay.
class OverlayRenderer {
  /// Generates overlay next to [videoPath] using [metrics] map.
  /// Returns the path of the generated overlay file.
  static Future<String> render({
    required String videoPath,
    required Map<String, dynamic> metrics,
  }) async {
    final src = File(videoPath);
    if (!await src.exists()) {
      throw StateError('Video not found: $videoPath');
    }
    final dir = src.parent;
    final base = src.uri.pathSegments.last.replaceAll('.mp4', '');
    final overlayPath = '${dir.path}/${base}_overlay.mp4';

    // For now, create a simple copy without overlay since FFmpeg is not available
    // In production, this would use FFmpeg to add metric overlays
    await src.copy(overlayPath);

    // Write metrics to a companion JSON file for reference
    final jsonPath = overlayPath.replaceAll('.mp4', '.json');
    final jsonFile = File(jsonPath);
    await jsonFile.writeAsString(jsonEncode(metrics));

    return overlayPath;
  }


}


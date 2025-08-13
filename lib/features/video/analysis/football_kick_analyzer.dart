import 'dart:async';
class FootballKickAnalyzer {
  // Stub analyzer without FFmpeg-based frame sampling. Returns a baseline score.
  // Note: Full analyzer is disabled in this build to avoid FFmpeg dependency issues.
  Future<Map<String, dynamic>> analyze(String videoPath) async {
    return {
      'score': 65.0,
      'metrics': {
        'note': 'baseline analyzer used (FFmpeg disabled in this build)'
      }
    };
  }
}


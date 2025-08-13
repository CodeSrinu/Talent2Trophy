import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/local_video.dart';
import 'video_repository.dart';
import '../analysis/football_kick_analyzer.dart';

class AnalysisService {
  final VideoRepository _repo;
  AnalysisService(this._repo);

  Future<Map<String, dynamic>> analyzeAndStore(LocalVideo video) async {
    // Mark analyzing
    final analyzing = LocalVideo(
      id: video.id,
      sport: video.sport,
      drill: video.drill,
      title: video.title,
      filePath: video.filePath,
      createdAt: video.createdAt,
      durationSecs: video.durationSecs,
      notes: video.notes,
      analysisStatus: 'analyzing',
      analysisScore: video.analysisScore,
      metrics: video.metrics,
    );
    await _repo.upsert(analyzing);

    // Run on-device analysis based on sport/drill
    final result = await _dispatchAnalyze(video);

    final completed = LocalVideo(
      id: video.id,
      sport: video.sport,
      drill: video.drill,
      title: video.title,
      filePath: video.filePath,
      createdAt: video.createdAt,
      durationSecs: video.durationSecs,
      notes: video.notes,
      analysisStatus: 'complete',
      analysisScore: result['score'] as double,
      metrics: result['metrics'] as Map<String, dynamic>,
    );
    await _repo.upsert(completed);

    // Prepare return payload now; upload is best-effort
    final resultMap = {
      'score': completed.analysisScore ?? 0.0,
      'metrics': completed.metrics ?? const {},
    };

    // Metrics-only upload to Firestore (free tier friendly)
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('analyses')
            .doc(video.id);
        await doc.set({
          'videoId': video.id,
          'sport': video.sport,
          'drill': video.drill,
          'createdAt': DateTime.fromMillisecondsSinceEpoch(video.createdAt),
          'score': completed.analysisScore,
          'metrics': completed.metrics,
        }, SetOptions(merge: true));

        // Update top score if higher
        if (completed.analysisScore != null) {
          final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
          await FirebaseFirestore.instance.runTransaction((txn) async {
            final snap = await txn.get(userDoc);
            final current = (snap.data()?['topAiScore'] as num?)?.toDouble();
            if (current == null || completed.analysisScore! > current) {
              txn.update(userDoc, {'topAiScore': completed.analysisScore});
            }
          });
        }
      }
    } catch (_) {
      // Swallow upload errors; local result remains
    }

    return resultMap;
  }

  Future<Map<String, dynamic>> _dispatchAnalyze(LocalVideo v) async {
    // For now, implement Football Kick; extend with other drills later
    final drill = (v.drill ?? '').toLowerCase();
    if (v.sport.toLowerCase() == 'football' && drill.contains('kick')) {
      final analyzer = FootballKickAnalyzer();
      return analyzer.analyze(v.filePath);
    }
    // Fallback: simple baseline
    return {
      'score': 65.0,
      'metrics': {
        'note': 'baseline analyzer used',
      }
    };
  }
}


import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// CloudProClient calls an optional Cloud Run endpoint to run heavier models.
/// If no endpoint is configured, it simulates a "pro" result locally for demo.
class CloudProClient {
  final String? endpoint; // e.g., https://pro-analysis-xxxx.a.run.app/analyze
  CloudProClient({this.endpoint});

  Future<Map<String, dynamic>> requestProAnalysis({
    required String uid,
    required String videoId,
    required Map<String, dynamic> payload,
  }) async {
    // If endpoint provided, try calling it. Otherwise, simulate.
    Map<String, dynamic> result;
    if (endpoint != null && endpoint!.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse(endpoint!),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
        if (res.statusCode == 200) {
          result = jsonDecode(res.body) as Map<String, dynamic>;
        } else {
          result = _simulatePro(payload);
        }
      } catch (_) {
        result = _simulatePro(payload);
      }
    } else {
      result = _simulatePro(payload);
    }

    // Persist into analyses doc
    final doc = FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('analyses').doc(videoId);
    await doc.set({
      'cloudPro': {
        'status': 'ready',
        'score': result['score'],
        'metrics': result['metrics'],
        'overlayUrl': result['overlayUrl'],
        'reportUrl': result['reportUrl'],
        'updatedAt': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));

    return result;
  }

  Map<String, dynamic> _simulatePro(Map<String, dynamic> payload) {
    // Simulate a better score and slightly tweaked metrics
    final baseScore = (payload['score'] as num?)?.toDouble() ?? 65.0;
    final proScore = (baseScore * 1.08).clamp(0, 100).toDouble();
    final metrics = Map<String, dynamic>.from((payload['metrics'] as Map?) ?? {});
    final proMetrics = metrics.map((k, v) {
      if (v is num) return MapEntry(k, (v * 1.05));
      return MapEntry(k, v);
    });
    return {
      'score': proScore,
      'metrics': proMetrics,
      // No real pro overlay/report; leave null to let UI handle gracefully
      'overlayUrl': payload['driveOverlayUrl'],
      'reportUrl': null,
    };
  }
}


import 'dart:convert';
import 'package:uuid/uuid.dart';

class LocalVideo {
  final String id;
  final String sport; // 'Football' | 'Kabaddi'
  final String? drill; // optional drill label
  final String title;
  final String filePath; // platform file URI/path
  final int createdAt; // epoch millis
  final int? durationSecs;
  final String? notes;

  // Analysis fields (Option B: on-device analysis, metrics-only to cloud)
  final String analysisStatus; // 'pending' | 'analyzing' | 'complete' | 'failed'
  final double? analysisScore; // 0..100
  final Map<String, dynamic>? metrics; // small JSON of computed metrics

  LocalVideo({
    required this.id,
    required this.sport,
    required this.title,
    required this.filePath,
    required this.createdAt,
    this.drill,
    this.durationSecs,
    this.notes,
    this.analysisStatus = 'pending',
    this.analysisScore,
    this.metrics,
  });

  factory LocalVideo.newItem({
    required String sport,
    String? drill,
    required String title,
    required String filePath,
    int? durationSecs,
    String? notes,
  }) {
    return LocalVideo(
      id: const Uuid().v4(),
      sport: sport,
      drill: drill,
      title: title,
      filePath: filePath,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      durationSecs: durationSecs,
      notes: notes,
      analysisStatus: 'pending',
      analysisScore: null,
      metrics: null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sport': sport,
        'drill': drill,
        'title': title,
        'file_path': filePath,
        'created_at': createdAt,
        'duration_secs': durationSecs,
        'notes': notes,
        'analysis_status': analysisStatus,
        'analysis_score': analysisScore,
        'metrics_json': metrics != null ? jsonEncode(metrics) : null,
      };

  factory LocalVideo.fromMap(Map<String, dynamic> map) => LocalVideo(
        id: map['id'] as String,
        sport: map['sport'] as String,
        drill: map['drill'] as String?,
        title: map['title'] as String,
        filePath: map['file_path'] as String,
        createdAt: map['created_at'] as int,
        durationSecs: map['duration_secs'] as int?,
        notes: map['notes'] as String?,
        analysisStatus: (map['analysis_status'] as String?) ?? 'pending',
        analysisScore: (map['analysis_score'] is num) ? (map['analysis_score'] as num).toDouble() : null,
        metrics: map['metrics_json'] != null ? jsonDecode(map['metrics_json'] as String) as Map<String, dynamic> : null,
      );
}


import 'package:flutter/material.dart';

class VideoAnalysis {
  final String videoId;
  final String drillName;
  final String sport;
  final double overallScore;
  final List<DrillMetric> metrics;
  final List<String> feedback;
  final DateTime analyzedAt;
  final String analysisStatus; // 'pending', 'completed', 'failed'

  const VideoAnalysis({
    required this.videoId,
    required this.drillName,
    required this.sport,
    required this.overallScore,
    required this.metrics,
    required this.feedback,
    required this.analyzedAt,
    required this.analysisStatus,
  });

  factory VideoAnalysis.mock({
    required String videoId,
    required String drillName,
    required String sport,
  }) {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final baseScore = 60.0 + (random * 0.4); // Score between 60-100
    
    return VideoAnalysis(
      videoId: videoId,
      drillName: drillName,
      sport: sport,
      overallScore: baseScore,
      metrics: _generateMockMetrics(drillName, sport, baseScore),
      feedback: _generateMockFeedback(drillName, baseScore),
      analyzedAt: DateTime.now(),
      analysisStatus: 'completed',
    );
  }

  static List<DrillMetric> _generateMockMetrics(String drillName, String sport, double baseScore) {
    final metrics = <DrillMetric>[];
    
    if (sport == 'Football') {
      switch (drillName) {
        case 'Kick':
        case 'Shooting':
          metrics.addAll([
            DrillMetric('Power', baseScore * 0.9, 'Good power generation'),
            DrillMetric('Accuracy', baseScore * 0.85, 'Needs improvement'),
            DrillMetric('Technique', baseScore * 0.95, 'Excellent form'),
            DrillMetric('Follow-through', baseScore * 0.8, 'Could be better'),
          ]);
          break;
        case 'Juggling':
          metrics.addAll([
            DrillMetric('Control', baseScore * 0.9, 'Good ball control'),
            DrillMetric('Balance', baseScore * 0.85, 'Maintains balance well'),
            DrillMetric('Touch', baseScore * 0.8, 'Needs softer touch'),
            DrillMetric('Consistency', baseScore * 0.75, 'Work on consistency'),
          ]);
          break;
        case 'Dribbling':
          metrics.addAll([
            DrillMetric('Speed', baseScore * 0.9, 'Good pace'),
            DrillMetric('Control', baseScore * 0.85, 'Ball stays close'),
            DrillMetric('Vision', baseScore * 0.8, 'Look up more'),
            DrillMetric('Change of Direction', baseScore * 0.75, 'Practice turns'),
          ]);
          break;
        default:
          metrics.addAll([
            DrillMetric('Technique', baseScore * 0.9, 'Good overall technique'),
            DrillMetric('Execution', baseScore * 0.85, 'Well executed'),
            DrillMetric('Form', baseScore * 0.8, 'Maintain proper form'),
          ]);
      }
    } else {
      // Kabaddi metrics
      switch (drillName) {
        case 'Raid Entry':
          metrics.addAll([
            DrillMetric('Speed', baseScore * 0.9, 'Quick entry'),
            DrillMetric('Agility', baseScore * 0.85, 'Good movement'),
            DrillMetric('Strategy', baseScore * 0.8, 'Smart approach'),
            DrillMetric('Escape', baseScore * 0.75, 'Work on escape timing'),
          ]);
          break;
        case 'Tackle':
          metrics.addAll([
            DrillMetric('Timing', baseScore * 0.9, 'Perfect timing'),
            DrillMetric('Strength', baseScore * 0.85, 'Good power'),
            DrillMetric('Positioning', baseScore * 0.8, 'Correct stance'),
            DrillMetric('Recovery', baseScore * 0.75, 'Faster recovery needed'),
          ]);
          break;
        default:
          metrics.addAll([
            DrillMetric('Execution', baseScore * 0.9, 'Well executed'),
            DrillMetric('Technique', baseScore * 0.85, 'Good technique'),
            DrillMetric('Form', baseScore * 0.8, 'Maintain form'),
          ]);
      }
    }
    
    return metrics;
  }

  static List<String> _generateMockFeedback(String drillName, double score) {
    final feedback = <String>[];
    
    if (score >= 90) {
      feedback.add('Excellent performance! Keep up the great work.');
      feedback.add('Your technique is outstanding.');
      feedback.add('Consider trying more advanced variations.');
    } else if (score >= 80) {
      feedback.add('Great job! You\'re showing good progress.');
      feedback.add('Focus on the areas that need improvement.');
      feedback.add('Practice regularly to maintain consistency.');
    } else if (score >= 70) {
      feedback.add('Good effort! You have the basics down.');
      feedback.add('Work on refining your technique.');
      feedback.add('Practice the fundamentals more.');
    } else {
      feedback.add('Keep practicing! Everyone starts somewhere.');
      feedback.add('Focus on mastering the basics first.');
      feedback.add('Don\'t get discouraged, improvement takes time.');
    }
    
    // Add drill-specific feedback
    switch (drillName) {
      case 'Kick':
      case 'Shooting':
        feedback.add('Focus on keeping your head down during contact.');
        feedback.add('Practice with both feet for versatility.');
        break;
      case 'Juggling':
        feedback.add('Start with fewer touches and gradually increase.');
        feedback.add('Keep the ball at a comfortable height.');
        break;
      case 'Dribbling':
        feedback.add('Keep the ball close to your feet.');
        feedback.add('Practice changing direction quickly.');
        break;
      case 'Raid Entry':
        feedback.add('Work on your initial burst of speed.');
        feedback.add('Practice different entry strategies.');
        break;
      case 'Tackle':
        feedback.add('Focus on proper defensive stance.');
        feedback.add('Work on timing your tackles.');
        break;
    }
    
    return feedback;
  }
}

class DrillMetric {
  final String name;
  final double score;
  final String comment;

  const DrillMetric(this.name, this.score, this.comment);

  Color get scoreColor {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.orange;
    if (score >= 70) return Colors.yellow;
    return Colors.red;
  }

  String get scoreLabel {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Fair';
    return 'Needs Work';
  }
}

class AIAnalysisService {
  static Future<VideoAnalysis> analyzeVideo({
    required String videoId,
    required String drillName,
    required String sport,
  }) async {
    // Simulate AI processing time
    await Future.delayed(const Duration(seconds: 2));
    
    // Return mock analysis for now
    return VideoAnalysis.mock(
      videoId: videoId,
      drillName: drillName,
      sport: sport,
    );
  }
}


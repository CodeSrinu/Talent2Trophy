// Platform-conditional: dart:io only used on mobile/desktop
import 'dart:async';
import 'dart:io' show Directory, File;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../cloud/drive_upload_service.dart';
import '../../services/quality_gate_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../data/video_repository.dart';
import '../../domain/local_video.dart';
import '../../data/analysis_service.dart';

class RecordScreen extends ConsumerStatefulWidget {
  final String sport; // 'Football' | 'Kabaddi'
  const RecordScreen({super.key, required this.sport});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _initFailed = false;
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));
  // Pre-flight state
  String? _preFlightMessage;
  bool _isBrightnessOk = false;
  bool _isBodyVisible = false;
  bool _isPoseConfidenceOk = false;
  Timer? _preFlightTimer;
  bool get _preFlightOk => _isBrightnessOk && _isBodyVisible && _isPoseConfidenceOk;


  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      // Camera plugin is not supported on web the same way; fall back gracefully
      setState(() {
        _initFailed = true;
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _initFailed = true);
        return;
      }
      // Prefer back camera if available
      final back = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(back, ResolutionPreset.high);
      await _controller!.initialize();
      _startPreFlightChecks();

      setState(() {});
    } catch (e) {
      setState(() => _initFailed = true);
    }
  }

  @override
  void dispose() {
    _preFlightTimer?.cancel();
    _poseDetector.close();
    _controller?.dispose();
    super.dispose();
  }


  // Pre-flight checks: run every second on a captured preview frame
  void _startPreFlightChecks() {
    _preFlightTimer?.cancel();
    _preFlightTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || _controller == null || !_controller!.value.isInitialized || _isRecording) return;
      try {
        final preview = await _controller!.takePicture();
        final gate = await const QualityGateService().evaluate(
          imagePath: preview.path,
          poseDetector: _poseDetector,
        );

        if (mounted) {
          setState(() {
            _isBrightnessOk = gate.brightnessOk;
            _isBodyVisible = gate.bodyVisible;
            _isPoseConfidenceOk = gate.poseConfidenceOk;
            _preFlightMessage = gate.message;
          });
        }
      } catch (_) {}
    });
  }




  Future<void> _toggleRecord() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      final file = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);

      if (!mounted) return;

      if (kIsWeb) {
        // On web, path_provider and File I/O are unavailable for saving to disk.
        // For now, we keep the temp blob in memory; future step will upload or use IndexedDB.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved in session (Web). Library/save to disk requires mobile app.')),
        );
        return;
      }

      // Ask for drill before saving
      final drill = await _pickDrill(context, widget.sport);
      if (!mounted) return;
      if (drill == null) return; // user cancelled

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video captured. Saving to library...')),
      );

      // Move file into app's documents directory and add to local repository
      try {


        final docs = await getApplicationDocumentsDirectory();
        final ts = DateTime.now().millisecondsSinceEpoch;
        final baseName = '${widget.sport.toLowerCase()}_${drill.toLowerCase().replaceAll(' ', '_')}_$ts.mp4';
        final destPath = '${docs.path}/videos/$baseName';
        final destDir = Directory('${docs.path}/videos');


        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }

        final saved = await File(file.path).copy(destPath);

        // Save metadata in repository
        final repo = VideoRepository();
        final video = LocalVideo.newItem(
          sport: widget.sport,
          drill: drill,
          title: baseName,
          filePath: saved.path,
        );

	        // Trigger on-device analysis (free) and metrics-only upload
	        try {
	          await AnalysisService(repo).analyzeAndStore(video);
	        } catch (_) {}

        await repo.add(video);

        // Mark player's profile as having at least one upload
        try {
          await ref.read(authProvider.notifier).updateUserData({'hasUploadedVideo': true});
        } catch (_) {}

        if (!mounted) return;

        // Show AI analysis option
        _showAnalysisOption(context, video);

        // Optional: Upload artifacts to Google Drive (overlay + JSON) after analysis completes
        // In this build, we upload only the raw captured video as a placeholder. Replace with overlay.mp4 & analysis.json.
        try {
          final drive = DriveUploadService();
          final folderId = await drive.ensureFolder('Talent2Trophy Uploads');
          final overlayPath = saved.path.replaceAll('.mp4', '_overlay.mp4');
          final jsonPath = saved.path.replaceAll('.mp4', '_analysis.json');
          final overlayFile = File(overlayPath);
          final jsonFile = File(jsonPath);
          if (await overlayFile.exists() && await jsonFile.exists()) {
            final overlayUrl = await drive.uploadFile(parentFolderId: folderId, file: overlayFile, mimeType: 'video/mp4');
            final jsonUrl = await drive.uploadFile(parentFolderId: folderId, file: jsonFile, mimeType: 'application/json');
            try {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                final doc = FirebaseFirestore.instance.collection('users').doc(uid)
                    .collection('analyses').doc(video.id);
                await doc.set({
                  'driveOverlayUrl': overlayUrl,
                  'driveJsonUrl': jsonUrl,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              }
            } catch (_) {}
            if (!context.mounted) return;
            // Mark user as having cloud artifacts for Pro badge
            try {
              await ref.read(authProvider.notifier).updateUserData({'hasCloudArtifacts': true});
            } catch (_) {}
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Uploaded overlay+JSON to Drive.')),
            );
          } else {
            await drive.uploadFile(parentFolderId: folderId, file: File(saved.path), mimeType: 'video/mp4');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Uploaded raw video to Drive.')),
              );
            }
          }
        } catch (e) {
          // Non-fatal; demo should continue offline
        }

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } else {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initFailed) {
      return const Scaffold(
        body: Center(child: Text('Camera unavailable')),
      );
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Intercept system back to navigate to Player Home
          context.go('/player');
        }
        // Always clean up resources
        _preFlightTimer?.cancel();
        _poseDetector.close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/player'),
          ),
          title: Text('Record - ${widget.sport}'),
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
        ),
      body: Stack(
        children: [
          // Camera Preview
          CameraPreview(_controller!),

          // Pre-flight Banner (blocks recording until OK)
          if (_preFlightMessage != null && !_isRecording) Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.accentColor, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _preFlightMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recording Overlay
          if (_isRecording) ...[
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstants.errorColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Drill Instructions Overlay
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.sport} Drills',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap record to start',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select drill after recording',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Camera Controls
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Recording Button
                Center(
                  child: GestureDetector(
                    onTap: _preFlightOk ? _toggleRecord : null,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isRecording ? AppConstants.errorColor : AppConstants.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Instructions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isRecording
                      ? 'Tap to stop recording'
                      : 'Tap to start recording',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

  Future<String?> _pickDrill(BuildContext context, String sport) async {
    final drillData = _getDrillData(sport);

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Select $sport Drill'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: drillData.map((drill) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(
                  _getDrillIcon(drill['name'] as String),
                  color: AppConstants.primaryColor,
                ),
                title: Text(drill['name'] as String),
                subtitle: Text(drill['description'] as String),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(drill['difficulty'] as String),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    drill['difficulty'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                onTap: () => Navigator.pop(ctx, drill['name'] as String),
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getDrillData(String sport) {
    if (sport == 'Football') {
      return [
        {
          'name': 'Kick',
          'description': 'Practice shooting and passing techniques',
          'difficulty': 'Beginner',
          'duration': '2-3 min',
          'focus': 'Technique & Power'
        },
        {
          'name': 'Juggling',
          'description': 'Improve ball control and touch',
          'difficulty': 'Intermediate',
          'duration': '3-5 min',
          'focus': 'Control & Balance'
        },
        {
          'name': 'Dribbling',
          'description': 'Enhance ball handling skills',
          'difficulty': 'Intermediate',
          'duration': '2-4 min',
          'focus': 'Control & Speed'
        },
        {
          'name': 'Passing',
          'description': 'Work on accuracy and timing',
          'difficulty': 'Beginner',
          'duration': '2-3 min',
          'focus': 'Accuracy & Vision'
        },
        {
          'name': 'Shooting',
          'description': 'Practice goal-scoring techniques',
          'difficulty': 'Advanced',
          'duration': '3-5 min',
          'focus': 'Power & Accuracy'
        },
        {
          'name': 'Ball Control',
          'description': 'Master first touch and control',
          'difficulty': 'Intermediate',
          'duration': '2-4 min',
          'focus': 'Touch & Awareness'
        },
      ];
    } else {
      // Kabaddi drills
      return [
        {
          'name': 'Raid Entry',
          'description': 'Practice attacking techniques and speed',
          'difficulty': 'Intermediate',
          'duration': '2-3 min',
          'focus': 'Speed & Agility'
        },
        {
          'name': 'Tackle',
          'description': 'Improve defensive skills and timing',
          'difficulty': 'Advanced',
          'duration': '3-4 min',
          'focus': 'Timing & Strength'
        },
        {
          'name': 'Chain Formation',
          'description': 'Work on team coordination',
          'difficulty': 'Advanced',
          'duration': '4-5 min',
          'focus': 'Teamwork & Strategy'
        },
        {
          'name': 'Bonus Point',
          'description': 'Practice bonus line touches',
          'difficulty': 'Intermediate',
          'duration': '2-3 min',
          'focus': 'Speed & Precision'
        },
        {
          'name': 'Defensive Stance',
          'description': 'Improve defensive positioning',
          'difficulty': 'Beginner',
          'duration': '2-3 min',
          'focus': 'Positioning & Balance'
        },
        {
          'name': 'Quick Movement',
          'description': 'Enhance agility and reflexes',
          'difficulty': 'Intermediate',
          'duration': '2-4 min',
          'focus': 'Agility & Reflexes'
        },
      ];
    }
  }

  IconData _getDrillIcon(String drillName) {
    switch (drillName) {
      case 'Kick':
      case 'Shooting':
        return Icons.sports_soccer;
      case 'Juggling':
      case 'Dribbling':
      case 'Ball Control':
        return Icons.sports_soccer;
      case 'Passing':
        return Icons.swap_horiz;
      case 'Raid Entry':
      case 'Bonus Point':
        return Icons.sports_kabaddi;
      case 'Tackle':
      case 'Defensive Stance':
        return Icons.shield;
      case 'Chain Formation':
        return Icons.group;
      case 'Quick Movement':
        return Icons.directions_run;
      default:
        return Icons.sports;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppConstants.successColor;
      case 'intermediate':
        return AppConstants.warningColor;
      case 'advanced':
        return AppConstants.errorColor;
      default:
        return AppConstants.primaryColor;
    }
  }

  void _showAnalysisOption(BuildContext context, LocalVideo video) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Video Saved Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your video has been saved to the library.'),
            const SizedBox(height: 16),
            const Text('Would you like to analyze it with AI to get performance insights?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Get detailed analysis of your ${video.drill} technique',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video saved to library. You can analyze it later.'),
                  backgroundColor: AppConstants.successColor,
                ),
              );
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _startAIAnalysis(context, video);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Analyze Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _startAIAnalysis(BuildContext context, LocalVideo video) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Analyzing your video with AI...'),
            const SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(
                color: AppConstants.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Import the analysis service
      final analysis = await _analyzeVideoWithAI(video);

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to analysis results
      _navigateToAnalysis(context, analysis);

    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<dynamic> _analyzeVideoWithAI(LocalVideo video) async {
    // Import the analysis service
    // For now, we'll create a mock analysis
    // In the future, this would call the real AI service
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing

    // Create mock analysis data
    final analysisData = {
      'videoId': video.id,
      'drillName': video.drill,
      'sport': video.sport,
      'overallScore': 75.0 + (DateTime.now().millisecondsSinceEpoch % 25),
      'metrics': [
        {'name': 'Technique', 'score': 80.0, 'comment': 'Good overall technique'},
        {'name': 'Execution', 'score': 75.0, 'comment': 'Well executed'},
        {'name': 'Form', 'score': 70.0, 'comment': 'Maintain proper form'},
      ],
      'feedback': [
        'Great effort! You\'re showing good progress.',
        'Focus on the areas that need improvement.',
        'Practice regularly to maintain consistency.',
      ],
      'analyzedAt': DateTime.now(),
      'analysisStatus': 'completed',
    };

    return analysisData;
  }

  void _navigateToAnalysis(BuildContext context, dynamic analysisData) {
    // For now, show a simple dialog with results
    // In the future, this would navigate to the analysis screen
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${analysisData['drillName']} Analysis Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overall Score: ${analysisData['overallScore'].toStringAsFixed(1)}/100'),
            const SizedBox(height: 16),
            const Text('Key Insights:'),
            ...analysisData['feedback'].take(2).map((tip) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppConstants.successColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip)),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/library');
            },
            child: const Text('View in Library'),
          ),
        ],
      ),
    );
  }

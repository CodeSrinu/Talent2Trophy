import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../video/domain/local_video.dart';
import '../../video/data/video_repository.dart';
import '../../video/data/analysis_service.dart';
import '../../video/services/video_storage_service.dart';

// Update sample video URLs here per sport and drill name
const Map<String, Map<String, String>> kSampleDrillVideos = {
  'Football': {
    'Kick': 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
    'Juggling': 'https://samplelib.com/lib/preview/mp4/sample-10s.mp4',
    'Dribbling': 'https://samplelib.com/lib/preview/mp4/sample-15s.mp4',
  },
  'Kabaddi': {
    'Raid Entry': 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
    'Tackle': 'https://samplelib.com/lib/preview/mp4/sample-10s.mp4',
    'Chain Formation': 'https://samplelib.com/lib/preview/mp4/sample-15s.mp4',
  },
};

class DrillsScreen extends ConsumerWidget {
  const DrillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Drills Library')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _recordUploadSection(context, ref),
          const SizedBox(height: 24),
          _sectionHeader(context, 'Your Major Sport'),
          _majorSportCard(context, user?.sport ?? 'Select in Profile', ref),
          const SizedBox(height: 24),
          _sectionHeader(context, 'All Sports'),
          const SizedBox(height: 8),
          _sportGroup(context, 'Football', [
            _drill('Kick', 'Technique & Power'),
            _drill('Juggling', 'Control & Balance'),
            _drill('Dribbling', 'Control & Speed'),
          ]),
          const SizedBox(height: 16),
          _sportGroup(context, 'Kabaddi', [
            _drill('Raid Entry', 'Speed & Stability'),
            _drill('Tackle', 'Strength & Timing'),
            _drill('Chain Formation', 'Team Coordination'),
          ]),
        ],
      ),
    );
  }

  Widget _recordUploadSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _startRecording(context, ref.read(currentUserProvider).value?.sport ?? 'Football'),
                icon: const Icon(Icons.fiber_manual_record, color: Colors.white),
                label: const Text('Record Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _pickFromGallery(context, ref);
                },
                icon: const Icon(Icons.upload_rounded),
                label: const Text('Upload Video'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700));
  }

  Widget _majorSportCard(BuildContext context, String sport, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Icon(sport == 'Kabaddi' ? Icons.sports_kabaddi : Icons.sports_soccer, color: AppConstants.primaryColor),
        title: Text(sport),
        subtitle: const Text('Your primary sport for profile and leaderboards'),
        trailing: TextButton(
          onPressed: () => context.go('/profile'),
          child: const Text('Change'),
        ),
      ),
    );
  }

  Widget _sportGroup(BuildContext context, String sport, List<Map<String, String>> drills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(sport == 'Kabaddi' ? Icons.sports_kabaddi : Icons.sports_soccer, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Text(sport, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ...drills.map((d) => Card(
          child: ListTile(
            title: Text(d['name']!),
            subtitle: Text(d['desc']!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _previewDrill(context, sport, d['name']!),
                  icon: const Icon(Icons.play_circle_fill),
                ),
                IconButton(
                  onPressed: () => _startRecording(context, sport),
                  icon: const Icon(Icons.fiber_manual_record, color: AppConstants.errorColor),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Map<String, String> _drill(String name, String desc) => {'name': name, 'desc': desc};

  void _previewDrill(BuildContext context, String sport, String drill) {
    final url = kSampleDrillVideos[sport]?[drill];

    VideoPlayerController? controller;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          // Lazy init controller inside dialog
          controller ??= (url != null)
              ? VideoPlayerController.networkUrl(Uri.parse(url))
              : null;

          if (controller != null && !controller!.value.isInitialized) {
            controller!.initialize().then((_) {
              controller!..setLooping(true)..play();
              setState(() {});
            });
          }

          Widget content;
          if (controller != null && controller!.value.isInitialized) {
            content = AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: VideoPlayer(controller!),
            );
          } else {
            content = Container(
              width: 300,
              height: 180,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.video_library, size: 48, color: AppConstants.primaryColor),
              ),
            );
          }

          return AlertDialog(
            title: Text('$sport · $drill'),
            content: SizedBox(width: 320, child: content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _startRecording(context, sport);
                },
                child: const Text('Try This Drill'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      controller?.dispose();
    });
  }

  void _startRecording(BuildContext context, String sport) {
    context.go('/record/$sport');
  }



  Future<void> _pickFromGallery(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    try {
      final xfile = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
      if (xfile == null) return;

      // Ask sport/drill since gallery can be any content
      final userSport = ref.read(currentUserProvider).value?.sport ?? 'Football';
      if (!context.mounted) return;
      final sport = await _pickSport(context, defaultSport: userSport);
      if (sport == null) return;
      if (!context.mounted) return;
      final drill = await _pickDrill(context, sport);
      if (drill == null) return;

      if (kIsWeb) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Web upload not supported in this build.')));
        return;
      }

      // Save copy into app storage and enqueue analysis
      final storage = VideoStorageService();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final baseName = '${sport.toLowerCase()}_${drill.toLowerCase().replaceAll(' ', '_')}_$ts.mp4';
      final dest = await storage.reserveFilePath(baseName);
      final saved = await File(xfile.path).copy(dest.path);

      final repo = VideoRepository();
      final video = LocalVideo.newItem(
        sport: sport,
        drill: drill,
        title: baseName,
        filePath: saved.path,
      );

      // On-device quick analysis then add to library
      try {
        await AnalysisService(repo).analyzeAndStore(video);
      } catch (_) {}
      await repo.add(video);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video added from gallery.')),
      );

      // Offer AI analysis flow
      // Reuse RecordScreen dialog UX in a future step; for now we just notify
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppConstants.errorColor),
      );
    }
  }

  Future<String?> _pickSport(BuildContext context, {required String defaultSport}) async {
    final sports = ['Football', 'Kabaddi'];
    String selected = defaultSport;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Sport'),
        content: StatefulBuilder(
          builder: (ctx, setState) => DropdownButton<String>(
            value: selected,
            isExpanded: true,
            items: sports.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => selected = v ?? selected),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('Continue')),
        ],
      ),
    );
  }

  Future<String?> _pickDrill(BuildContext context, String sport) async {
    final drills = sport == 'Football'
        ? ['Kick', 'Juggling', 'Dribbling']
        : ['Raid Entry', 'Tackle', 'Chain Formation'];
    String selected = drills.first;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Drill'),
        content: StatefulBuilder(
          builder: (ctx, setState) => DropdownButton<String>(
            value: selected,
            isExpanded: true,
            items: drills.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => selected = v ?? selected),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('Continue')),
        ],
      ),
    );
  }


}


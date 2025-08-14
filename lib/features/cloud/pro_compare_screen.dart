import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ProCompareScreen extends StatefulWidget {
  final String localOverlayPath;
  final String? cloudOverlayUrl;
  const ProCompareScreen({super.key, required this.localOverlayPath, this.cloudOverlayUrl});

  @override
  State<ProCompareScreen> createState() => _ProCompareScreenState();
}

class _ProCompareScreenState extends State<ProCompareScreen> {
  late VideoPlayerController _local;
  VideoPlayerController? _cloud;
  bool _readyLocal = false;
  bool _readyCloud = false;

  @override
  void initState() {
    super.initState();
    _local = VideoPlayerController.file(File(widget.localOverlayPath))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _readyLocal = true);
        _local.setLooping(true);
        _local.play();
      });
    if ((widget.cloudOverlayUrl ?? '').isNotEmpty) {
      _cloud = VideoPlayerController.networkUrl(Uri.parse(widget.cloudOverlayUrl!))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() => _readyCloud = true);
          _cloud!.setLooping(true);
          _cloud!.play();
        });
    }
  }

  @override
  void dispose() {
    _local.dispose();
    _cloud?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare: Local vs Pro')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Local Overlay', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _readyLocal
                              ? AspectRatio(
                                  aspectRatio: _local.value.aspectRatio,
                                  child: VideoPlayer(_local),
                                )
                              : const Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Pro Overlay', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: (widget.cloudOverlayUrl ?? '').isEmpty
                              ? const Center(child: Text('No Pro overlay yet'))
                              : (_readyCloud
                                  ? AspectRatio(
                                      aspectRatio: _cloud!.value.aspectRatio,
                                      child: VideoPlayer(_cloud!),
                                    )
                                  : const Center(child: CircularProgressIndicator())),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Score Delta and Metrics Comparison (placeholder)'),
          ],
        ),
      ),
    );
  }
}


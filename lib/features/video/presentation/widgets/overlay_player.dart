import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class OverlayPlayer extends StatefulWidget {
  final String path;
  const OverlayPlayer({super.key, required this.path});
  @override
  State<OverlayPlayer> createState() => _OverlayPlayerState();
}

class _OverlayPlayerState extends State<OverlayPlayer> {
  late VideoPlayerController _player;
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    _player = VideoPlayerController.file(File(widget.path))..initialize().then((_) {
      setState(() => _ready = true);
      _player.play();
    });
  }
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overlay')),
      body: Center(
        child: _ready
            ? AspectRatio(
                aspectRatio: _player.value.aspectRatio,
                child: VideoPlayer(_player),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _ready
          ? FloatingActionButton(
              onPressed: () => _player.value.isPlaying ? _player.pause() : _player.play(),
              child: Icon(_player.value.isPlaying ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
  }
}


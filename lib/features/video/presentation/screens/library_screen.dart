import 'package:flutter/material.dart';
import 'dart:io' show File;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../data/video_repository.dart';
import '../widgets/overlay_player.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../cloud/cloud_pro_client.dart';
import '../../../cloud/pro_compare_screen.dart';

import '../../services/file_ops.dart';
import 'package:talent2trophy/core/constants/app_constants.dart';



class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  List<_Item> _items = [];
  bool _loading = true;
  String? _sportFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = VideoRepository();
    final vids = await repo.list(sport: _sportFilter);
    _items = vids
        .map((v) => _Item(
              v.id,
              v.title,
              v.filePath,
              v.sport,
              drill: v.drill,
              notes: v.notes,
              analysisStatus: v.analysisStatus,
              analysisScore: v.analysisScore,
            ))
        .toList();
    setState(() => _loading = false);
  }

  Future<void> _rename(_Item it) async {
    final controller = TextEditingController(text: it.title);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Video'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await VideoRepository().updateTitle(it.id, newName);
      await _load();
    }
  }

  Future<void> _delete(_Item it) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      // Remove file (best-effort) and metadata
      await deleteFilePath(it.path);
      await VideoRepository().delete(it.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/player'),
        ),
        title: const Text('Library'),
        actions: [
          PopupMenuButton<String?>(
            initialValue: _sportFilter,
            onSelected: (val) async {
              setState(() => _sportFilter = val);
              await _load();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: null, child: Text('All')),
              ...AppConstants.sportsTypes.map((sport) =>
                PopupMenuItem(value: sport, child: Text(sport))
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No videos yet'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final it = _items[i];
                    return Dismissible(
                      key: ValueKey(it.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        await _delete(it);
                        return false; // We'll refresh manually
                      },
                      child: ListTile(
                        title: Text(it.title),
                        subtitle: Text(
                          '${it.sport}${it.drill != null ? ' • ${it.drill}' : ''}'
                          '${it.analysisStatus == 'analyzing' ? ' • Analyzing…' : it.analysisScore != null ? ' • Score: ${it.analysisScore!.toStringAsFixed(1)}' : ''}',
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => _DetailsScreen(item: it)),
                          );
                          await _load();
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _rename(it),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _Item {
  final String id;
  final String title;
  final String path;
  final String sport;
  final String? drill;
  final String? notes;
  final String? analysisStatus;
  final double? analysisScore;
  _Item(this.id, this.title, this.path, this.sport, {this.drill, this.notes, this.analysisStatus, this.analysisScore});
}

class _DetailsScreen extends StatefulWidget {
  final _Item item;
  const _DetailsScreen({required this.item});
  @override
  State<_DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<_DetailsScreen> {
  late TextEditingController _title;
  late TextEditingController _notes;
  late VideoPlayerController _player;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.item.title);
    _notes = TextEditingController(text: widget.item.notes ?? '');
    _player = VideoPlayerController.networkUrl(Uri.file(widget.item.path))
      ..initialize().then((_) => setState(() => _ready = true));
  }

  @override
  void dispose() {
    _player.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final notes = _notes.text.trim();
    await VideoRepository().updateTitle(widget.item.id, title);
    await VideoRepository().updateNotes(widget.item.id, notes.isEmpty ? null : notes);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_ready) AspectRatio(
            aspectRatio: _player.value.aspectRatio,
            child: VideoPlayer(_player),
          ) else const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes (coming soon)', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final overlayPath = widget.item.path.replaceAll('.mp4', '_overlay.mp4');
                  final exists = await File(overlayPath).exists();
                  if (!context.mounted) return;
                  if (!exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Overlay not available yet. Analyze the video first.')),
                    );
                    return;
                  }
                  if (!context.mounted) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => OverlayPlayer(path: overlayPath)),
                  );
                },
                icon: const Icon(Icons.slideshow),
                label: const Text('View Overlay'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Requesting Pro analysis...')),
                    );
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    String? driveOverlayUrl;
                    if (uid != null) {
                      final doc = await FirebaseFirestore.instance
                          .collection('users').doc(uid)
                          .collection('analyses').doc(widget.item.id)
                          .get();
                      driveOverlayUrl = doc.data()?['driveOverlayUrl'];
                      // Simulate/request pro analysis and persist cloudPro
                      await CloudProClient().requestProAnalysis(
                        uid: uid,
                        videoId: widget.item.id,
                        payload: {
                          'score': widget.item.analysisScore ?? 0,
                          'metrics': {},
                          'driveOverlayUrl': driveOverlayUrl,
                        },
                      );
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pro analysis ready (simulated).')),
                    );
                  } catch (_) {}
                },
                icon: const Icon(Icons.bolt),
                label: const Text('Request Pro Analysis'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    if (!context.mounted) return;
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    String? cloudOverlayUrl;
                    if (uid != null) {
                      final doc = await FirebaseFirestore.instance
                          .collection('users').doc(uid)
                          .collection('analyses').doc(widget.item.id)
                          .get();
                      cloudOverlayUrl = doc.data()?['cloudPro']?['overlayUrl'] ?? doc.data()?['driveOverlayUrl'];
                    }
                    final localOverlay = widget.item.path.replaceAll('.mp4', '_overlay.mp4');
                    if (!context.mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProCompareScreen(
                          localOverlayPath: localOverlay,
                          cloudOverlayUrl: cloudOverlayUrl,
                        ),
                      ),
                    );
                  } catch (_) {}
                },
                icon: const Icon(Icons.compare),
                label: const Text('Compare Pro'),
              ),
            ],
          ),


        ],
      ),
      floatingActionButton: _ready ? FloatingActionButton(
        onPressed: () {
          setState(() {
            _player.value.isPlaying ? _player.pause() : _player.play();
          });
        },
        child: Icon(_player.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ) : null,
    );
  }
}


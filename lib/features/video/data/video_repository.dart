import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/local_video.dart';
import 'local_video_dao.dart';
import 'video_db.dart';

class VideoRepository {
  static const _key = 'local_videos_list';

  // Upsert for analysis updates
  Future<void> upsert(LocalVideo video) async {
    if (!kIsWeb) {
      final db = await VideoDb.instance();
      final dao = LocalVideoDao(db);
      await dao.insert(video);
      return;
    }
    // Web fallback: rewrite full list
    final prefs = await SharedPreferences.getInstance();
    final current = await list();
    final next = [video, ...current.where((v) => v.id != video.id)];
    await prefs.setString(_key, jsonEncode(next.map((e) => e.toMap()).toList()));
  }

  // List videos (SQLite on mobile/desktop; SharedPreferences on web)
  Future<List<LocalVideo>> list({String? sport}) async {
    if (!kIsWeb) {
      final db = await VideoDb.instance();
      final dao = LocalVideoDao(db);
      return dao.listAll(sport: sport);
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final vids = list.map((m) => LocalVideo.fromMap(m)).toList();
      if (sport != null) {
        return vids.where((v) => v.sport == sport).toList();
      }
      return vids;
    } catch (_) {
      return [];
    }
  }

  Future<void> add(LocalVideo video) async {
    if (!kIsWeb) {
      final db = await VideoDb.instance();
      final dao = LocalVideoDao(db);
      await dao.insert(video);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final current = await list();
    final next = [video, ...current];
    await prefs.setString(_key, jsonEncode(next.map((e) => e.toMap()).toList()));
  }

  Future<void> delete(String id) async {
    if (!kIsWeb) {
      final db = await VideoDb.instance();
      final dao = LocalVideoDao(db);
      await dao.delete(id);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final current = await list();
    final next = current.where((v) => v.id != id).toList();
    await prefs.setString(_key, jsonEncode(next.map((e) => e.toMap()).toList()));
  }

  Future<void> updateTitle(String id, String title) async {
    if (!kIsWeb) {
      final db = await VideoDb.instance();
      final dao = LocalVideoDao(db);
      await dao.updateTitle(id, title);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final current = await list();
    final next = current
        .map((v) => v.id == id ? LocalVideo(
              id: v.id,
              sport: v.sport,
              drill: v.drill,
              title: title,
              filePath: v.filePath,
              createdAt: v.createdAt,
              durationSecs: v.durationSecs,
              notes: v.notes,
            ) : v)
        .toList();
    await prefs.setString(_key, jsonEncode(next.map((e) => e.toMap()).toList()));
  }

  Future<void> updateNotes(String id, String? notes) async {
    if (!kIsWeb) {
      final db = await VideoDb.instance();
      final dao = LocalVideoDao(db);
      await dao.updateNotes(id, notes);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final current = await list();
    final next = current
        .map((v) => v.id == id ? LocalVideo(
              id: v.id,
              sport: v.sport,
              drill: v.drill,
              title: v.title,
              filePath: v.filePath,
              createdAt: v.createdAt,
              durationSecs: v.durationSecs,
              notes: notes,
            ) : v)
        .toList();
    await prefs.setString(_key, jsonEncode(next.map((e) => e.toMap()).toList()));
  }
}


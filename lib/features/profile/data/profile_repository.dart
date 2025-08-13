import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/user_model.dart';
import '../../../shared/services/network_info.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  final NetworkInfo _networkInfo;

  ProfileRepository(this._firestore, this._prefs, this._networkInfo);

  String _cacheKey(String userId) => 'user_profile_$userId';
  String _pendingKey(String userId) => 'user_profile_pending_$userId';

  Future<UserModel?> getUser(String userId) async {
    // 1) Serve cache if present
    final cached = _prefs.getString(_cacheKey(userId));
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        return _fromMap(userId, data);
      } catch (_) {}
    }

    // 2) If online, fetch from Firestore and cache
    if (await _networkInfo.isConnected) {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final model = UserModel.fromFirestore(doc);
        await _cacheUser(model);
        return model;
      }
      return null;
    }

    // 3) Offline and no cache
    return null;
  }

  Stream<UserModel?> watchUser(String userId) async* {
    // Emit cached immediately
    final cached = _prefs.getString(_cacheKey(userId));
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        yield _fromMap(userId, data);
      } catch (_) {}
    }

    // Then listen to Firestore if online
    if (await _networkInfo.isConnected) {
      final stream = _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .handleError((error) {
        // Swallow Firestore permission errors (e.g., right after sign-out)
        // We rely on auth state to emit null instead of erroring the app
      });

      yield* stream.asyncMap((doc) async {
        if (!doc.exists) return null;
        final model = UserModel.fromFirestore(doc);
        await _cacheUser(model);
        return model;
      });
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    final connected = await _networkInfo.isConnected;

    // Always update cache optimistically (JSON-safe)
    final existing = await getUser(userId);
    if (existing != null) {
      final merged = {
        ...existing.toJson(),
        ...data,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await _prefs.setString(_cacheKey(userId), jsonEncode(merged));
    }

    if (connected) {
      final updateMap = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('users').doc(userId).update(updateMap);
    } else {
      // Save pending update to replay later (JSON-safe)
      final pending = _prefs.getString(_pendingKey(userId));
      Map<String, dynamic> pendingMap = {};
      if (pending != null) {
        try { pendingMap = jsonDecode(pending) as Map<String, dynamic>; } catch (_) {}
      }
      pendingMap.addAll(data);
      pendingMap['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await _prefs.setString(_pendingKey(userId), jsonEncode(pendingMap));
    }
  }

  Future<void> flushPending(String userId) async {
    if (!await _networkInfo.isConnected) return;
    final pending = _prefs.getString(_pendingKey(userId));
    if (pending == null) return;

    try {
      final pendingMap = jsonDecode(pending) as Map<String, dynamic>;
      if (pendingMap.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(pendingMap);
      }
    } catch (_) {}

    await _prefs.remove(_pendingKey(userId));
  }

  Future<void> _cacheUser(UserModel user) async {
    // Store JSON-safe map (no Firestore Timestamp objects)
    await _prefs.setString(_cacheKey(user.id), jsonEncode(user.toJson()));
  }

  UserModel _fromMap(String userId, Map<String, dynamic> map) {
    return UserModel.fromMap(userId, map);
  }
}


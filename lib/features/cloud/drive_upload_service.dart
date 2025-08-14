import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Minimal Google Drive uploader for overlay.mp4 and analysis.json
/// Notes:
/// - Uses user OAuth via google_sign_in (Android/iOS). Web is out of scope here.
/// - Scope is drive.file to allow creating files the app manages.
/// - No Firebase Storage; free Google Drive API only.
class DriveUploadService {
  static const _scopes = <String>[
    drive.DriveApi.driveFileScope,
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  Future<_AuthorizedClient> _getAuthedClient() async {
    if (kIsWeb) {
      throw UnsupportedError('Web Drive upload is not supported in this build');
    }

    final account = await _googleSignIn.signInSilently();
    final GoogleSignInAccount? user = account ?? await _googleSignIn.signIn();
    if (user == null) throw StateError('Google sign-in cancelled');

    final authHeaders = await user.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(client);
    return _AuthorizedClient(client: client, driveApi: driveApi);
  }

  /// Ensures a folder exists by name, returns its fileId. Creates if missing.
  Future<String> ensureFolder(String name) async {
    final authd = await _getAuthedClient();
    final q = "mimeType='application/vnd.google-apps.folder' and name='${name.replaceAll("'", "\\'")}' and trashed=false";
    final res = await authd.driveApi.files.list(q: q, spaces: 'drive');
    if ((res.files ?? []).isNotEmpty) {
      return res.files!.first.id!;
    }
    final folder = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await authd.driveApi.files.create(folder);
    return created.id!;
  }

  /// Uploads a file to Drive under [parentFolderId]. Returns the public/view link.
  /// Note: Sets permission anyoneWithLink=reader for quick sharing.
  Future<String> uploadFile({
    required String parentFolderId,
    required File file,
    required String mimeType,
  }) async {
    final authd = await _getAuthedClient();
    final media = drive.Media(file.openRead(), await file.length());
    final metadata = drive.File()
      ..name = file.uri.pathSegments.last
      ..parents = [parentFolderId];

    final created = await authd.driveApi.files.create(
      metadata,
      uploadMedia: media,
    );

    // Make file shareable via link
    try {
      await authd.driveApi.permissions.create(
        drive.Permission()
          ..type = 'anyone'
          ..role = 'reader',
        created.id!,
      );
    } catch (_) {}

    // Return webViewLink or webContentLink
    final fetched = await authd.driveApi.files.get(
      created.id!,
      $fields: 'id,webViewLink,webContentLink',
    ) as drive.File;
    return (fetched.webViewLink ?? fetched.webContentLink ?? '');
  }
}

class _AuthorizedClient {
  final http.Client client;
  final drive.DriveApi driveApi;
  _AuthorizedClient({required this.client, required this.driveApi});
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../github_list.dart';

/// One online audio file.
class RemoteItem {
  final String title;
  final String url;
  const RemoteItem(this.title, this.url);
}

class GazalSources {
  final String github;
  final String driveFolder;
  final String driveKey;
  const GazalSources(this.github, this.driveFolder, this.driveKey);

  bool get hasGithub => github.trim().isNotEmpty;
  bool get hasDrive => driveFolder.trim().isNotEmpty;
  bool get any => hasGithub || hasDrive;
}

class SyncResult {
  final List<RemoteItem> items;
  final bool ok; // false = could not reach a source, items come from the cache
  final bool configured;
  const SyncResult(this.items, this.ok, this.configured);
}

/// Reads the gazal list from a public GitHub folder and/or a Google Drive
/// folder, so adding a file there updates the app without a new build.
class GazalRemote {
  static const _kGh = 'gz_github';
  static const _kDrive = 'gz_drive';
  static const _kKey = 'gz_drive_key';
  static const _kCache = 'gz_remote_cache';
  static const _audioExt = ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'flac'];

  /// The list always comes from the sources set in config.dart.
  static Future<GazalSources> sources() async =>
      const GazalSources(kGazalGithub, kGazalDriveFolder, kGazalDriveKey);

  static Future<void> saveSources(String github, String drive, String key) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kGh, github.trim());
    await p.setString(_kDrive, drive.trim());
    await p.setString(_kKey, key.trim());
  }

  static Future<List<RemoteItem>> cached() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kCache);
      if (raw == null) return [];
      return [
        for (final e in jsonDecode(raw) as List)
          RemoteItem((e as Map)['t'] as String, e['u'] as String),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveCache(List<RemoteItem> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _kCache, jsonEncode([for (final i in items) {'t': i.title, 'u': i.url}]));
  }

  /// Fetches the latest lists. Falls back to the cached list when offline.
  static Future<SyncResult> sync() async {
    final s = await sources();
    if (!s.any) return const SyncResult([], true, false);

    final items = <RemoteItem>[];
    var ok = true;
    if (s.hasGithub) {
      try {
        items.addAll(await _github(s.github));
      } catch (_) {
        ok = false;
      }
    }
    if (s.hasDrive) {
      try {
        items.addAll(await _drive(s.driveFolder, s.driveKey));
      } catch (_) {
        ok = false;
      }
    }
    if (ok) {
      await _saveCache(items);
      return SyncResult(items, true, true);
    }
    return SyncResult(await cached(), false, true);
  }

  // ---------------- helpers ----------------

  static bool _isAudio(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return false;
    return _audioExt.contains(name.substring(dot + 1).toLowerCase());
  }

  static String _titleOf(String name) {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    return base.replaceAll('_', ' ').trim();
  }

  static Future<dynamic> _getJson(Uri uri, {Map<String, String>? headers}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 15));
      if (headers != null) {
        for (final e in headers.entries) {
          req.headers.set(e.key, e.value);
        }
      }
      final res = await req.close().timeout(const Duration(seconds: 20));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }

  // ---------------- GitHub ----------------

  static Future<List<RemoteItem>> _github(String input) async {
    final files = await listGithubFolder(input, defaultFolder: kGazalDefaultFolder);
    final out = <RemoteItem>[
      for (final f in files)
        if (_isAudio(f.name)) RemoteItem(_titleOf(f.name), f.url),
    ];
    out.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return out;
  }

  // ---------------- Google Drive ----------------

  static String _driveId(String input) {
    final t = input.trim();
    final m = RegExp(r'/folders/([A-Za-z0-9_-]+)').firstMatch(t) ??
        RegExp(r'[?&]id=([A-Za-z0-9_-]+)').firstMatch(t);
    return m != null ? m.group(1)! : t;
  }

  static Future<List<RemoteItem>> _drive(String folder, String key) async {
    if (key.trim().isEmpty) throw const FormatException('key');
    final id = _driveId(folder);
    final uri = Uri.https('www.googleapis.com', '/drive/v3/files', {
      'q': "'$id' in parents and trashed=false",
      'fields': 'files(id,name,mimeType)',
      'pageSize': '1000',
      'orderBy': 'name',
      'key': key.trim(),
    });
    final data = await _getJson(uri);
    final files = (data is Map ? data['files'] : null);
    if (files is! List) throw const FormatException('files');

    final out = <RemoteItem>[];
    for (final e in files) {
      if (e is! Map) continue;
      final name = e['name'];
      final fid = e['id'];
      final mime = (e['mimeType'] ?? '') as String;
      if (name is! String || fid is! String) continue;
      if (mime.startsWith('audio/') || _isAudio(name)) {
        out.add(RemoteItem(
          _titleOf(name),
          'https://www.googleapis.com/drive/v3/files/$fid?alt=media&key=${key.trim()}',
        ));
      }
    }
    return out;
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../i18n.dart';

/// One PDF book from the GitHub `kitab/` folder.
class Book {
  /// File name, e.g. `Riyadus_Salehin.pdf` (also the key for status / history).
  final String file;
  final String url;
  final int size; // bytes, 0 = unknown
  const Book(this.file, this.url, this.size);

  /// Shown name: file name without `.pdf`, `_` -> space.
  String get title {
    final dot = file.lastIndexOf('.');
    final base = dot > 0 ? file.substring(0, dot) : file;
    return base.replaceAll('_', ' ').trim();
  }

  String get sizeText {
    if (size <= 0) return '';
    final mb = size / (1024 * 1024);
    return mb >= 1 ? '${mb.toStringAsFixed(1)} MB' : '${(size / 1024).round()} KB';
  }
}

class KitabSync {
  final List<Book> books;
  final bool ok; // false = could not reach GitHub, books come from the cache
  const KitabSync(this.books, this.ok);
}

/// Reads the book list from the public GitHub folder (and caches it).
class KitabRemote {
  static const _kCache = 'kitab_remote_cache_v1';

  static Future<List<Book>> cached() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kCache);
      if (raw == null) return [];
      return [
        for (final e in jsonDecode(raw) as List)
          Book((e as Map)['f'] as String, e['u'] as String, (e['s'] as int?) ?? 0),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<Book> l) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _kCache, jsonEncode([for (final b in l) {'f': b.file, 'u': b.url, 's': b.size}]));
  }

  static Future<KitabSync> sync() async {
    try {
      final list = await _github(kKitabGithub);
      await _save(list);
      return KitabSync(list, true);
    } catch (_) {
      return KitabSync(await cached(), false);
    }
  }

  static Future<List<Book>> _github(String input) async {
    var t = input.trim().replaceAll(RegExp(r'^https?://(www\.)?github\.com/'), '');
    t = t.replaceAll(RegExp(r'^/+|/+$'), '');
    final parts = t.split('/').where((e) => e.isNotEmpty).toList();
    if (parts.length < 2) throw const FormatException('repo');
    final owner = parts[0];
    final repo = parts[1].replaceAll(RegExp(r'\.git$'), '');
    String? ref;
    var rest = parts.skip(2).toList();
    if (rest.length >= 2 && rest[0] == 'tree') {
      ref = rest[1];
      rest = rest.skip(2).toList();
    }
    final folder = rest.isEmpty ? 'kitab' : rest.join('/');

    final uri = Uri.https('api.github.com', '/repos/$owner/$repo/contents/$folder',
        ref == null ? null : {'ref': ref});
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 15));
      req.headers.set('Accept', 'application/vnd.github+json');
      req.headers.set('User-Agent', 'noor-app');
      final res = await req.close().timeout(const Duration(seconds: 20));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final data = jsonDecode(body);
      if (data is! List) throw const FormatException('folder');
      final out = <Book>[];
      for (final e in data) {
        if (e is! Map) continue;
        final name = e['name'];
        final url = e['download_url'];
        if (e['type'] == 'file' &&
            name is String &&
            url is String &&
            name.toLowerCase().endsWith('.pdf')) {
          out.add(Book(name, url, (e['size'] as int?) ?? 0));
        }
      }
      out.sort((a, b) => a.title.compareTo(b.title));
      return out;
    } finally {
      client.close(force: true);
    }
  }
}

class HistoryEntry {
  final String file;
  final String title;
  final String url;
  final int size;
  final DateTime at;
  final int opens;
  const HistoryEntry(this.file, this.title, this.url, this.size, this.at, this.opens);

  Book get book => Book(file, url, size);
}

/// Which books were opened, newest first (shown on the profile page).
class KitabHistory {
  static const _key = 'kitab_history_v2';

  static Future<List<HistoryEntry>> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final out = <HistoryEntry>[];
      for (final e in jsonDecode(raw) as List) {
        final m = e as Map;
        out.add(HistoryEntry(
            m['f'] as String,
            m['ti'] as String,
            m['u'] as String,
            (m['s'] as int?) ?? 0,
            DateTime.fromMillisecondsSinceEpoch(m['t'] as int),
            (m['n'] as int?) ?? 1));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<void> record(Book b) async {
    final p = await SharedPreferences.getInstance();
    final list = await load();
    var opens = 1;
    final old = list.indexWhere((e) => e.file == b.file);
    if (old >= 0) {
      opens = list[old].opens + 1;
      list.removeAt(old);
    }
    list.insert(0, HistoryEntry(b.file, b.title, b.url, b.size, DateTime.now(), opens));
    if (list.length > 30) list.removeRange(30, list.length);
    await p.setString(
        _key,
        jsonEncode([
          for (final e in list)
            {
              'f': e.file,
              'ti': e.title,
              'u': e.url,
              's': e.size,
              't': e.at.millisecondsSinceEpoch,
              'n': e.opens
            }
        ]));
    // Opening a book that was only "in the list" / "want to read" = reading it now.
    final s = p.getInt(statusKey(b.file)) ?? 0;
    if (s == 0 || s == 1) await p.setInt(statusKey(b.file), 2);
  }

  /// SharedPreferences key of a book's reading status (0..3).
  static String statusKey(String file) => 'kitab_s_$file';

  /// How many books are marked "finished" (status 3).
  static Future<int> finishedCount() async {
    final p = await SharedPreferences.getInstance();
    var n = 0;
    for (final k in p.getKeys()) {
      if (k.startsWith('kitab_s_') && p.getInt(k) == 3) n++;
    }
    return n;
  }
}

/// 11/11/2026  09:40 (digits follow the app language).
String formatStamp(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return localizeDigits('${two(d.day)}/${two(d.month)}/${d.year}  ${two(d.hour)}:${two(d.minute)}');
}

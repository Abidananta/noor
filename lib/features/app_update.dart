import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

/// Latest release found on GitHub.
class UpdateInfo {
  final String version;
  final String url; // APK download (or the release page)
  final int size; // APK size in bytes (0 if unknown)
  const UpdateInfo(this.version, this.url, [this.size = 0]);

  bool get isApk => url.toLowerCase().endsWith('.apk');
}

/// Repo from config.dart or the build (GitHub Actions passes its own repo),
/// else one typed in the app earlier.
Future<String> savedUpdateRepo() async {
  if (kUpdateGithub.trim().isNotEmpty) return kUpdateGithub.trim();
  if (kUpdateRepoBuild.trim().isNotEmpty) return kUpdateRepoBuild.trim();
  try {
    final p = await SharedPreferences.getInstance();
    final r = p.getString('update_repo') ?? '';
    if (r.trim().isNotEmpty) return r.trim();
  } catch (_) {}
  return '';
}

/// Accepts 'owner/repo' or a github.com link; returns null if it is not valid.
String? normalizeRepo(String input) {
  var s = input.trim();
  s = s.replaceFirst(RegExp(r'^https?://(www\.)?github\.com/'), '');
  s = s.replaceFirst(RegExp(r'\.git$'), '');
  final parts = s.split('/').where((e) => e.isNotEmpty).toList();
  if (parts.length < 2) return null;
  return '${parts[0]}/${parts[1]}';
}

Future<void> saveUpdateRepo(String repo) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('update_repo', repo);
}

/// Reads the latest GitHub release. Throws if it cannot be reached.
Future<UpdateInfo> fetchLatestRelease(String repo) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  try {
    final req = await client.getUrl(Uri.parse('https://api.github.com/repos/$repo/releases/latest'));
    req.headers.set('Accept', 'application/vnd.github+json');
    req.headers.set('User-Agent', 'noor-app');
    final res = await req.close().timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw HttpException('HTTP ${res.statusCode}');
    }
    final body = await res.transform(utf8.decoder).join();
    final j = jsonDecode(body) as Map<String, dynamic>;
    final tag = ((j['tag_name'] as String?) ?? '').trim().replaceFirst(RegExp(r'^[vV]'), '');
    String? url;
    int size = 0;
    for (final a in (j['assets'] as List? ?? const [])) {
      final m = a as Map<String, dynamic>;
      if (((m['name'] as String?) ?? '').toLowerCase().endsWith('.apk')) {
        url = m['browser_download_url'] as String?;
        size = (m['size'] as num?)?.toInt() ?? 0;
        break;
      }
    }
    url ??= j['html_url'] as String?;
    if (tag.isEmpty || url == null) throw const FormatException('no release data');
    return UpdateInfo(tag, url, size);
  } finally {
    client.close();
  }
}

List<int> _parts(String v) => v
    .split('+')
    .first
    .split('.')
    .map((e) => int.tryParse(RegExp(r'\d+').firstMatch(e)?.group(0) ?? '') ?? 0)
    .toList();

/// true if [latest] is a higher version than [current] (1.0.10 > 1.0.9).
bool isNewerVersion(String latest, String current) {
  final a = _parts(latest);
  final b = _parts(current);
  final n = a.length > b.length ? a.length : b.length;
  for (int i = 0; i < n; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

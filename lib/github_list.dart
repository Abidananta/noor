import 'dart:convert';
import 'dart:io';

/// One file found in a public GitHub folder.
class GhFile {
  final String name;
  final String url; // direct download link
  final int size; // bytes, 0 = unknown
  const GhFile(this.name, this.url, this.size);
}

class _Repo {
  final String owner;
  final String repo;
  final String ref;
  final String folder;
  const _Repo(this.owner, this.repo, this.ref, this.folder);
}

_Repo _parse(String input, String defaultFolder) {
  var t = input.trim().replaceAll(RegExp(r'^https?://(www\.)?github\.com/'), '');
  t = t.replaceAll(RegExp(r'^/+|/+$'), '');
  final parts = t.split('/').where((e) => e.isNotEmpty).toList();
  if (parts.length < 2) throw const FormatException('repo');
  var ref = 'main';
  var rest = parts.skip(2).toList();
  if (rest.length >= 2 && rest[0] == 'tree') {
    ref = rest[1];
    rest = rest.skip(2).toList();
  }
  return _Repo(parts[0], parts[1].replaceAll(RegExp(r'\.git$'), ''), ref,
      rest.isEmpty ? defaultFolder : rest.join('/'));
}

Future<String> _get(Uri uri, Map<String, String> headers) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final req = await client.getUrl(uri).timeout(const Duration(seconds: 10));
    headers.forEach(req.headers.set);
    final res = await req.close().timeout(const Duration(seconds: 12));
    final body = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
    return body;
  } finally {
    client.close(force: true);
  }
}

String _raw(_Repo r, String path) => Uri(
      scheme: 'https',
      host: 'raw.githubusercontent.com',
      pathSegments: [r.owner, r.repo, r.ref, ...path.split('/')],
    ).toString();

String _cdn(_Repo r, String path) => Uri(
      scheme: 'https',
      host: 'cdn.jsdelivr.net',
      pathSegments: ['gh', '${r.owner}', '${r.repo}@${r.ref}', ...path.split('/')],
    ).toString();

/// Same file through jsDelivr, used when raw.githubusercontent.com does not
/// open on the phone's network. Returns null if [url] is not a raw link.
String? alternateUrl(String url) {
  final u = Uri.tryParse(url);
  if (u == null || u.host != 'raw.githubusercontent.com' || u.pathSegments.length < 4) {
    return null;
  }
  final s = u.pathSegments;
  return Uri(
    scheme: 'https',
    host: 'cdn.jsdelivr.net',
    pathSegments: ['gh', s[0], '${s[1]}@${s[2]}', ...s.skip(3)],
  ).toString();
}

/// Lists the files of a public GitHub folder. Tries three ways, because on
/// some networks api.github.com is blocked or its free request limit
/// (shared by everyone on the same mobile IP) is used up:
///  1. GitHub API  2. the github.com folder page (JSON)  3. jsDelivr.
Future<List<GhFile>> listGithubFolder(String input, {required String defaultFolder}) async {
  final r = _parse(input, defaultFolder);
  Object? lastError;

  // 1. GitHub API
  try {
    final body = await _get(
      Uri.https('api.github.com', '/repos/${r.owner}/${r.repo}/contents/${r.folder}',
          {'ref': r.ref}),
      {'Accept': 'application/vnd.github+json', 'User-Agent': 'noor-app'},
    );
    final data = jsonDecode(body);
    if (data is List) {
      final out = <GhFile>[];
      for (final e in data) {
        if (e is! Map) continue;
        final name = e['name'];
        final url = e['download_url'];
        if (e['type'] == 'file' && name is String && url is String) {
          out.add(GhFile(name, url, (e['size'] as num?)?.toInt() ?? 0));
        }
      }
      return out;
    }
  } catch (e) {
    lastError = e;
  }

  // 2. github.com folder page as JSON
  try {
    final body = await _get(
      Uri(
        scheme: 'https',
        host: 'github.com',
        pathSegments: [r.owner, r.repo, 'tree', r.ref, ...r.folder.split('/')],
      ),
      {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13) noor-app',
      },
    );
    final items = (jsonDecode(body) as Map)['payload']['tree']['items'];
    if (items is List) {
      final out = <GhFile>[];
      for (final e in items) {
        if (e is! Map) continue;
        final name = e['name'];
        final path = e['path'];
        if (e['contentType'] == 'file' && name is String && path is String) {
          out.add(GhFile(name, _raw(r, path), 0));
        }
      }
      return out;
    }
  } catch (e) {
    lastError = e;
  }

  // 3. jsDelivr
  try {
    final body = await _get(
      Uri.https('data.jsdelivr.com', '/v1/packages/gh/${r.owner}/${r.repo}@${r.ref}',
          {'structure': 'flat'}),
      {'User-Agent': 'noor-app'},
    );
    final files = (jsonDecode(body) as Map)['files'];
    if (files is List) {
      final prefix = '/${r.folder}/';
      final out = <GhFile>[];
      for (final e in files) {
        if (e is! Map) continue;
        final n = e['name'];
        if (n is! String || !n.startsWith(prefix)) continue;
        final rel = n.substring(prefix.length);
        if (rel.isEmpty || rel.contains('/')) continue;
        out.add(GhFile(rel, _cdn(r, n.substring(1)), (e['size'] as num?)?.toInt() ?? 0));
      }
      return out;
    }
  } catch (e) {
    lastError = e;
  }

  throw lastError ?? const HttpException('GitHub unreachable');
}

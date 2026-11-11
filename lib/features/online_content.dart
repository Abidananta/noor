import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/glass.dart';
import 'common.dart';

/// One random hadith / dua (fetched from the internet, or from the built-in
/// list when offline).
class RItem {
  final String id; // used to avoid showing the same one twice in a row
  final String title; // may be empty (hadith)
  final String arabic; // may be empty
  final String text; // Bangla text / meaning
  final String source;
  final String extra; // e.g. hadith grade, may be empty
  const RItem({
    required this.id,
    this.title = '',
    this.arabic = '',
    required this.text,
    this.source = '',
    this.extra = '',
  });

  Map<String, dynamic> toJson() => {
        'i': id,
        't': title,
        'a': arabic,
        'x': text,
        's': source,
        'e': extra,
      };

  static RItem? fromJson(dynamic j) {
    try {
      final m = j as Map;
      return RItem(
        id: m['i'] as String,
        title: (m['t'] as String?) ?? '',
        arabic: (m['a'] as String?) ?? '',
        text: m['x'] as String,
        source: (m['s'] as String?) ?? '',
        extra: (m['e'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Rough time (seconds) a person needs to read this, used for auto-change.
  int get readSeconds {
    final chars = text.length + title.length + (arabic.length * 0.8).round();
    return (8 + chars / 12).round().clamp(10, 90).toInt();
  }
}

/// Small JSON GET with timeouts. Throws on any failure.
Future<dynamic> fetchJson(String url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
  try {
    final req = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 8));
    req.headers.set('Accept', 'application/json');
    req.headers.set('User-Agent', 'NoorApp/1.0');
    final res = await req.close().timeout(const Duration(seconds: 10));
    final body = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
    return jsonDecode(body);
  } finally {
    client.close(force: true);
  }
}

/// Asks several mirrors of the same file at once and returns the first answer.
/// (Some networks block one host but not another, e.g. cdn.jsdelivr.net.)
/// If every mirror fails and any of them said 404, the 404 is thrown, because
/// that means "the server is fine, this file just does not exist".
Future<dynamic> fetchJsonAny(List<String> urls) {
  final c = Completer<dynamic>();
  var failed = 0;
  Object? notFound;
  Object? last;
  for (final u in urls) {
    fetchJson(u).then((v) {
      if (!c.isCompleted) c.complete(v);
    }, onError: (Object e) {
      failed++;
      last = e;
      if (e is HttpException && e.message.contains('404')) notFound = e;
      if (failed == urls.length && !c.isCompleted) {
        c.completeError(notFound ?? last ?? 'failed');
      }
    });
  }
  return c.future;
}

/// Picks a random item, preferring the internet. Remembers what it fetched
/// (so something fresh-looking still shows when the phone is offline) and
/// falls back to the built-in list as the last resort.
class RandomSource {
  final String kind; // 'hadith' | 'dua'
  final Future<RItem?> Function(Random rnd) fetchOne;
  final List<RItem> fallback;
  RandomSource({required this.kind, required this.fetchOne, required this.fallback});

  final Random _rnd = Random();
  final List<String> _recent = [];
  bool offline = false;
  String lastError = '';

  String get _cacheKey => 'rand_cache_v1_$kind';

  Future<List<RItem>> _loadCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return [];
      final out = <RItem>[];
      for (final e in jsonDecode(raw) as List) {
        final it = RItem.fromJson(e);
        if (it != null) out.add(it);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<void> _remember(RItem it) async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = await _loadCache();
      list.removeWhere((e) => e.id == it.id);
      list.add(it);
      while (list.length > 60) {
        list.removeAt(0);
      }
      await p.setString(_cacheKey, jsonEncode([for (final e in list) e.toJson()]));
    } catch (_) {}
  }

  void _seen(String id) {
    _recent.add(id);
    if (_recent.length > 25) _recent.removeAt(0);
  }

  Future<RItem?> next() async {
    // 1) the internet (a few tries: a number can be missing / too long)
    for (var i = 0; i < 8; i++) {
      try {
        final it = await fetchOne(_rnd);
        if (it == null || _recent.contains(it.id)) continue;
        offline = false;
        lastError = '';
        _seen(it.id);
        _remember(it);
        return it;
      } catch (e) {
        // network trouble: a second failure in a row means we are offline
        lastError = e.toString();
        if (i >= 1) break;
      }
    }
    // 2) offline: earlier fetched items + built-in list
    offline = true;
    final pool = <RItem>[...await _loadCache(), ...fallback];
    if (pool.isEmpty) return null;
    final fresh = pool.where((e) => !_recent.contains(e.id)).toList();
    final from = fresh.isEmpty ? pool : fresh;
    final it = from[_rnd.nextInt(from.length)];
    _seen(it.id);
    return it;
  }
}

// ---------------------------------------------------------------- Hadith

class _HEd {
  final String id;
  final String name;
  final int max;
  const _HEd(this.id, this.name, this.max);
}

// Bengali editions of fawazahmed0/hadith-api (open source, served by jsDelivr).
// `max` is a safe upper bound of the hadith number; a missing number just
// makes the source try another one.
const _hEditions = <_HEd>[
  _HEd('ben-bukhari', 'সহীহ বুখারী', 7000),
  _HEd('ben-muslim', 'সহীহ মুসলিম', 3000),
  _HEd('ben-abudawud', 'সুনান আবূ দাঊদ', 5000),
  _HEd('ben-tirmidhi', 'জামে তিরমিযী', 3900),
  _HEd('ben-nasai', 'সুনান নাসাঈ', 5700),
  _HEd('ben-ibnmajah', 'সুনান ইবনু মাজাহ', 4300),
];

const _hadithBases = <String>[
  'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions',
  'https://fastly.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions',
  'https://gcore.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions',
  'https://raw.githubusercontent.com/fawazahmed0/hadith-api/1/editions',
];

Future<RItem?> fetchRandomHadith(Random rnd) async {
  final ed = _hEditions[rnd.nextInt(_hEditions.length)];
  final n = 1 + rnd.nextInt(ed.max);
  dynamic j;
  try {
    j = await fetchJsonAny([for (final b in _hadithBases) '$b/${ed.id}/$n.json']);
  } on HttpException catch (e) {
    // 404 = this number does not exist in the edition -> caller tries another one
    if (e.message.contains('404')) return null;
    rethrow;
  }
  if (j is! Map) return null;
  final m = j;
  final text = ((m['text'] as String?) ?? '').trim();
  // Skip empty or very long ones (they do not fit a quick "read and move on" card).
  if (text.length < 25 || text.length > 900) return null;

  var grade = '';
  final g = m['grades'];
  if (g is List && g.isNotEmpty && g.first is Map) {
    final gm = g.first as Map;
    final gr = (gm['grade'] ?? '').toString().trim();
    final by = (gm['name'] ?? '').toString().trim();
    if (gr.isNotEmpty) grade = by.isEmpty ? 'মান: $gr' : 'মান: $gr ($by)';
  }
  return RItem(
    id: 'h:${ed.id}:$n',
    text: text,
    source: '${ed.name} · হাদীস নং ${localizeDigitsSafe('$n')}',
    extra: grade,
  );
}

// ---------------------------------------------------------------- Dua

class _DRef {
  final int s;
  final int a;
  final String sura;
  final String title;
  const _DRef(this.s, this.a, this.sura, this.title);
}

// Duas that appear in the Quran (Arabic + Bangla meaning are fetched live).
const _duaRefs = <_DRef>[
  _DRef(2, 127, 'বাকারা', "কবুলের দু'আ (ইবরাহীম ও ইসমাঈল আ.)"),
  _DRef(2, 201, 'বাকারা', 'দুনিয়া ও আখিরাতের কল্যাণ'),
  _DRef(2, 250, 'বাকারা', 'ধৈর্য ও বিজয়ের দু\'আ'),
  _DRef(2, 286, 'বাকারা', 'ভুল ও কষ্টের বোঝা থেকে মুক্তি'),
  _DRef(3, 8, 'আলে ইমরান', 'হিদায়াতের ওপর অটল থাকা'),
  _DRef(3, 16, 'আলে ইমরান', 'গুনাহ মাফ ও জাহান্নাম থেকে মুক্তি'),
  _DRef(3, 38, 'আলে ইমরান', "নেক সন্তানের দু'আ (যাকারিয়া আ.)"),
  _DRef(3, 147, 'আলে ইমরান', 'ক্ষমা ও দৃঢ়পদ থাকার দু\'আ'),
  _DRef(3, 193, 'আলে ইমরান', 'নেককারদের সাথে মৃত্যুর দু\'আ'),
  _DRef(7, 23, 'আ\'রাফ', "ক্ষমা প্রার্থনা (আদম ও হাওয়া আ.)"),
  _DRef(11, 47, 'হূদ', 'অজানা বিষয় চাওয়া থেকে আশ্রয়'),
  _DRef(12, 101, 'ইউসুফ', 'ইসলামের ওপর মৃত্যু ও নেককারদের সঙ্গ'),
  _DRef(14, 40, 'ইবরাহীম', 'নামায কায়েমের দু\'আ'),
  _DRef(14, 41, 'ইবরাহীম', 'নিজের, পিতামাতার ও মুমিনদের জন্য ক্ষমা'),
  _DRef(17, 80, 'বনী ইসরাঈল', 'ভালোভাবে প্রবেশ ও বের হওয়ার দু\'আ'),
  _DRef(18, 10, 'কাহফ', "রহমত ও সঠিক পথের দু'আ (গুহাবাসী)"),
  _DRef(20, 25, 'তা-হা', "মনের প্রশান্তি ও কাজ সহজ হওয়ার দু'আ (মূসা আ.)"),
  _DRef(20, 114, 'তা-হা', 'ইলম বৃদ্ধির দু\'আ'),
  _DRef(21, 83, 'আম্বিয়া', "অসুস্থতা ও কষ্টে দু'আ (আইয়ূব আ.)"),
  _DRef(21, 87, 'আম্বিয়া', "বিপদ থেকে মুক্তি (ইউনুস আ.)"),
  _DRef(23, 97, 'মুমিনূন', 'শয়তানের কুমন্ত্রণা থেকে আশ্রয়'),
  _DRef(23, 118, 'মুমিনূন', 'ক্ষমা ও রহমতের দু\'আ'),
  _DRef(25, 74, 'ফুরকান', 'পরিবার ও সন্তানের জন্য দু\'আ'),
  _DRef(26, 83, 'শুআরা', "হিকমত ও নেককারদের সঙ্গ (ইবরাহীম আ.)"),
  _DRef(27, 19, 'নামল', 'নিয়ামতের শুকরিয়ার দু\'আ'),
  _DRef(28, 16, 'কাসাস', 'ভুলের জন্য ক্ষমা প্রার্থনা (মূসা আ.)'),
  _DRef(28, 24, 'কাসাস', "প্রয়োজনে আল্লাহর কাছে চাওয়া (মূসা আ.)"),
  _DRef(46, 15, 'আহকাফ', 'কৃতজ্ঞতা ও সন্তানের জন্য দু\'আ'),
  _DRef(59, 10, 'হাশর', 'মুমিন ভাইদের জন্য দু\'আ'),
  _DRef(66, 8, 'তাহরীম', 'নূর পূর্ণ করার দু\'আ'),
  _DRef(71, 28, 'নূহ', 'নিজের, পিতামাতার ও মুমিনদের জন্য দু\'আ (নূহ আ.)'),
];

Future<RItem?> fetchRandomDua(Random rnd) async {
  final r = _duaRefs[rnd.nextInt(_duaRefs.length)];
  String ar = '';
  String bn = '';
  try {
    final j = await fetchJson(
        'https://api.alquran.cloud/v1/ayah/${r.s}:${r.a}/editions/quran-uthmani,bn.bengali');
    for (final e in (j['data'] as List)) {
      final m = e as Map;
      final ident = (m['edition'] as Map)['identifier'];
      if (ident == 'quran-uthmani') ar = (m['text'] as String).trim();
      if (ident == 'bn.bengali') bn = (m['text'] as String).trim();
    }
  } catch (_) {
    // second host
    final a = await fetchJson(
        'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ara-quranuthmanihaf/${r.s}/${r.a}.json');
    final b = await fetchJson(
        'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ben-muhiuddinkhan/${r.s}/${r.a}.json');
    ar = ((a as Map)['text'] as String).trim();
    bn = ((b as Map)['text'] as String).trim();
  }
  if (ar.isEmpty || bn.isEmpty) return null;
  return RItem(
    id: 'd:${r.s}:${r.a}',
    title: r.title,
    arabic: ar,
    text: bn,
    source: 'সূরা ${r.sura} ${localizeDigitsSafe('${r.s}:${r.a}')}',
  );
}

String localizeDigitsSafe(String s) {
  try {
    return bnDigits(s);
  } catch (_) {
    return s;
  }
}

// ---------------------------------------------------------------- Widget

/// Card that shows one random item. When the reader taps "পড়া শেষ" (or, with
/// auto mode on, once the estimated reading time is over) the next random item
/// is loaded from the internet automatically. The next item is fetched in the
/// background while the current one is being read, so the change is instant.
class RandomReader extends StatefulWidget {
  final RandomSource source;
  final String heading;
  final bool arabicFirst;
  const RandomReader({
    super.key,
    required this.source,
    required this.heading,
    this.arabicFirst = false,
  });

  @override
  State<RandomReader> createState() => _RandomReaderState();
}

class _RandomReaderState extends State<RandomReader> {
  static const _kAuto = 'rand_auto_v1';
  RItem? _cur;
  Future<RItem?>? _pre;
  bool _loading = true;
  bool _auto = true;
  int _elapsedMs = 0;
  int _readCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _advance(first: true);
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getBool(_kAuto);
      if (v != null && mounted) setState(() => _auto = v);
    } catch (_) {}
  }

  Future<void> _setAuto(bool v) async {
    setState(() {
      _auto = v;
      _elapsedMs = 0;
    });
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kAuto, v);
    } catch (_) {}
  }

  void _tick() {
    final c = _cur;
    if (!mounted || !_auto || _loading || c == null) return;
    // Do not swap the text while the screen is covered by another page.
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _elapsedMs += 250;
    if (_elapsedMs >= c.readSeconds * 1000) {
      _advance();
    } else {
      setState(() {});
    }
  }

  Future<void> _advance({bool first = false}) async {
    if (_loading && !first) return;
    if (!first) setState(() => _loading = true);
    RItem? n;
    try {
      n = await (_pre ?? widget.source.next());
    } catch (_) {
      n = null;
    }
    _pre = null;
    if (!mounted) return;
    setState(() {
      if (n != null) _cur = n;
      _elapsedMs = 0;
      _loading = false;
    });
    // fetch the next one while this one is being read
    _pre = widget.source.next().catchError((_) => null);
  }

  Future<void> _done() async {
    if (_cur != null) _readCount++;
    await _advance();
  }

  void _copy(RItem it) {
    final b = StringBuffer();
    if (it.title.isNotEmpty) b.writeln(it.title);
    if (it.arabic.isNotEmpty) b.writeln(it.arabic);
    b.writeln(it.text);
    if (it.source.isNotEmpty) b.write('— ${it.source}');
    Clipboard.setData(ClipboardData(text: b.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কপি হয়েছে'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final it = _cur;
    final offline = widget.source.offline;
    return GlassCard(
      blur: 0,
      opacity: 0.16,
      radius: 22,
      tint: kGold,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                  size: 18, color: offline ? wh(.6) : kMint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    offline ? '${widget.heading} · অফলাইন' : widget.heading,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: kGold)),
              ),
              if (_readCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('পড়া হয়েছে: ${localizeDigitsSafe('$_readCount')}',
                      style: TextStyle(fontSize: 12, color: wh(.65))),
                ),
            ],
          ),
          if (offline && widget.source.lastError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('ইন্টারনেট থেকে আনা যায়নি (${widget.source.lastError})',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: wh(.5))),
            ),
          const SizedBox(height: 10),
          if (it == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: KeyedSubtree(
                key: ValueKey(it.id),
                child: _content(it),
              ),
            ),
          const SizedBox(height: 8),
          if (it != null && _auto)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: LinearProgressIndicator(
                value: (_elapsedMs / (it.readSeconds * 1000)).clamp(0.0, 1.0).toDouble(),
                minHeight: 3,
                color: kGold,
                backgroundColor: wh(.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _done,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text('পড়া শেষ — পরেরটি'),
                ),
              ),
              IconButton(
                tooltip: _auto ? 'অটো বদল চালু (বন্ধ করুন)' : 'অটো বদল বন্ধ (চালু করুন)',
                icon: Icon(_auto ? Icons.autorenew_rounded : Icons.pause_circle_outline_rounded,
                    color: _auto ? kGold : wh(.7)),
                onPressed: () => _setAuto(!_auto),
              ),
              IconButton(
                tooltip: 'কপি',
                icon: Icon(Icons.copy_rounded, size: 20, color: wh(.8)),
                onPressed: it == null ? null : () => _copy(it),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _content(RItem it) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (it.title.isNotEmpty) ...[
            Text(it.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
          ],
          if (it.arabic.isNotEmpty) ...[
            Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                width: double.infinity,
                child: Text(it.arabic,
                    style: const TextStyle(fontSize: 24, height: 1.9, color: kGold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(it.text, style: TextStyle(fontSize: 16, height: 1.55, color: wh(.92))),
          const SizedBox(height: 8),
          if (it.source.isNotEmpty)
            Text(it.source, style: const TextStyle(fontSize: 13, color: kGold)),
          if (it.extra.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(it.extra, style: TextStyle(fontSize: 12, color: wh(.6))),
            ),
        ],
      ),
    );
  }
}

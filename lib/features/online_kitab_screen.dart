import 'package:flutter/material.dart';
import '../ui/glass.dart';
import 'common.dart';
import 'kitab_data.dart';
import 'kitab_reader.dart';
import 'online_content.dart' show fetchJson;


/// Finds free Islamic PDF books on the internet (archive.org) and opens them
/// in the normal kitab reader. Nothing has to be uploaded to GitHub.
class OnlineKitabScreen extends StatefulWidget {
  final String title;
  const OnlineKitabScreen({super.key, this.title = 'অনলাইন কিতাব'});

  @override
  State<OnlineKitabScreen> createState() => _OnlineKitabScreenState();
}

class _Hit {
  final String id;
  final String title;
  final String author;
  final int downloads;
  const _Hit(this.id, this.title, this.author, this.downloads);
}

class _Lang {
  final String label;
  final String q;
  const _Lang(this.label, this.q);
}

const _langs = <_Lang>[
  _Lang('বাংলা', 'language:(Bengali OR ben OR bn OR Bangla)'),
  _Lang('العربية', 'language:(Arabic OR ara OR ar)'),
  _Lang('English', 'language:(English OR eng OR en)'),
  _Lang('اردو', 'language:(Urdu OR urd OR ur)'),
];

const _topic = '(subject:islam OR subject:islamic OR subject:quran OR subject:hadith '
    'OR subject:tafsir OR subject:fiqh OR subject:sirah)';

const _pageSize = 25;

class _OnlineKitabScreenState extends State<OnlineKitabScreen> {
  final TextEditingController _ctl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Hit> _hits = [];
  int _lang = 0;
  int _page = 1;
  bool _loading = false;
  bool _more = false;
  bool _failed = false;
  String _query = '';
  String? _opening; // id being resolved
  List<HistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    KitabHistory.load().then((l) {
      if (mounted) setState(() => _history = l);
    });
    _search();
  }

  @override
  void dispose() {
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _buildQuery(bool loose) {
    final lang = _langs[_lang].q;
    final t = _query.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ').trim();
    if (!loose) {
      final b = StringBuffer('mediatype:texts AND $lang AND $_topic');
      if (t.isNotEmpty) b.write(' AND (title:($t) OR creator:($t) OR subject:($t))');
      return b.toString();
    }
    // Wider search: plain keywords in any field.
    final b = StringBuffer('mediatype:texts AND $lang');
    if (t.isNotEmpty) {
      b.write(' AND ($t)');
    } else {
      b.write(' AND (islam OR islamic OR quran OR hadith OR tafsir OR namaz OR salat '
          'OR ইসলাম OR কুরআন OR হাদীস OR নামাজ)');
    }
    return b.toString();
  }

  Future<List<_Hit>> _fetch(bool loose) async {
    final uri = Uri.https('archive.org', '/advancedsearch.php', {
      'q': _buildQuery(loose),
      'fl[]': ['identifier', 'title', 'creator', 'downloads'],
      'sort[]': 'downloads desc',
      'rows': '$_pageSize',
      'page': '$_page',
      'output': 'json',
    });
    final j = await fetchJson(uri.toString());
    final docs = ((j as Map)['response'] as Map)['docs'] as List;
    final found = <_Hit>[];
    for (final d in docs) {
      final m = d as Map;
      final id = (m['identifier'] ?? '').toString();
      if (id.isEmpty) continue;
      found.add(_Hit(id, _first(m['title']), _first(m['creator']),
          int.tryParse((m['downloads'] ?? '0').toString()) ?? 0));
    }
    return found;
  }

  bool _loose = false;

  Future<void> _search({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
      if (!more) {
        _page = 1;
        _hits.clear();
        _loose = false;
      } else {
        _page++;
      }
    });
    try {
      var found = await _fetch(_loose);
      if (found.isEmpty && !more && !_loose) {
        _loose = true; // strict subject search found nothing: widen it
        found = await _fetch(true);
      }
      if (!mounted) return;
      setState(() {
        _hits.addAll(found);
        _more = found.length >= _pageSize;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (more && _page > 1) _page--;
        _failed = true;
        _loading = false;
      });
    }
  }

  static String _first(dynamic v) {
    if (v is List && v.isNotEmpty) return v.first.toString();
    return (v ?? '').toString();
  }

  Future<void> _open(_Hit h) async {
    if (_opening != null) return;
    setState(() => _opening = h.id);
    Book? book;
    try {
      final j = await fetchJson('https://archive.org/metadata/${h.id}');
      final files = ((j as Map)['files'] as List?) ?? const [];
      Map? best;
      var bestRank = 99;
      for (final f in files) {
        final m = f as Map;
        final name = (m['name'] ?? '').toString();
        if (!name.toLowerCase().endsWith('.pdf')) continue;
        final fmt = (m['format'] ?? '').toString();
        final rank = fmt == 'Text PDF'
            ? 0
            : fmt == 'Image Container PDF'
                ? 1
                : fmt == 'Additional Text PDF'
                    ? 2
                    : 3;
        if (rank < bestRank) {
          best = m;
          bestRank = rank;
        }
      }
      if (best != null) {
        final name = best['name'].toString();
        final size = int.tryParse((best['size'] ?? '0').toString()) ?? 0;
        final url = Uri(
                scheme: 'https',
                host: 'archive.org',
                pathSegments: ['download', h.id, ...name.split('/')])
            .toString();
        final safe = h.id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        book = Book('ia_$safe.pdf', url, size, label: h.title.isEmpty ? h.id : h.title);
      }
    } catch (_) {
      book = null;
    }
    if (!mounted) return;
    setState(() => _opening = null);
    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('এই বইয়ের PDF পাওয়া যায়নি বা ইন্টারনেট সমস্যা। অন্য বই চেষ্টা করুন।')));
      return;
    }
    final bk = book;
    if (bk.size > 60 * 1024 * 1024) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('বড় ফাইল'),
          content: Text(
              'বইটি প্রায় ${bnDigits((bk.size / (1024 * 1024)).round().toString())} MB। ডাউনলোড করবেন? (ওয়াই-ফাই হলে ভালো)'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('না')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('ডাউনলোড')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await openBook(context, bk);
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: widget.title,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: TextField(
              controller: _ctl,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                _query = v.trim();
                _search();
              },
              decoration: InputDecoration(
                hintText: 'বইয়ের নাম বা লেখক খুঁজুন (যেমন: Riyadus, নামাজ, Bukhari)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _query = _ctl.text.trim();
                    _search();
                  },
                ),
                filled: true,
                fillColor: wh(.08),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _langs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(_langs[i].label),
                selected: _lang == i,
                onSelected: (_) {
                  if (_lang == i) return;
                  setState(() => _lang = i);
                  _search();
                },
              ),
            ),
          ),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  Widget _list() {
    if (_hits.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      return ListView(
        padding: const EdgeInsets.fromLTRB(28, 70, 28, 24),
        children: [
          Icon(_failed ? Icons.cloud_off_rounded : Icons.search_off_rounded,
              size: 54, color: wh(.55)),
          const SizedBox(height: 14),
          Text(
            _failed
                ? 'ইন্টারনেট সংযোগ নেই বা সার্ভারে পৌঁছানো যায়নি।'
                : 'কোনো বই পাওয়া যায়নি। অন্য শব্দে বা অন্য ভাষায় খুঁজুন।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.5, color: wh(.8)),
          ),
          if (_failed) ...[
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('আবার চেষ্টা করুন'),
              ),
            ),
          ],
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('আগে পড়া বই (ডাউনলোড থাকলে অফলাইনেও খোলে)',
                style: TextStyle(fontSize: 13.5, color: wh(.7))),
            const SizedBox(height: 8),
            for (final e in _history.take(10))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  blur: 0,
                  radius: 16,
                  opacity: 0.10,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: () => openBook(context, e.book),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: kGold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(e.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      );
    }
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _hits.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == _hits.length) {
          if (_loading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_failed) {
            return TextButton.icon(
              onPressed: () => _search(more: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('আবার চেষ্টা করুন'),
            );
          }
          if (_more) {
            return TextButton(
                onPressed: () => _search(more: true), child: const Text('আরও দেখুন'));
          }
          return const FootNote('বইগুলো archive.org এর উন্মুক্ত সংগ্রহ থেকে। ট্যাপ করলে ডাউনলোড হয়ে পড়ার পেজে খুলবে।');
        }
        final h = _hits[i];
        final busy = _opening == h.id;
        return GlassCard(
          blur: 0,
          radius: 18,
          opacity: 0.10,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => _open(h),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFE08A), Color(0xFFB7791F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B2A05)),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF3B2A05)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.title.isEmpty ? h.id : h.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, height: 1.35)),
                    if (h.author.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(h.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: wh(.72))),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: wh(.6)),
            ],
          ),
        );
      },
    );
  }
}

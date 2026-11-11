import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n.dart';
import '../ui/glass.dart';
import 'common.dart';
import 'kitab_data.dart';
import 'kitab_reader.dart';

const _statusLabels = ['তালিকায়', 'পড়তে চাই', 'পড়ছি', 'শেষ করেছি'];
const _statusIcons = [
  Icons.add_circle_outline_rounded,
  Icons.bookmark_add_outlined,
  Icons.auto_stories_rounded,
  Icons.check_circle_rounded,
];

class KitabScreen extends StatefulWidget {
  const KitabScreen({super.key});

  @override
  State<KitabScreen> createState() => _KitabScreenState();
}

class _KitabScreenState extends State<KitabScreen> with WidgetsBindingObserver {
  List<Book> _books = [];
  final Map<String, int> _status = {};
  bool _loading = true; // first load (nothing to show yet)
  bool _syncing = false;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  Future<void> _init() async {
    final c = await KitabRemote.cached();
    if (c.isNotEmpty) {
      await _loadStatus(c);
      if (mounted) setState(() { _books = c; _loading = false; });
    }
    await _sync();
  }

  Future<void> _loadStatus(List<Book> l) async {
    final p = await SharedPreferences.getInstance();
    for (final b in l) {
      final v = p.getInt(KitabHistory.statusKey(b.file)) ?? 0;
      _status[b.file] = (v >= 0 && v < _statusLabels.length) ? v : 0;
    }
  }

  Future<void> _sync() async {
    if (_syncing) return;
    if (mounted) setState(() => _syncing = true);
    final r = await KitabRemote.sync();
    await _loadStatus(r.books);
    if (!mounted) return;
    setState(() {
      _books = r.books;
      _offline = !r.ok;
      _loading = false;
      _syncing = false;
    });
  }

  Future<void> _cycle(Book b) async {
    final n = ((_status[b.file] ?? 0) + 1) % _statusLabels.length;
    setState(() => _status[b.file] = n);
    final p = await SharedPreferences.getInstance();
    await p.setInt(KitabHistory.statusKey(b.file), n);
  }

  Future<void> _open(Book b) async {
    await openBook(context, b);
    if (mounted) {
      await _loadStatus(_books);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: tr('f_kitab'),
      actions: [
        if (_syncing)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _sync, child: _list()),
    );
  }

  Widget _list() {
    if (_books.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 80, 28, 24),
        children: [
          Icon(_offline ? Icons.cloud_off_rounded : Icons.library_books_rounded,
              size: 54, color: wh(.55)),
          const SizedBox(height: 14),
          Text(
            _offline
                ? 'ইন্টারনেট সংযোগ নেই। সংযোগ দিয়ে নিচে টেনে রিফ্রেশ করুন।'
                : 'এখনও কোনো কিতাব নেই।\nGitHub রিপোর kitab ফোল্ডারে PDF আপলোড করলে এখানে দেখা যাবে।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.5, color: wh(.8)),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: _books.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == _books.length) {
          return FootNote(_offline
              ? 'অফলাইন — আগের তালিকা দেখানো হচ্ছে।'
              : 'কিতাবে ট্যাপ করলে নতুন পেজে খুলবে। ডান পাশের আইকনে ট্যাপ করে অবস্থা বদলান (পড়তে চাই → পড়ছি → শেষ করেছি)।');
        }
        final b = _books[i];
        final s = _status[b.file] ?? 0;
        final active = s != 0;
        return GlassCard(
          blur: 0,
          radius: 18,
          opacity: active ? 0.16 : 0.10,
          tint: s == 3 ? kMint : (s == 2 ? kGold : null),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => _open(b),
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
                child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF3B2A05)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.35)),
                    if (b.sizeText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('PDF · ${bnDigits(b.sizeText)}',
                          style: TextStyle(fontSize: 12.5, color: wh(.72))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _cycle(b),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Column(
                    children: [
                      Icon(_statusIcons[s], color: active ? Colors.white : wh(.6)),
                      const SizedBox(height: 2),
                      Text(_statusLabels[s], style: TextStyle(fontSize: 11, color: wh(.8))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

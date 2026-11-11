import 'package:flutter/material.dart';
import '../ui/glass.dart';
import 'models.dart';
import 'reader_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Surah> _all = [];
  List<String> _keys = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await QuranRepo.load();
    final b = (await QuranStore.bookmarks()).toList();
    b.sort((a, c) {
      final x = a.split(':').map(int.parse).toList();
      final y = c.split(':').map(int.parse).toList();
      return x[0] != y[0] ? x[0].compareTo(y[0]) : x[1].compareTo(y[1]);
    });
    if (mounted) {
      setState(() {
        _all = all;
        _keys = b;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('বুকমার্ক')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _keys.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'কোনো বুকমার্ক নেই।\nআয়াতের পাশের বুকমার্ক আইকনে চাপ দিন।',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: wh(.75), height: 1.5),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: _keys.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = _keys[i].split(':').map(int.parse).toList();
                      final s = _all[p[0] - 1];
                      final v = s.verses[p[1] - 1];
                      return GlassCard(
                        radius: 20,
                        blur: 0,
                        opacity: 0.10,
                        padding: const EdgeInsets.all(14),
                        onTap: () async {
                          await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => ReaderScreen(surah: s)));
                          _load();
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.bookmark_rounded, color: kGold),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${s.transliteration} ${toBn(s.id)}:${toBn(v.id)}',
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(v.translation,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: wh(.75), height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

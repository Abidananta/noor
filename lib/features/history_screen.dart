import 'package:flutter/material.dart';
import '../i18n.dart';
import '../ui/glass.dart';
import 'common.dart';
import '../quran/models.dart';
import '../quran/reader_screen.dart';
import 'kitab_data.dart';
import 'kitab_reader.dart';

/// Full history (opened from the Profile page menu): every surah read or
/// listened to, and every kitab opened, newest first.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<_Row>? _rows;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final books = await KitabHistory.load();
    final surahs = await SurahHistory.load();
    List<Surah> all = [];
    try {
      all = await QuranRepo.load();
    } catch (_) {}
    final rows = <_Row>[
      for (final b in books) _Row(b.at, book: b),
      for (final e in surahs)
        if (e.surah >= 1 && e.surah <= all.length) _Row(e.at, surah: all[e.surah - 1], entry: e),
    ]..sort((a, b) => b.at.compareTo(a.at));
    if (mounted) setState(() => _rows = rows);
  }

  @override
  Widget build(BuildContext context) {
    final list = _rows;
    return GlassPage(
      title: tr('pf_history'),
      body: list == null
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    GlassCard(
                      blur: 0,
                      radius: 18,
                      opacity: 0.10,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, color: kGold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(tr('pf_hist_empty'),
                                style: TextStyle(color: wh(.75))),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final r = list[i];
                      final sr = r.surah;
                      final h = r.book;
                      final String title;
                      final String sub;
                      final IconData icon;
                      if (sr != null) {
                        final e = r.entry!;
                        title = '${toBn(sr.id)}. ${sr.transliteration}';
                        final parts = <String>['কুরআন'];
                        if (e.reads > 0) parts.add('পড়া ${toBn(e.reads)} বার');
                        if (e.listens > 0) parts.add('শোনা ${toBn(e.listens)} বার');
                        sub = parts.join(' · ');
                        icon = Icons.auto_stories_rounded;
                      } else {
                        title = h!.title;
                        sub = 'PDF${h.book.sizeText.isEmpty ? '' : ' · ${h.book.sizeText}'}';
                        icon = Icons.menu_book_rounded;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          blur: 0,
                          radius: 16,
                          opacity: 0.10,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          onTap: () async {
                            if (sr != null) {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => ReaderScreen(surah: sr)));
                            } else {
                              await openBook(context, h!.book);
                            }
                            if (mounted) _load();
                          },
                          child: Row(
                            children: [
                              Icon(icon, color: kGold),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w700)),
                                    Text(sub,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12.5, color: wh(.7))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(formatStamp(r.at),
                                  style: TextStyle(fontSize: 11.5, color: wh(.65))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _Row {
  final DateTime at;
  final HistoryEntry? book;
  final Surah? surah;
  final SurahHistoryEntry? entry;
  _Row(this.at, {this.book, this.surah, this.entry});
}

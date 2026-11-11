import '../i18n.dart';
import 'package:flutter/material.dart';
import '../ui/glass.dart';
import 'models.dart';
import 'reader_screen.dart';
import 'bookmarks_screen.dart';
import 'quran_audio.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  late Future<List<Surah>> _future;
  String _query = '';
  int? _last;

  @override
  void initState() {
    super.initState();
    _future = QuranRepo.load();
    _loadLast();
  }

  Future<void> _loadLast() async {
    final l = await QuranStore.lastSurah();
    if (mounted) setState(() => _last = l);
  }

  Future<void> _open(Surah s) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => ReaderScreen(surah: s)));
    _loadLast();
  }

  bool _match(Surah s) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase().trim();
    return s.transliteration.toLowerCase().contains(q) ||
        s.meaning.contains(q) ||
        s.name.contains(q) ||
        s.id.toString() == q ||
        toBn(s.id) == q;
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(tr('f_quran')),
          actions: [
            IconButton(
              tooltip: 'বুকমার্ক',
              icon: const Icon(Icons.bookmark_border_rounded),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BookmarksScreen())),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
                child: FutureBuilder<List<Surah>>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('লোড করা যায়নি: ${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snap.data!;
            final list = all.where(_match).toList();
            Surah? last;
            if (_last != null && _query.isEmpty) last = all[_last! - 1];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: GlassCard(
                    radius: 26,
                    blur: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'সূরা খুঁজুন (নাম বা নম্বর)',
                        hintStyle: TextStyle(color: wh(.6)),
                        prefixIcon: Icon(Icons.search_rounded, color: wh(.8)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                ),
                if (last != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: GlassCard(
                      tint: kGold,
                      opacity: 0.14,
                      blur: 14,
                      radius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      onTap: () => _open(last!),
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, color: kGold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('শেষ পড়া: ${last.transliteration}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w600)),
                                Text('${last.meaning} · ${toBn(last.totalVerses)} আয়াত',
                                    style: TextStyle(fontSize: 13, color: wh(.7))),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == list.length) return const _Credit();
                      final s = list[i];
                      return GlassCard(
                        radius: 20,
                        blur: 0,
                        opacity: 0.10,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        onTap: () => _open(s),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFFFE08A), Color(0xFFE0A33A)],
                                ),
                                boxShadow: [
                                  BoxShadow(color: kGold.withOpacity(.4), blurRadius: 10),
                                ],
                              ),
                              child: Text(toBn(s.id),
                                  style: const TextStyle(
                                      color: Color(0xFF3B2A05),
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.transliteration,
                                      style: const TextStyle(
                                          fontSize: 17, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${s.meaning} · ${toBn(s.totalVerses)} আয়াত · ${s.typeBn}',
                                      style: TextStyle(fontSize: 13, color: wh(.7))),
                                ],
                              ),
                            ),
                            Text(s.name, style: const TextStyle(fontSize: 25, color: kGold)),
                            const SizedBox(width: 2),
                            SurahPlayButton(surah: s.id),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        )),
          ],
        ),
      ),
    );
  }
}

class _Credit extends StatelessWidget {
  const _Credit();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'বাংলা অনুবাদ: মুহিউদ্দীন খান (tanzil.net)\nআরবি পাঠ: The Noble Qur\'an Encyclopedia',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: wh(.5)),
      ),
    );
  }
}

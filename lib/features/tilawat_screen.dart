import '../i18n.dart';
import 'package:flutter/material.dart';
import '../quran/bookmarks_screen.dart';
import '../quran/models.dart';
import '../quran/quran_audio.dart';
import '../quran/reader_screen.dart';
import 'history_screen.dart';
import '../ui/glass.dart';
import 'common.dart';

class TilawatScreen extends StatefulWidget {
  const TilawatScreen({super.key});

  @override
  State<TilawatScreen> createState() => _TilawatScreenState();
}

class _TilawatScreenState extends State<TilawatScreen> {
  late Future<List<Surah>> _future;
  int? _last;
  String _query = '';

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
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderScreen(surah: s)));
    _loadLast();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: tr('f_tilawat'),
      body: FutureBuilder<List<Surah>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('লোড করা যায়নি: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = snap.data!;
          final last = (_last != null && _last! >= 1 && _last! <= all.length)
              ? all[_last! - 1]
              : null;

          final list = all.where(_match).toList();
          final head = <Widget>[
            GlassCard(
              tint: kGold,
              opacity: 0.14,
              blur: 0,
              padding: const EdgeInsets.all(16),
              onTap: () => _open(last ?? all.first),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill_rounded, size: 40, color: kGold),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(last == null ? 'তিলাওয়াত শুরু করুন' : 'যেখানে থেমেছিলেন',
                            style: TextStyle(fontSize: 13, color: wh(.75))),
                        const SizedBox(height: 2),
                        Text((last ?? all.first).transliteration,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Action(
                    icon: Icons.bookmark_border_rounded,
                    label: 'বুকমার্ক',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BookmarksScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Action(
                    icon: Icons.history_rounded,
                    label: 'ইতিহাস',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GlassCard(
              radius: 26,
              blur: 0,
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
            const SizedBox(height: 18),
            const Text('সকল সূরা',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
          ];

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            itemCount: head.length + list.length + 1,
            itemBuilder: (_, i) {
              if (i < head.length) return head[i];
              final j = i - head.length;
              if (j == list.length) {
                return const FootNote(
                    'ডান পাশের প্লে বাটনে ট্যাপ করে তিলাওয়াত শুনুন, অথবা সূরায় ট্যাপ করে পড়ুন।');
              }
              final sr = list[j];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  blur: 0,
                  radius: 18,
                  opacity: 0.10,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: () => _open(sr),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: kGold,
                        child: Text(toBn(sr.id),
                            style: const TextStyle(
                                color: Color(0xFF3B2A05),
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sr.transliteration,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            Text('${sr.meaning} · ${toBn(sr.totalVerses)} আয়াত',
                                style: TextStyle(fontSize: 12.5, color: wh(.7))),
                          ],
                        ),
                      ),
                      Text(sr.name, style: const TextStyle(fontSize: 22, color: kGold)),
                      const SizedBox(width: 2),
                      SurahPlayButton(surah: sr.id),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 0,
      radius: 18,
      opacity: 0.10,
      padding: const EdgeInsets.symmetric(vertical: 14),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: kMint),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

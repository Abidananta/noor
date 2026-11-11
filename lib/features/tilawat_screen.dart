import 'package:flutter/material.dart';
import '../quran/bookmarks_screen.dart';
import '../quran/models.dart';
import '../quran/reader_screen.dart';
import '../quran/surah_list_screen.dart';
import '../ui/glass.dart';
import 'common.dart';

/// Surah ids that are commonly recited.
const _popular = <int>[1, 36, 55, 56, 67, 18, 112, 113, 114];

class TilawatScreen extends StatefulWidget {
  const TilawatScreen({super.key});

  @override
  State<TilawatScreen> createState() => _TilawatScreenState();
}

class _TilawatScreenState extends State<TilawatScreen> {
  late Future<List<Surah>> _future;
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
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderScreen(surah: s)));
    _loadLast();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'তিলাওয়াত',
      body: FutureBuilder<List<Surah>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('লোড করা যায়নি: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = snap.data!;
          final last = (_last != null && _last! >= 1 && _last! <= all.length)
              ? all[_last! - 1]
              : null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            children: [
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
                      icon: Icons.list_alt_rounded,
                      label: 'সকল সূরা',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SurahListScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('নিয়মিত তিলাওয়াতের সূরা',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              for (final id in _popular)
                if (id <= all.length)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      blur: 0,
                      radius: 18,
                      opacity: 0.10,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      onTap: () => _open(all[id - 1]),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: kGold,
                            child: Text(toBn(id),
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
                                Text(all[id - 1].transliteration,
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w600)),
                                Text(
                                    '${all[id - 1].meaning} · ${toBn(all[id - 1].totalVerses)} আয়াত',
                                    style: TextStyle(fontSize: 12.5, color: wh(.7))),
                              ],
                            ),
                          ),
                          Text(all[id - 1].name,
                              style: const TextStyle(fontSize: 22, color: kGold)),
                        ],
                      ),
                    ),
                  ),
              const FootNote('অডিও তিলাওয়াত এই সংস্করণে নেই; এখানে পড়ার মাধ্যমে তিলাওয়াত করা যাবে।'),
            ],
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

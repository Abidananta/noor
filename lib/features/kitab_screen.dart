import '../i18n.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/glass.dart';
import 'common.dart';
import 'kitab_data.dart';

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

class _KitabScreenState extends State<KitabScreen> {
  final List<int> _status = List<int>.filled(kBooks.length, 0);
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    for (int i = 0; i < kBooks.length; i++) {
      final v = p.getInt('kitab_$i') ?? 0;
      _status[i] = (v >= 0 && v < _statusLabels.length) ? v : 0;
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _cycle(int i) async {
    setState(() => _status[i] = (_status[i] + 1) % _statusLabels.length);
    final p = await SharedPreferences.getInstance();
    await p.setInt('kitab_$i', _status[i]);
  }

  Future<void> _open(int i) async {
    await openBook(context, i);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return GlassPage(title: tr('f_kitab'), body: const Center(child: CircularProgressIndicator()));
    }
    return GlassPage(
      title: tr('f_kitab'),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: kBooks.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == kBooks.length) {
            return const FootNote(
                'কার্ডে ট্যাপ করলে বইটি পড়ার জন্য খুলবে। ডান পাশের আইকনে ট্যাপ করে অবস্থা বদলান (পড়তে চাই → পড়ছি → শেষ করেছি)। যে বইগুলো খুলেছেন সেগুলো প্রোফাইলের "পড়ার ইতিহাস"-এ দেখা যাবে।');
          }
          final b = kBooks[i];
          final s = _status[i];
          final active = s != 0;
          return GlassCard(
            blur: 0,
            radius: 18,
            opacity: active ? 0.16 : 0.10,
            tint: s == 3 ? kMint : (s == 2 ? kGold : null),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () => _open(i),
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
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF3B2A05)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(b.author, style: const TextStyle(fontSize: 13, color: kGold)),
                      const SizedBox(height: 2),
                      Text(b.about, style: TextStyle(fontSize: 12.5, color: wh(.72))),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _cycle(i),
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
      ),
    );
  }
}

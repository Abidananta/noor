import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/glass.dart';
import 'common.dart';

class _Book {
  final String title;
  final String author;
  final String about;
  const _Book(this.title, this.author, this.about);
}

const _books = <_Book>[
  _Book('রিয়াদুস সালেহীন', 'ইমাম নববী (রহ.)', 'আখলাক, ইবাদত ও দৈনন্দিন জীবনের হাদীস সংকলন'),
  _Book('আল-আরবাঈন আন-নববীয়্যাহ', 'ইমাম নববী (রহ.)', 'দ্বীনের মূল ভিত্তিসংক্রান্ত চল্লিশটি হাদীস'),
  _Book('সহীহ বুখারী', 'ইমাম বুখারী (রহ.)', 'সবচেয়ে প্রসিদ্ধ হাদীস সংকলন'),
  _Book('সহীহ মুসলিম', 'ইমাম মুসলিম (রহ.)', 'সিহাহ সিত্তাহর অন্যতম প্রধান গ্রন্থ'),
  _Book('হিসনুল মুসলিম', 'সাঈদ ইবনু আলী আল-কাহতানী', 'কুরআন-সুন্নাহর দু\'আ ও যিকিরের সংকলন'),
  _Book('আর-রাহীকুল মাখতূম', 'সফিউর রহমান মুবারকপুরী', 'রাসূলুল্লাহ ﷺ-এর সীরাত'),
  _Book('তাফসীর ইবনু কাসীর', 'ইমাম ইবনু কাসীর (রহ.)', 'কুরআনের প্রসিদ্ধ তাফসীর'),
  _Book('ফিকহুস সুন্নাহ', 'সাইয়্যিদ সাবিক (রহ.)', 'ইবাদত ও লেনদেনের মাসআলা'),
  _Book('বেহেশতী জেওর', 'আশরাফ আলী থানভী (রহ.)', 'দৈনন্দিন মাসআলা-মাসায়েল'),
  _Book('ফাযায়েলে আমল', 'যাকারিয়া কান্ধলভী (রহ.)', 'আমলের ফযীলতসংক্রান্ত সংকলন'),
];

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
  final List<int> _status = List<int>.filled(_books.length, 0);
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    for (int i = 0; i < _books.length; i++) {
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

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const GlassPage(title: 'কিতাব', body: Center(child: CircularProgressIndicator()));
    }
    return GlassPage(
      title: 'কিতাব',
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: _books.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == _books.length) {
            return const FootNote(
                'এটি আপনার পড়ার তালিকা। কার্ডে ট্যাপ করে অবস্থা বদলান (পড়তে চাই → পড়ছি → শেষ করেছি)।');
          }
          final b = _books[i];
          final s = _status[i];
          final active = s != 0;
          return GlassCard(
            blur: 0,
            radius: 18,
            opacity: active ? 0.16 : 0.10,
            tint: s == 3 ? kMint : (s == 2 ? kGold : null),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () => _cycle(i),
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
                const SizedBox(width: 8),
                Column(
                  children: [
                    Icon(_statusIcons[s], color: active ? Colors.white : wh(.6)),
                    const SizedBox(height: 2),
                    Text(_statusLabels[s], style: TextStyle(fontSize: 11, color: wh(.8))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

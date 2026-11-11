import '../i18n.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/glass.dart';
import 'common.dart';

class _Section {
  final String title;
  final IconData icon;
  final List<String> points;
  const _Section(this.title, this.icon, this.points);
}

const _sections = <_Section>[
  _Section('বিবাহের গুরুত্ব', Icons.favorite_rounded, [
    'আল্লাহ তাআলা বলেন, তিনি তোমাদের জন্য তোমাদের মধ্য থেকেই জোড়া সৃষ্টি করেছেন, যাতে তোমরা তাদের কাছে শান্তি পাও এবং তিনি তোমাদের মধ্যে ভালোবাসা ও দয়া সৃষ্টি করেছেন। (সূরা রূম ৩০:২১)',
    'রাসূলুল্লাহ ﷺ বলেছেন, "হে যুবসমাজ! তোমাদের মধ্যে যে বিবাহের সামর্থ্য রাখে, সে যেন বিবাহ করে। কারণ এটি দৃষ্টি অবনত রাখে ও লজ্জাস্থানের হিফাযত করে।" (বুখারী ও মুসলিম)',
  ]),
  _Section('পাত্র-পাত্রী নির্বাচন', Icons.search_rounded, [
    'রাসূলুল্লাহ ﷺ দ্বীনদারীকে প্রাধান্য দিতে বলেছেন: "তুমি দ্বীনদার নারীকে বেছে নাও, তোমার হাত ধুলোমলিন হোক!" (বুখারী ও মুসলিম)',
    'উভয় পক্ষের চরিত্র, আচরণ ও দ্বীনি অবস্থা সম্পর্কে নির্ভরযোগ্য সূত্রে খোঁজখবর নেওয়া উচিত।',
    'ইস্তিখারা ও পরিবারের পরামর্শ নিয়ে সিদ্ধান্ত নেওয়া ভালো।',
  ]),
  _Section('বিবাহের শর্ত ও রুকন', Icons.rule_rounded, [
    'পাত্র ও পাত্রী উভয়ের সম্মতি থাকা আবশ্যক।',
    'একই মজলিসে ইজাব (প্রস্তাব) ও কবুল (গ্রহণ) হওয়া।',
    'কমপক্ষে দুইজন সাক্ষীর উপস্থিতি।',
    'মোহর নির্ধারণ করা।',
    'এ বিষয়ের খুঁটিনাটি ও মাযহাবভেদে পার্থক্য জানতে আলেমের সাথে পরামর্শ করুন।',
  ]),
  _Section('মোহর', Icons.card_giftcard_rounded, [
    'মোহর স্ত্রীর অধিকার; এটি সন্তুষ্টচিত্তে পরিশোধ করতে হয়। (সূরা নিসা ৪:৪)',
    'মোহর নির্ধারণে সামর্থ্য ও পারস্পরিক সম্মতিকে গুরুত্ব দেওয়া উচিত; অযথা বাড়াবাড়ি এড়ানো ভালো।',
  ]),
  _Section('ওয়ালীমা', Icons.restaurant_rounded, [
    'বিবাহের পর ওয়ালীমা করা সুন্নাত। রাসূলুল্লাহ ﷺ আবদুর রহমান ইবনু আউফ (রা.)-কে বলেছিলেন, "ওয়ালীমা করো, একটি ছাগল দিয়ে হলেও।" (বুখারী ও মুসলিম)',
    'অপচয় ও লৌকিকতা এড়িয়ে সাধ্যমতো আয়োজন করা উচিত।',
  ]),
  _Section('দাম্পত্য জীবন', Icons.home_rounded, [
    'রাসূলুল্লাহ ﷺ বলেছেন, "তোমাদের মধ্যে সর্বোত্তম সে, যে তার পরিবারের কাছে সর্বোত্তম।" (তিরমিযী)',
    'পারস্পরিক সম্মান, ধৈর্য, ক্ষমা ও খোলামেলা আলোচনা সুখী সংসারের ভিত্তি।',
  ]),
];

const _checklist = <(String, String)>[
  ('families', 'উভয় পরিবারের সম্মতি ও পরিচয় সম্পন্ন'),
  ('istikhara', 'ইস্তিখারা ও পরামর্শ করা হয়েছে'),
  ('mahr', 'মোহর নির্ধারণ'),
  ('witness', 'সাক্ষী ও বিবাহ পড়ানোর ব্যক্তি ঠিক করা'),
  ('kabin', 'কাবিননামা ও নিবন্ধনের প্রস্তুতি (কাজী অফিস)'),
  ('walima', 'ওয়ালীমার পরিকল্পনা'),
];

class BibahoScreen extends StatefulWidget {
  const BibahoScreen({super.key});

  @override
  State<BibahoScreen> createState() => _BibahoScreenState();
}

class _BibahoScreenState extends State<BibahoScreen> {
  final Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getStringList('bibaho_checklist') ?? <String>[];
    if (mounted) setState(() => _done.addAll(saved));
  }

  Future<void> _toggle(String id) async {
    setState(() {
      if (!_done.remove(id)) _done.add(id);
    });
    final p = await SharedPreferences.getInstance();
    await p.setStringList('bibaho_checklist', _done.toList());
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: tr('f_bibaho'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          GlassCard(
            blur: 0,
            tint: const Color(0xFFFDA4AF),
            opacity: 0.12,
            radius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.checklist_rounded, color: Color(0xFFFDA4AF)),
                    const SizedBox(width: 10),
                    const Text('প্রস্তুতি চেকলিস্ট',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(bnDigits('${_done.length}/${_checklist.length}'),
                        style: TextStyle(color: wh(.8))),
                  ],
                ),
                const SizedBox(height: 6),
                for (final c in _checklist)
                  InkWell(
                    onTap: () => _toggle(c.$1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            _done.contains(c.$1)
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: _done.contains(c.$1) ? kMint : wh(.6),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(c.$2, style: const TextStyle(fontSize: 15))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final s in _sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                blur: 0,
                radius: 18,
                opacity: 0.10,
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    iconColor: kGold,
                    collapsedIconColor: wh(.7),
                    leading: Icon(s.icon, color: kGold),
                    title: Text(s.title,
                        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
                    children: [
                      for (final p in s.points)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('• $p',
                              style: TextStyle(fontSize: 15, height: 1.55, color: wh(.9))),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const FootNote(
              'এটি সাধারণ দিকনির্দেশনা। বিবাহের আইনি ও ফিকহী বিষয়ে স্থানীয় কাজী/আলেমের পরামর্শ নিন।'),
        ],
      ),
    );
  }
}

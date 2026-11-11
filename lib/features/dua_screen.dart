import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/glass.dart';
import 'common.dart';

class _Dua {
  final String cat;
  final String title;
  final String arabic;
  final String meaning;
  final String source;
  const _Dua(this.cat, this.title, this.arabic, this.meaning, this.source);
}

const _daily = 'দৈনন্দিন';
const _quran = "কুরআনের দু'আ";

const _duas = <_Dua>[
  _Dua(_daily, 'ঘুম থেকে উঠে',
      'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      'সকল প্রশংসা আল্লাহর, যিনি আমাদের মৃত্যুর (ঘুমের) পর জীবিত করেছেন। আর তাঁরই কাছে পুনরুত্থান।',
      'বুখারী'),
  _Dua(_daily, 'ঘুমানোর আগে', 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      'হে আল্লাহ! আপনার নামেই আমি মৃত্যুবরণ করি (ঘুমাই) এবং জীবিত হই (জাগি)।', 'বুখারী'),
  _Dua(_daily, 'খাওয়ার শুরুতে', 'بِسْمِ اللَّهِ', 'আল্লাহর নামে (শুরু করছি)।',
      'আবূ দাঊদ, তিরমিযী'),
  _Dua(_daily, 'খাওয়ার পরে',
      'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
      'সকল প্রশংসা আল্লাহর, যিনি আমাদের খাওয়ালেন, পান করালেন এবং মুসলিম বানালেন।',
      'আবূ দাঊদ, তিরমিযী'),
  _Dua(_daily, 'ঘর থেকে বের হওয়ার সময়',
      'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      'আল্লাহর নামে (বের হলাম), আল্লাহর ওপর ভরসা করলাম। আল্লাহর সাহায্য ছাড়া কোনো উপায় ও শক্তি নেই।',
      'আবূ দাঊদ, তিরমিযী'),
  _Dua(_daily, 'মসজিদে প্রবেশের সময়', 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
      'হে আল্লাহ! আমার জন্য আপনার রহমতের দরজাগুলো খুলে দিন।', 'মুসলিম'),
  _Dua(_daily, 'মসজিদ থেকে বের হওয়ার সময়', 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
      'হে আল্লাহ! আমি আপনার অনুগ্রহ প্রার্থনা করছি।', 'মুসলিম'),
  _Dua(_daily, 'ইস্তিঞ্জায় প্রবেশের সময়',
      'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ',
      'হে আল্লাহ! আমি আপনার কাছে অনিষ্টকর সবকিছু (পুরুষ ও নারী শয়তান) থেকে আশ্রয় চাই।',
      'বুখারী ও মুসলিম'),
  _Dua(_daily, 'ক্ষমা প্রার্থনা', 'أَسْتَغْفِرُ اللَّهَ', 'আমি আল্লাহর কাছে ক্ষমা চাই।',
      'হাদীসে বর্ণিত'),
  _Dua(_quran, 'দুনিয়া ও আখিরাতের কল্যাণ',
      'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      'হে আমাদের রব! আমাদের দুনিয়াতে কল্যাণ দিন, আখিরাতেও কল্যাণ দিন এবং আমাদের জাহান্নামের আযাব থেকে রক্ষা করুন।',
      'সূরা বাকারা ২:২০১'),
  _Dua(_quran, 'ইলম বৃদ্ধির দু\'আ', 'رَبِّ زِدْنِي عِلْمًا',
      'হে আমার রব! আমার জ্ঞান বৃদ্ধি করে দিন।', 'সূরা তা-হা ২০:১১৪'),
  _Dua(_quran, 'পিতামাতার জন্য দু\'আ', 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
      'হে আমার রব! তাঁদের উভয়ের প্রতি দয়া করুন, যেমন তাঁরা আমাকে শৈশবে লালন-পালন করেছেন।',
      'সূরা বনী ইসরাঈল ১৭:২৪'),
  _Dua(_quran, 'বিপদ থেকে মুক্তি (ইউনুস আ.-এর দু\'আ)',
      'لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
      'আপনি ছাড়া কোনো ইলাহ নেই, আপনি পবিত্র; নিশ্চয়ই আমি যালিমদের অন্তর্ভুক্ত ছিলাম।',
      'সূরা আম্বিয়া ২১:৮৭'),
  _Dua(_quran, 'ক্ষমা প্রার্থনা (আদম ও হাওয়া আ.-এর দু\'আ)',
      'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
      'হে আমাদের রব! আমরা নিজেদের ওপর যুলুম করেছি। আপনি যদি আমাদের ক্ষমা না করেন ও দয়া না করেন, তাহলে অবশ্যই আমরা ক্ষতিগ্রস্তদের অন্তর্ভুক্ত হবো।',
      'সূরা আ\'রাফ ৭:২৩'),
  _Dua(_quran, 'আল্লাহর ওপর ভরসা', 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      'আল্লাহই আমাদের জন্য যথেষ্ট এবং তিনিই উত্তম কর্মবিধায়ক।', 'সূরা আলে ইমরান ৩:১৭৩'),
  _Dua(_quran, 'হিদায়াতের ওপর অটল থাকা',
      'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً ۚ إِنَّكَ أَنتَ الْوَهَّابُ',
      'হে আমাদের রব! হিদায়াত দেওয়ার পর আপনি আমাদের অন্তরকে বাঁকা করে দেবেন না। আপনার পক্ষ থেকে আমাদের রহমত দান করুন; নিশ্চয়ই আপনি মহান দাতা।',
      'সূরা আলে ইমরান ৩:৮'),
];

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  String _filter = 'সব';

  @override
  Widget build(BuildContext context) {
    final cats = ['সব', _daily, _quran];
    final list = _duas.where((d) => _filter == 'সব' || d.cat == _filter).toList();

    return GlassPage(
      title: "দু'আ",
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(cats[i]),
                selected: _filter == cats[i],
                onSelected: (_) => setState(() => _filter = cats[i]),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: list.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == list.length) {
                  return const FootNote(
                      'আরবি পাঠ ও উচ্চারণ ভালোভাবে শিখে নিতে একজন যোগ্য উস্তাদের সাহায্য নিন।');
                }
                final d = list[i];
                return GlassCard(
                  blur: 0,
                  opacity: 0.10,
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(d.arabic,
                                style: const TextStyle(
                                    fontSize: 24, height: 1.9, color: kGold)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(d.meaning,
                            style: TextStyle(fontSize: 15, height: 1.5, color: wh(.9))),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(d.source,
                                style: TextStyle(fontSize: 12.5, color: wh(.6))),
                          ),
                          IconButton(
                            tooltip: 'কপি',
                            icon: Icon(Icons.copy_rounded, size: 20, color: wh(.8)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: '${d.arabic}\n${d.meaning}\n— ${d.source}'));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('কপি হয়েছে'),
                                  duration: Duration(seconds: 1)));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

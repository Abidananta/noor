import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/glass.dart';
import 'common.dart';

class _Hadith {
  final String text;
  final String narrator;
  final String source;
  const _Hadith(this.text, this.narrator, this.source);
}

const _hadiths = <_Hadith>[
  _Hadith('নিশ্চয়ই সকল কাজ নিয়তের ওপর নির্ভরশীল। আর প্রত্যেক ব্যক্তি তা-ই পাবে, যা সে নিয়ত করে।',
      'উমর ইবনুল খাত্তাব (রা.)', 'বুখারী ও মুসলিম'),
  _Hadith('তোমাদের কেউ প্রকৃত মুমিন হতে পারবে না, যতক্ষণ না সে তার ভাইয়ের জন্য তা-ই পছন্দ করে, যা নিজের জন্য পছন্দ করে।',
      'আনাস (রা.)', 'বুখারী ও মুসলিম'),
  _Hadith('যে ব্যক্তি আল্লাহ ও আখিরাত দিবসে বিশ্বাস রাখে, সে যেন ভালো কথা বলে অথবা চুপ থাকে।',
      'আবূ হুরায়রা (রা.)', 'বুখারী ও মুসলিম'),
  _Hadith('তোমাদের মধ্যে সর্বোত্তম সেই ব্যক্তি, যে কুরআন শেখে এবং অন্যকে শেখায়।',
      'উসমান ইবনু আফফান (রা.)', 'বুখারী'),
  _Hadith('দ্বীন হলো কল্যাণ কামনা (নসীহত)।', 'তামীম আদ-দারী (রা.)', 'মুসলিম'),
  _Hadith('প্রকৃত বীর সে নয়, যে কুস্তিতে অন্যকে হারিয়ে দেয়; বরং প্রকৃত বীর সে, যে রাগের সময় নিজেকে নিয়ন্ত্রণ করে।',
      'আবূ হুরায়রা (রা.)', 'বুখারী ও মুসলিম'),
  _Hadith('তোমার ভাইয়ের সামনে মুচকি হাসাও সদাকা।', 'আবূ যার (রা.)', 'তিরমিযী'),
  _Hadith('তোমরা সহজ করো, কঠিন করো না; সুসংবাদ দাও, বীতশ্রদ্ধ করো না।',
      'আনাস (রা.)', 'বুখারী ও মুসলিম'),
  _Hadith('আল্লাহর কাছে সবচেয়ে প্রিয় আমল হলো তা, যা নিয়মিত করা হয়— তা পরিমাণে কম হলেও।',
      'আয়িশা (রা.)', 'বুখারী ও মুসলিম'),
  _Hadith('পবিত্রতা ঈমানের অর্ধেক।', 'আবূ মালিক আল-আশআরী (রা.)', 'মুসলিম'),
  _Hadith('যে ব্যক্তি মানুষের প্রতি দয়া করে না, আল্লাহও তার প্রতি দয়া করেন না।',
      'জারীর ইবনু আবদিল্লাহ (রা.)', 'বুখারী ও মুসলিম'),
  _Hadith('মুসলিম সেই ব্যক্তি, যার জিহ্বা ও হাত থেকে অন্য মুসলিমরা নিরাপদ থাকে।',
      'আবদুল্লাহ ইবনু আমর (রা.)', 'বুখারী ও মুসলিম'),
];

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'হাদীস',
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: _hadiths.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i == _hadiths.length) {
            return const FootNote(
                'হাদীসগুলোর অনুবাদ সারমর্মভিত্তিক। বিস্তারিত ও পূর্ণ পাঠের জন্য নির্ভরযোগ্য হাদীসগ্রন্থ দেখুন।');
          }
          final h = _hadiths[i];
          return GlassCard(
            blur: 0,
            opacity: 0.10,
            radius: 20,
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.text, style: const TextStyle(fontSize: 17, height: 1.5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text('${h.narrator} · ${h.source}',
                          style: const TextStyle(fontSize: 13, color: kGold)),
                    ),
                    IconButton(
                      tooltip: 'কপি',
                      icon: Icon(Icons.copy_rounded, size: 20, color: wh(.8)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text: '${h.text}\n— ${h.narrator}, ${h.source}'));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('কপি হয়েছে'), duration: Duration(seconds: 1)));
                      },
                    ),
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

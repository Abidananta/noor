import '../i18n.dart';
import 'package:flutter/material.dart';
import '../ui/glass.dart';
import 'common.dart';

class _Letter {
  final String ar;
  final String bn;
  const _Letter(this.ar, this.bn);
}

const _letters = <_Letter>[
  _Letter('ا', 'আলিফ'),
  _Letter('ب', 'বা'),
  _Letter('ت', 'তা'),
  _Letter('ث', 'ছা'),
  _Letter('ج', 'জীম'),
  _Letter('ح', 'হা'),
  _Letter('خ', 'খা'),
  _Letter('د', 'দাল'),
  _Letter('ذ', 'যাল'),
  _Letter('ر', 'রা'),
  _Letter('ز', 'যা'),
  _Letter('س', 'সীন'),
  _Letter('ش', 'শীন'),
  _Letter('ص', 'ছোয়াদ'),
  _Letter('ض', 'দোয়াদ'),
  _Letter('ط', 'তোয়া'),
  _Letter('ظ', 'যোয়া'),
  _Letter('ع', 'আইন'),
  _Letter('غ', 'গাইন'),
  _Letter('ف', 'ফা'),
  _Letter('ق', 'ক্বাফ'),
  _Letter('ك', 'কাফ'),
  _Letter('ل', 'লাম'),
  _Letter('م', 'মীম'),
  _Letter('ن', 'নূন'),
  _Letter('و', 'ওয়াও'),
  _Letter('ه', 'হা'),
  _Letter('ء', 'হামযা'),
  _Letter('ي', 'ইয়া'),
];

class _Mark {
  final String name;
  final String sign;
  final String example;
  final String sound;
  final String desc;
  const _Mark(this.name, this.sign, this.example, this.sound, this.desc);
}

const _marks = <_Mark>[
  _Mark('যবর', 'َ', 'بَ', 'বা', 'হরফের উপরে বসে; "আ"-ধ্বনি দেয়।'),
  _Mark('যের', 'ِ', 'بِ', 'বি', 'হরফের নিচে বসে; "ই"-ধ্বনি দেয়।'),
  _Mark('পেশ', 'ُ', 'بُ', 'বু', 'হরফের উপরে বসে; "উ"-ধ্বনি দেয়।'),
  _Mark('সুকূন', 'ْ', 'بْ', 'ব্', 'হরফকে স্বরহীন করে; পূর্বের হরফের সাথে মিলিয়ে পড়তে হয়।'),
  _Mark('তাশদীদ', 'ّ', 'بَّ', 'ব্বা', 'হরফকে দ্বিত্ব করে; জোর দিয়ে দুইবার পড়ার মতো উচ্চারণ।'),
  _Mark('তানবীন (যবর)', 'ً', 'بًا', 'বান', 'শেষে "আন"-ধ্বনি যোগ করে।'),
  _Mark('তানবীন (যের)', 'ٍ', 'بٍ', 'বিন', 'শেষে "ইন"-ধ্বনি যোগ করে।'),
  _Mark('তানবীন (পেশ)', 'ٌ', 'بٌ', 'বুন', 'শেষে "উন"-ধ্বনি যোগ করে।'),
];

class QuranShikkhaScreen extends StatelessWidget {
  const QuranShikkhaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: GlassPage(
        title: tr('f_qshikkha'),
        bottom: const TabBar(
          indicatorColor: kGold,
          tabs: [Tab(text: 'আরবি হরফ'), Tab(text: 'হরকত ও চিহ্ন')],
        ),
        body: const TabBarView(children: [_LettersTab(), _MarksTab()]),
      ),
    );
  }
}

class _LettersTab extends StatelessWidget {
  const _LettersTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('আরবি বর্ণমালা — ডান থেকে বামে পড়া হয়। হরফে ট্যাপ করে বড় করে দেখুন।',
            style: TextStyle(color: wh(.75), height: 1.4)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            for (final l in _letters)
              GlassCard(
                blur: 0,
                radius: 18,
                opacity: 0.10,
                padding: const EdgeInsets.all(6),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: panelColor,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l.ar,
                            style: const TextStyle(fontSize: 96, color: kGold, height: 1.3)),
                        Text(l.bn,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l.ar, style: const TextStyle(fontSize: 34, color: kGold, height: 1.3)),
                    const SizedBox(height: 2),
                    Text(l.bn, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
        const FootNote(
            'সঠিক মাখরাজ ও উচ্চারণ শেখার জন্য একজন যোগ্য উস্তাদ বা ক্বারীর কাছে শুনে শেখা জরুরি।'),
      ],
    );
  }
}

class _MarksTab extends StatelessWidget {
  const _MarksTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _marks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final m = _marks[i];
        return GlassCard(
          blur: 0,
          radius: 18,
          opacity: 0.10,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Column(
                  children: [
                    Text(m.example,
                        style: const TextStyle(fontSize: 36, color: kGold, height: 1.5)),
                    Text(m.sound, style: TextStyle(fontSize: 13, color: wh(.8))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(m.desc, style: TextStyle(fontSize: 14, height: 1.4, color: wh(.82))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

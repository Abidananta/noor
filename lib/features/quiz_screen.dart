import '../i18n.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../ui/glass.dart';
import 'common.dart';

class _Q {
  final String q;
  final List<String> options;
  final int answer;
  const _Q(this.q, this.options, this.answer);
}

const _bank = <_Q>[
  _Q('ইসলামের মূল স্তম্ভ কয়টি?', ['৩টি', '৪টি', '৫টি', '৬টি'], 2),
  _Q('কুরআনে মোট সূরা কয়টি?', ['১১০টি', '১১২টি', '১১৪টি', '১২০টি'], 2),
  _Q('কুরআনের সবচেয়ে বড় সূরা কোনটি?', ['আলে ইমরান', 'আল-বাকারা', 'আন-নিসা', 'আল-আ\'রাফ'], 1),
  _Q('সূরা আল-ফাতিহার আয়াত সংখ্যা কত?', ['৫', '৬', '৭', '৮'], 2),
  _Q('কুরআনের প্রথম নাযিল হওয়া আয়াতগুলো কোন সূরার?', ['আল-ফাতিহা', 'আল-আলাক', 'আল-মুদ্দাসসির', 'আল-বাকারা'], 1),
  _Q('দিনে ফরয নামায কত ওয়াক্ত?', ['৩', '৪', '৫', '৬'], 2),
  _Q('হিজরী সনের প্রথম মাস কোনটি?', ['রামাযান', 'মুহাররম', 'রজব', 'শাওয়াল'], 1),
  _Q('যে রাত হাজার মাসের চেয়ে উত্তম, সেটি কোন রাত?', ['শবে বরাত', 'লাইলাতুল কদর', 'আশুরার রাত', 'জুমআর রাত'], 1),
  _Q('কাবা শরীফ কোন শহরে অবস্থিত?', ['মদীনা', 'জেদ্দা', 'মক্কা', 'তায়েফ'], 2),
  _Q('রাসূলুল্লাহ ﷺ মক্কা থেকে কোথায় হিজরত করেন?', ['তায়েফ', 'মদীনা', 'হাবশা', 'জেরুজালেম'], 1),
  _Q('সাধারণ যাকাতের হার কত?', ['২.৫%', '৫%', '১০%', '২০%'], 0),
  _Q('কোন নবীকে আল্লাহ "খলীল" (অন্তরঙ্গ বন্ধু) বলেছেন?', ['মূসা (আ.)', 'ঈসা (আ.)', 'ইবরাহীম (আ.)', 'নূহ (আ.)'], 2),
  _Q('প্রথম নবী কে?', ['নূহ (আ.)', 'আদম (আ.)', 'ইদরীস (আ.)', 'ইবরাহীম (আ.)'], 1),
  _Q('ঈদুল ফিতর কোন হিজরী মাসের প্রথম দিনে?', ['রামাযান', 'শাওয়াল', 'যিলহজ্জ', 'শা\'বান'], 1),
  _Q('শেষ নবী কে?', ['ঈসা (আ.)', 'ইবরাহীম (আ.)', 'মূসা (আ.)', 'মুহাম্মাদ ﷺ'], 3),
];

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<_Q> _qs;
  int _i = 0;
  int _score = 0;
  int? _picked;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _qs = List<_Q>.of(_bank)..shuffle(Random());
    _i = 0;
    _score = 0;
    _picked = null;
  }

  void _pick(int idx) {
    if (_picked != null) return;
    setState(() {
      _picked = idx;
      if (idx == _qs[_i].answer) _score++;
    });
  }

  void _next() => setState(() {
        _i++;
        _picked = null;
      });

  @override
  Widget build(BuildContext context) {
    final done = _i >= _qs.length;
    return GlassPage(
      title: tr('f_quiz'),
      body: done ? _result() : _question(),
    );
  }

  Widget _result() {
    final pct = (_score * 100 / _qs.length).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, size: 56, color: kGold),
              const SizedBox(height: 12),
              Text(bnDigits('$_score / ${_qs.length}'),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(bnDigits('$pct% সঠিক'), style: TextStyle(fontSize: 16, color: wh(.8))),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => setState(_reset),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('আবার খেলুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _question() {
    final q = _qs[_i];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        Text(bnDigits('প্রশ্ন ${_i + 1} / ${_qs.length}'),
            style: TextStyle(color: wh(.7))),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _i / _qs.length,
            minHeight: 8,
            backgroundColor: wh(.16),
            color: kMint,
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          blur: 0,
          padding: const EdgeInsets.all(18),
          child: Text(q.q,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4)),
        ),
        const SizedBox(height: 14),
        for (int k = 0; k < q.options.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _option(q, k),
          ),
        if (_picked != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: FilledButton(
              onPressed: _next,
              child: Text(_i == _qs.length - 1 ? 'ফলাফল দেখুন' : 'পরবর্তী প্রশ্ন'),
            ),
          ),
      ],
    );
  }

  Widget _option(_Q q, int k) {
    Color? tint;
    IconData? icon;
    if (_picked != null) {
      if (k == q.answer) {
        tint = const Color(0xFF34D399);
        icon = Icons.check_circle_rounded;
      } else if (k == _picked) {
        tint = const Color(0xFFF87171);
        icon = Icons.cancel_rounded;
      }
    }
    return GlassCard(
      blur: 0,
      radius: 18,
      tint: tint,
      opacity: tint != null ? 0.22 : 0.10,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => _pick(k),
      child: Row(
        children: [
          Expanded(child: Text(q.options[k], style: const TextStyle(fontSize: 17))),
          if (icon != null) Icon(icon, color: tint),
        ],
      ),
    );
  }
}

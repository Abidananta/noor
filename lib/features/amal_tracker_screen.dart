import '../i18n.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/glass.dart';
import 'common.dart';

class _Amal {
  final String id;
  final String label;
  final IconData icon;
  const _Amal(this.id, this.label, this.icon);
}

const _amals = <_Amal>[
  _Amal('fajr', 'ফজরের নামায', Icons.nights_stay_rounded),
  _Amal('dhuhr', 'যোহরের নামায', Icons.wb_sunny_rounded),
  _Amal('asr', 'আসরের নামায', Icons.wb_sunny_outlined),
  _Amal('maghrib', 'মাগরিবের নামায', Icons.wb_twilight_rounded),
  _Amal('isha', 'ইশার নামায', Icons.bedtime_rounded),
  _Amal('quran', 'কুরআন তিলাওয়াত', Icons.menu_book_rounded),
  _Amal('adhkar', 'সকাল-সন্ধ্যার যিকির', Icons.auto_awesome_rounded),
  _Amal('istighfar', 'ইস্তিগফার', Icons.favorite_rounded),
  _Amal('sadaqah', 'সদাকা', Icons.volunteer_activism_rounded),
];

const _dayNames = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি', 'রবি'];

String _key(DateTime d) =>
    'amal_${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class AmalTrackerScreen extends StatefulWidget {
  const AmalTrackerScreen({super.key});

  @override
  State<AmalTrackerScreen> createState() => _AmalTrackerScreenState();
}

class _AmalTrackerScreenState extends State<AmalTrackerScreen> {
  // index 0 = today, 1 = yesterday, ...
  final List<DateTime> _days = [];
  final List<Set<String>> _done = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < 7; i++) {
      final d = today.subtract(Duration(days: i));
      _days.add(d);
      _done.add((p.getStringList(_key(d)) ?? <String>[]).toSet());
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _toggle(String id) async {
    setState(() {
      if (!_done[0].remove(id)) _done[0].add(id);
    });
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key(_days[0]), _done[0].toList());
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return GlassPage(title: tr('f_amal'), body: const Center(child: CircularProgressIndicator()));
    }
    final total = _amals.length;
    final todayCount = _done[0].length;

    return GlassPage(
      title: tr('f_amal'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          GlassCard(
            blur: 0,
            tint: kGold,
            opacity: 0.12,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('আজকের অগ্রগতি', style: TextStyle(color: wh(.75))),
                const SizedBox(height: 6),
                Text(bnDigits('$todayCount / $total'),
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: todayCount / total,
                    minHeight: 10,
                    backgroundColor: wh(.16),
                    color: kGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            blur: 0,
            opacity: 0.10,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 6; i >= 0; i--)
                  Column(
                    children: [
                      Text(_dayNames[_days[i].weekday - 1],
                          style: TextStyle(fontSize: 12, color: wh(.7))),
                      const SizedBox(height: 6),
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: _done[i].length == total
                            ? kMint
                            : (_done[i].isEmpty ? wh(.12) : kGold.withOpacity(.55)),
                        child: Text(bnDigits('${_done[i].length}'),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _done[i].length == total
                                    ? const Color(0xFF052A21)
                                    : Colors.white)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final a in _amals)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                blur: 0,
                radius: 18,
                opacity: _done[0].contains(a.id) ? 0.20 : 0.10,
                tint: _done[0].contains(a.id) ? kMint : null,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () => _toggle(a.id),
                child: Row(
                  children: [
                    Icon(a.icon, color: _done[0].contains(a.id) ? kMint : wh(.75)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(a.label, style: const TextStyle(fontSize: 17))),
                    Icon(
                      _done[0].contains(a.id)
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _done[0].contains(a.id) ? kMint : wh(.55),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

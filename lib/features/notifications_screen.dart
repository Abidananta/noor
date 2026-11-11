import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n.dart';
import '../ui/glass.dart';
import 'common.dart';
import 'prayer_times_screen.dart';

/// Day (Bangladesh date, yyyy-mm-dd) whose notifications the user last opened.
final ValueNotifier<String> notifSeenDay = ValueNotifier<String>('');

String todayKey() {
  final b = DateTime.now().toUtc().add(const Duration(hours: 6));
  return '${b.year}-${b.month.toString().padLeft(2, '0')}-${b.day.toString().padLeft(2, '0')}';
}

Future<void> loadNotifSeen() async {
  try {
    final p = await SharedPreferences.getInstance();
    notifSeenDay.value = p.getString('notif_seen_day') ?? '';
  } catch (_) {}
}

Future<void> markNotifSeen() async {
  final k = todayKey();
  notifSeenDay.value = k;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setString('notif_seen_day', k);
  } catch (_) {}
}

/// In-app notification centre: next prayer, today's prayer times and reminders.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    markNotifSeen();
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      );

  Widget _item(IconData icon, Color color, String title, String body, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        blur: 0,
        radius: 18,
        opacity: 0.10,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: color.withOpacity(.18),
                border: Border.all(color: color.withOpacity(.45)),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                  if (body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(body, style: TextStyle(fontSize: 13.5, height: 1.4, color: wh(.75))),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(trailing, style: TextStyle(fontSize: 12.5, color: wh(.7))),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: tr('nav_notif'),
      body: ValueListenableBuilder<int>(
        valueListenable: cityIndex,
        builder: (context, ci, _) {
          final c = kCities[ci];
          final nowUtc = DateTime.now().toUtc();
          final bd = nowUtc.add(const Duration(hours: 6));
          final t = computePrayerTimes(bd.year, bd.month, bd.day, c.lat, c.lng);
          final nb = bd.add(const Duration(days: 1));
          final n = computePrayerTimes(nb.year, nb.month, nb.day, c.lat, c.lng);

          final rows = <(String, DateTime, IconData)>[
            (tr('p_fajr'), t.fajr, Icons.nights_stay_rounded),
            (tr('p_sunrise'), t.sunrise, Icons.wb_twilight_rounded),
            (tr('p_dhuhr'), t.dhuhr, Icons.wb_sunny_rounded),
            (tr('p_asr'), t.asr, Icons.wb_sunny_outlined),
            (tr('p_maghrib'), t.maghrib, Icons.wb_twilight_rounded),
            (tr('p_isha'), t.isha, Icons.bedtime_rounded),
          ];

          // next of the five fard prayers
          String nextName = tr('p_fajr');
          DateTime nextTime = n.fajr;
          for (final r in rows) {
            if (r.$1 == tr('p_sunrise')) continue;
            if (r.$2.isAfter(nowUtc)) {
              nextName = r.$1;
              nextTime = r.$2;
              break;
            }
          }
          final isFriday = bd.weekday == DateTime.friday;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              GlassCard(
                tint: kGold,
                opacity: 0.14,
                blur: 0,
                radius: 20,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(children: [
                    Text(tr('p_next'), style: TextStyle(color: wh(.75), fontSize: 13.5)),
                    const SizedBox(height: 6),
                    Text('$nextName · ${bdTime(nextTime)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(remainText(nextTime.difference(nowUtc)),
                        style: const TextStyle(fontSize: 15, color: kMint)),
                    const SizedBox(height: 4),
                    Text('${tr('nt_in_area')}: ${c.label}',
                        style: TextStyle(fontSize: 12.5, color: wh(.6))),
                  ]),
                ),
              ),
              _sectionTitle(tr('nt_today')),
              for (final r in rows)
                _item(
                  r.$3,
                  r.$2.isAfter(nowUtc) ? kGold : kMint,
                  r.$1,
                  r.$2.isAfter(nowUtc) ? tr('nt_upcoming') : tr('nt_done'),
                  trailing: bdTime(r.$2),
                ),
              _sectionTitle(tr('nt_reminders')),
              if (isFriday)
                _item(Icons.mosque_rounded, kMint, tr('nt_jumuah_t'), tr('nt_jumuah_b')),
              _item(Icons.checklist_rounded, kGold, tr('nt_amal_t'), tr('nt_amal_b')),
              _item(Icons.menu_book_rounded, kMint, tr('nt_quran_t'), tr('nt_quran_b')),
              FootNote(tr('nt_hint')),
            ],
          );
        },
      ),
    );
  }
}

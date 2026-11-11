import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n.dart';
import '../ui/glass.dart';
import 'common.dart';

class City {
  final String name; // Bangla
  final String en; // shown for every non-Bangla language
  final double lat;
  final double lng;
  const City(this.name, this.en, this.lat, this.lng);

  String get label => appLang.value == 'bn' ? name : en;
}

const kCities = <City>[
  City('ঢাকা', 'Dhaka', 23.8103, 90.4125),
  City('চট্টগ্রাম', 'Chattogram', 22.3569, 91.7832),
  City('সিলেট', 'Sylhet', 24.8949, 91.8687),
  City('রাজশাহী', 'Rajshahi', 24.3745, 88.6042),
  City('খুলনা', 'Khulna', 22.8456, 89.5403),
  City('বরিশাল', 'Barishal', 22.7010, 90.3535),
  City('রংপুর', 'Rangpur', 25.7439, 89.2752),
  City('ময়মনসিংহ', 'Mymensingh', 24.7471, 90.4203),
];

/// Selected city index, shared by the home card, header, profile and prayer screen.
final ValueNotifier<int> cityIndex = ValueNotifier<int>(0);

Future<void> loadCity() async {
  final p = await SharedPreferences.getInstance();
  final c = p.getInt('prayer_city') ?? 0;
  if (c >= 0 && c < kCities.length) cityIndex.value = c;
}

Future<void> saveCity(int i) async {
  cityIndex.value = i;
  final p = await SharedPreferences.getInstance();
  await p.setInt('prayer_city', i);
}

/// All times are absolute instants (UTC DateTime). Display with [bdTime].
class PrayerTimes {
  final DateTime fajr, sunrise, dhuhr, asr, maghrib, isha;
  const PrayerTimes(this.fajr, this.sunrise, this.dhuhr, this.asr, this.maghrib, this.isha);
}

const double _tz = 6; // Bangladesh Standard Time (UTC+6)
const double _d2r = math.pi / 180;

double _fix(double a, double b) => a - b * (a / b).floor();

int _jdn(int y, int m, int d) {
  final a = (14 - m) ~/ 12;
  final y2 = y + 4800 - a;
  final m2 = m + 12 * a - 3;
  return d + (153 * m2 + 2) ~/ 5 + 365 * y2 + y2 ~/ 4 - y2 ~/ 100 + y2 ~/ 400 - 32045;
}

/// University of Islamic Sciences, Karachi (Fajr/Isha 18 deg) + Hanafi Asr,
/// the method commonly used in Bangladesh. Y/M/D is the Bangladesh local date.
PrayerTimes computePrayerTimes(int y, int m, int d, double lat, double lng) {
  final dd = _jdn(y, m, d) - 2451545.0;
  final g = _fix(357.529 + 0.98560028 * dd, 360);
  final q = _fix(280.459 + 0.98564736 * dd, 360);
  final l = _fix(q + 1.915 * math.sin(g * _d2r) + 0.020 * math.sin(2 * g * _d2r), 360);
  final e = 23.439 - 0.00000036 * dd;
  final ra = _fix(
      math.atan2(math.cos(e * _d2r) * math.sin(l * _d2r), math.cos(l * _d2r)) / _d2r / 15, 24);
  final eqt = q / 15 - ra;
  final decl = math.asin(math.sin(e * _d2r) * math.sin(l * _d2r)) / _d2r;
  final noon = 12 + _tz - lng / 15 - eqt;

  double clampAcos(double x) => math.acos(x < -1 ? -1.0 : (x > 1 ? 1.0 : x));
  final denom = math.cos(lat * _d2r) * math.cos(decl * _d2r);
  final base = math.sin(lat * _d2r) * math.sin(decl * _d2r);

  // hours between solar noon and the sun being [angle] degrees below the horizon
  double below(double angle) => clampAcos((-math.sin(angle * _d2r) - base) / denom) / _d2r / 15;

  // Hanafi Asr: shadow length = 2 x object + noon shadow
  final asrAlt = math.atan(1 / (2 + math.tan((lat - decl).abs() * _d2r))) / _d2r;
  final asrT = clampAcos((math.sin(asrAlt * _d2r) - base) / denom) / _d2r / 15;

  final midnightUtc = DateTime.utc(y, m, d);
  DateTime at(double hBd) =>
      midnightUtc.add(Duration(seconds: ((hBd - _tz) * 3600).round()));

  return PrayerTimes(
    at(noon - below(18)),
    at(noon - below(0.833)),
    at(noon),
    at(noon + asrT),
    at(noon + below(0.833)),
    at(noon + below(18)),
  );
}

/// Instant -> Bangladesh wall clock, e.g. "৪:৫৩ AM" in Bangla digits.
/// "৩ ঘণ্টা ১০ মিনিট বাকি" in the current language.
String remainText(Duration left) {
  final h = left.inHours;
  final m = left.inMinutes % 60;
  final s = h > 0
      ? trf('left_hm', {'h': '$h', 'm': '$m'})
      : trf('left_m', {'m': '${m < 1 ? 1 : m}'});
  return localizeDigits(s);
}

String bdTime(DateTime t) {
  final b = t.toUtc().add(const Duration(hours: 6));
  final h12 = b.hour % 12 == 0 ? 12 : b.hour % 12;
  final mm = b.minute.toString().padLeft(2, '0');
  final suffix = b.hour < 12 ? 'AM' : 'PM';
  return bnDigits('$h12:$mm $suffix');
}

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  int get _city => cityIndex.value;
  Timer? _timer;

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    cityIndex.addListener(_rebuild);
    loadCity();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    cityIndex.removeListener(_rebuild);
    _timer?.cancel();
    super.dispose();
  }

  PrayerTimes _forDate(DateTime bd) {
    final c = kCities[_city];
    return computePrayerTimes(bd.year, bd.month, bd.day, c.lat, c.lng);
  }

  @override
  Widget build(BuildContext context) {
    final nowUtc = DateTime.now().toUtc();
    final bd = nowUtc.add(const Duration(hours: 6)); // Bangladesh "now"
    final today = _forDate(bd);
    final tomorrow = _forDate(bd.add(const Duration(days: 1)));

    final rows = <(String, DateTime, IconData)>[
      (tr('p_fajr'), today.fajr, Icons.nights_stay_rounded),
      (tr('p_sunrise'), today.sunrise, Icons.wb_twilight_rounded),
      (tr('p_dhuhr'), today.dhuhr, Icons.wb_sunny_rounded),
      (tr('p_asr'), today.asr, Icons.wb_sunny_outlined),
      (tr('p_maghrib'), today.maghrib, Icons.wb_twilight_rounded),
      (tr('p_isha'), today.isha, Icons.bedtime_rounded),
    ];

    // next of the 5 fard prayers (sunrise excluded)
    String nextName = tr('p_fajr');
    DateTime nextTime = tomorrow.fajr;
    for (final r in rows) {
      if (r.$1 == tr('p_sunrise')) continue;
      if (r.$2.isAfter(nowUtc)) {
        nextName = r.$1;
        nextTime = r.$2;
        break;
      }
    }
    final diff = nextTime.difference(nowUtc);
    final remain = remainText(diff);

    return GlassPage(
      title: tr('f_prayer'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kCities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(kCities[i].label),
                selected: i == _city,
                onSelected: (_) => saveCity(i),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            tint: kGold,
            opacity: 0.14,
            blur: 16,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Text(tr('p_next'), style: TextStyle(color: wh(.75), fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('$nextName · ${bdTime(nextTime)}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(bnDigits(remain), style: const TextStyle(fontSize: 16, color: kMint)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                blur: 0,
                opacity: r.$1 == nextName ? 0.18 : 0.10,
                radius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(r.$3, color: r.$1 == nextName ? kGold : wh(.75)),
                    const SizedBox(width: 14),
                    Text(r.$1, style: const TextStyle(fontSize: 18)),
                    const Spacer(),
                    Text(bdTime(r.$2),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: r.$1 == nextName ? kGold : Colors.white)),
                  ],
                ),
              ),
            ),
          FootNote(tr('calc_note')),
        ],
      ),
    );
  }
}

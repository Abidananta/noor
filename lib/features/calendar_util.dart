import 'common.dart';

const _weekdays = ['সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'];
const _gMonths = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];
const _hMonths = [
  'মুহাররম', 'সফর', 'রবিউল আউয়াল', 'রবিউস সানি', 'জুমাদাল উলা', 'জুমাদাস সানিয়া',
  'রজব', "শা'বান", 'রমযান', 'শাওয়াল', 'যিলক্বদ', 'যিলহজ্জ',
];
const _bMonths = [
  'বৈশাখ', 'জ্যৈষ্ঠ', 'আষাঢ়', 'শ্রাবণ', 'ভাদ্র', 'আশ্বিন',
  'কার্তিক', 'অগ্রহায়ণ', 'পৌষ', 'মাঘ', 'ফাল্গুন', 'চৈত্র',
];
const _bSeasons = [
  'গ্রীষ্মকাল', 'গ্রীষ্মকাল', 'বর্ষাকাল', 'বর্ষাকাল', 'শরৎকাল', 'শরৎকাল',
  'হেমন্তকাল', 'হেমন্তকাল', 'শীতকাল', 'শীতকাল', 'বসন্তকাল', 'বসন্তকাল',
];

int _jdn(int y, int m, int d) {
  final a = (14 - m) ~/ 12;
  final y2 = y + 4800 - a;
  final m2 = m + 12 * a - 3;
  return d + (153 * m2 + 2) ~/ 5 + 365 * y2 + y2 ~/ 4 - y2 ~/ 100 + y2 ~/ 400 - 32045;
}

String weekdayBn(DateTime d) => _weekdays[d.weekday - 1];

/// "নভেম্বর ১১"
String shortDateBn(DateTime d) => '${_gMonths[d.month - 1]} ${bnDigits('${d.day}')}';

/// Tabular (arithmetical) Hijri date. Can differ by a day from local moon sighting.
String hijriBn(DateTime d) {
  final jd = _jdn(d.year, d.month, d.day);
  var l = jd - 1948440 + 10632;
  final n = (l - 1) ~/ 10631;
  l = l - 10631 * n + 354;
  final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) + (l ~/ 5670) * ((43 * l) ~/ 15238);
  l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
  final m = (24 * l) ~/ 709;
  final day = l - (709 * m) ~/ 24;
  final year = 30 * n + j - 30;
  final mi = (m - 1).clamp(0, 11).toInt();
  return bnDigits('$day ${_hMonths[mi]} $year হি.');
}

/// Bangladesh revised Bangla calendar: "২৭ কার্তিক ১৪৩৩ বঙ্গাব্দ, হেমন্তকাল"
String banglaDateBn(DateTime d) {
  final newYear = DateTime.utc(d.year, 4, 14);
  final today = DateTime.utc(d.year, d.month, d.day);
  final afterNy = !today.isBefore(newYear);
  final by = afterNy ? d.year - 593 : d.year - 594;
  final start = afterNy ? newYear : DateTime.utc(d.year - 1, 4, 14);
  final fy = afterNy ? d.year + 1 : d.year; // gregorian year in which Falgun falls
  final leap = (fy % 4 == 0 && fy % 100 != 0) || fy % 400 == 0;
  final lens = [31, 31, 31, 31, 31, 30, 30, 30, 30, 30, leap ? 31 : 30, 30];
  var off = today.difference(start).inDays;
  var mi = 0;
  for (int i = 0; i < 12; i++) {
    if (off < lens[i]) {
      mi = i;
      break;
    }
    off -= lens[i];
  }
  return '${bnDigits('${off + 1}')} ${_bMonths[mi]} ${bnDigits('$by')} বঙ্গাব্দ, ${_bSeasons[mi]}';
}

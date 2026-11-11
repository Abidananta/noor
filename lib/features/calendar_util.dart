import '../i18n.dart';
import 'common.dart';

// Names are '|' separated, keyed by language code. Missing language -> English.
const _weekdays = <String, String>{
  'bn': 'সোমবার|মঙ্গলবার|বুধবার|বৃহস্পতিবার|শুক্রবার|শনিবার|রবিবার',
  'en': 'Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday',
  'ar': 'الاثنين|الثلاثاء|الأربعاء|الخميس|الجمعة|السبت|الأحد',
  'ur': 'پیر|منگل|بدھ|جمعرات|جمعہ|ہفتہ|اتوار',
  'hi': 'सोमवार|मंगलवार|बुधवार|गुरुवार|शुक्रवार|शनिवार|रविवार',
  'tr': 'Pazartesi|Salı|Çarşamba|Perşembe|Cuma|Cumartesi|Pazar',
  'id': 'Senin|Selasa|Rabu|Kamis|Jumat|Sabtu|Minggu',
  'ms': 'Isnin|Selasa|Rabu|Khamis|Jumaat|Sabtu|Ahad',
};
const _gMonths = <String, String>{
  'bn': 'জানুয়ারি|ফেব্রুয়ারি|মার্চ|এপ্রিল|মে|জুন|জুলাই|আগস্ট|সেপ্টেম্বর|অক্টোবর|নভেম্বর|ডিসেম্বর',
  'en': 'January|February|March|April|May|June|July|August|September|October|November|December',
  'ar': 'يناير|فبراير|مارس|أبريل|مايو|يونيو|يوليو|أغسطس|سبتمبر|أكتوبر|نوفمبر|ديسمبر',
  'ur': 'جنوری|فروری|مارچ|اپریل|مئی|جون|جولائی|اگست|ستمبر|اکتوبر|نومبر|دسمبر',
  'hi': 'जनवरी|फ़रवरी|मार्च|अप्रैल|मई|जून|जुलाई|अगस्त|सितंबर|अक्टूबर|नवंबर|दिसंबर',
  'tr': 'Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık',
  'id': 'Januari|Februari|Maret|April|Mei|Juni|Juli|Agustus|September|Oktober|November|Desember',
  'ms': 'Januari|Februari|Mac|April|Mei|Jun|Julai|Ogos|September|Oktober|November|Disember',
};
const _hMonths = <String, String>{
  'bn': "মুহাররম|সফর|রবিউল আউয়াল|রবিউস সানি|জুমাদাল উলা|জুমাদাস সানিয়া|রজব|শা'বান|রমযান|শাওয়াল|যিলক্বদ|যিলহজ্জ",
  'en': "Muharram|Safar|Rabi' al-Awwal|Rabi' al-Thani|Jumada al-Ula|Jumada al-Akhirah|Rajab|Sha'ban|Ramadan|Shawwal|Dhu al-Qi'dah|Dhu al-Hijjah",
  'ar': 'المحرم|صفر|ربيع الأول|ربيع الآخر|جمادى الأولى|جمادى الآخرة|رجب|شعبان|رمضان|شوال|ذو القعدة|ذو الحجة',
  'ur': 'محرم|صفر|ربیع الاول|ربیع الثانی|جمادی الاول|جمادی الثانی|رجب|شعبان|رمضان|شوال|ذیقعدہ|ذوالحجہ',
  'hi': 'मुहर्रम|सफ़र|रबीउल अव्वल|रबीउस सानी|जमादिल अव्वल|जमादिस सानी|रजब|शाबान|रमज़ान|शव्वाल|ज़ीक़ादा|ज़ुल हिज्जा',
  'tr': 'Muharrem|Safer|Rebiülevvel|Rebiülahir|Cemaziyelevvel|Cemaziyelahir|Recep|Şaban|Ramazan|Şevval|Zilkade|Zilhicce',
  'id': "Muharram|Safar|Rabiul Awal|Rabiul Akhir|Jumadil Awal|Jumadil Akhir|Rajab|Sya'ban|Ramadan|Syawal|Dzulqa'dah|Dzulhijjah",
  'ms': 'Muharram|Safar|Rabiulawal|Rabiulakhir|Jamadilawal|Jamadilakhir|Rejab|Syaaban|Ramadan|Syawal|Zulkaedah|Zulhijjah',
};

List<String> _names(Map<String, String> m) => (m[appLang.value] ?? m['en']!).split('|');

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

String weekdayBn(DateTime d) => _names(_weekdays)[d.weekday - 1];

/// "নভেম্বর ১১"
String shortDateBn(DateTime d) => '${_names(_gMonths)[d.month - 1]} ${bnDigits('${d.day}')}';

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
  return bnDigits('$day ${_names(_hMonths)[mi]} $year ${tr('hijri_suffix')}');
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

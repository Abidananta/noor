import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/glass.dart' show panelColor;

/// Language order used by every row in [_t] below:
/// bn, en, ar, ur, hi, tr, id, ms
const kLangs = <(String, String)>[
  ('bn', 'বাংলা'),
  ('en', 'English'),
  ('ar', 'العربية'),
  ('ur', 'اردو'),
  ('hi', 'हिन्दी'),
  ('tr', 'Türkçe'),
  ('id', 'Bahasa Indonesia'),
  ('ms', 'Bahasa Melayu'),
];

const _rtlLangs = {'ar', 'ur'};

/// Current app language. Changing it rebuilds the whole app (see main.dart).
final ValueNotifier<String> appLang = ValueNotifier<String>('bn');

bool get isRtl => _rtlLangs.contains(appLang.value);

Future<void> loadLang() async {
  try {
    final p = await SharedPreferences.getInstance();
    final c = p.getString('app_lang');
    if (c != null && kLangs.any((l) => l.$1 == c)) appLang.value = c;
  } catch (_) {}
}

Future<void> setLang(String code) async {
  if (!kLangs.any((l) => l.$1 == code)) return;
  appLang.value = code;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setString('app_lang', code);
  } catch (_) {}
}

int get _idx {
  final i = kLangs.indexWhere((l) => l.$1 == appLang.value);
  return i < 0 ? 0 : i;
}

/// Translate [key] into the current language (falls back to Bangla, then the key).
String tr(String key) {
  final v = _t[key];
  if (v == null) return key;
  final s = _idx < v.length ? v[_idx] : '';
  return s.isEmpty ? v[0] : s;
}

/// Like [tr] but replaces {name} placeholders.
String trf(String key, Map<String, String> args) {
  var s = tr(key);
  args.forEach((k, v) => s = s.replaceAll('{$k}', v));
  return s;
}

const _digitSets = <String, String>{
  'bn': '০১২৩৪৫৬৭৮৯',
  'ar': '٠١٢٣٤٥٦٧٨٩',
  'ur': '۰۱۲۳۴۵۶۷۸۹',
  'hi': '०१२३४५६७८९',
};

/// Converts 0-9 to the digits of the current language (no change for en/tr/id/ms).
String localizeDigits(String s) {
  final set = _digitSets[appLang.value];
  if (set == null) return s;
  final d = set.runes.map((r) => String.fromCharCode(r)).toList();
  return s.replaceAllMapped(RegExp(r'[0-9]'), (m) => d[int.parse(m[0]!)]);
}

/// Bottom sheet listing every language.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: panelColor,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(tr('choose_lang'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final l in kLangs)
              ListTile(
                title: Text(l.$2),
                trailing: l.$1 == appLang.value
                    ? const Icon(Icons.check_rounded, color: Color(0xFFF2C46D))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setLang(l.$1);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// Name of the current language in its own script.
String get currentLangName => kLangs[_idx].$2;

// Row order: bn, en, ar, ur, hi, tr, id, ms
const Map<String, List<String>> _t = {
  // ---- general ----
  'nav_notif': ['নোটিফিকেশন', 'Notifications', 'الإشعارات', 'اطلاعات', 'सूचनाएँ', 'Bildirimler', 'Notifikasi', 'Pemberitahuan'],
  'menu': ['মেনু', 'Menu', 'القائمة', 'مینو', 'मेन्यू', 'Menü', 'Menu', 'Menu'],
  'profile': ['প্রোফাইল', 'Profile', 'الملف الشخصي', 'پروفائل', 'प्रोफ़ाइल', 'Profil', 'Profil', 'Profil'],
  'sec_ilm': ['ইলম ও আমল', 'Knowledge & Worship', 'العلم والعمل', 'علم و عمل', 'इल्म और अमल', 'İlim ve Amel', 'Ilmu & Amal', 'Ilmu & Amal'],
  'sec_seba': ['সেবা', 'Services', 'الخدمات', 'خدمات', 'सेवाएँ', 'Hizmetler', 'Layanan', 'Perkhidmatan'],
  'search': ['খুঁজুন', 'Search', 'بحث', 'تلاش', 'खोजें', 'Ara', 'Cari', 'Cari'],
  'search_menu': ['মেনু খুঁজুন', 'Search menu', 'ابحث في القائمة', 'مینو تلاش کریں', 'मेन्यू खोजें', 'Menüde ara', 'Cari menu', 'Cari menu'],
  'pick_area': ['এলাকা নির্বাচন করুন', 'Select area', 'اختر المنطقة', 'علاقہ منتخب کریں', 'क्षेत्र चुनें', 'Bölge seçin', 'Pilih wilayah', 'Pilih kawasan'],
  'language': ['ভাষা', 'Language', 'اللغة', 'زبان', 'भाषा', 'Dil', 'Bahasa', 'Bahasa'],
  'choose_lang': ['ভাষা নির্বাচন করুন', 'Choose language', 'اختر اللغة', 'زبان منتخب کریں', 'भाषा चुनें', 'Dil seçin', 'Pilih bahasa', 'Pilih bahasa'],
  'delete': ['মুছুন', 'Delete', 'حذف', 'حذف کریں', 'मिटाएँ', 'Sil', 'Hapus', 'Padam'],
  'cancel': ['বাতিল', 'Cancel', 'إلغاء', 'منسوخ کریں', 'रद्द करें', 'İptal', 'Batal', 'Batal'],
  'save': ['সংরক্ষণ', 'Save', 'حفظ', 'محفوظ کریں', 'सहेजें', 'Kaydet', 'Simpan', 'Simpan'],
  'no': ['না', 'No', 'لا', 'نہیں', 'नहीं', 'Hayır', 'Tidak', 'Tidak'],
  'yes_delete': ['হ্যাঁ, মুছুন', 'Yes, delete', 'نعم، احذف', 'ہاں، حذف کریں', 'हाँ, मिटाएँ', 'Evet, sil', 'Ya, hapus', 'Ya, padam'],

  // ---- menu items (f_<id>) ----
  'f_quran': ['কুরআন', 'Quran', 'القرآن', 'قرآن', 'क़ुरआन', "Kur'an", "Al-Qur'an", 'Al-Quran'],
  'f_hadith': ['হাদীস', 'Hadith', 'الحديث', 'حدیث', 'हदीस', 'Hadis', 'Hadis', 'Hadis'],
  'f_prayer': ['নামাযের সময়', 'Prayer Times', 'مواقيت الصلاة', 'نماز کے اوقات', 'नमाज़ का समय', 'Namaz Vakitleri', 'Waktu Salat', 'Waktu Solat'],
  'f_tilawat': ['তিলাওয়াত', 'Recitation', 'التلاوة', 'تلاوت', 'तिलावत', 'Tilavet', 'Tilawah', 'Tilawah'],
  'f_kitab': ['কিতাব', 'Books', 'الكتب', 'کتابیں', 'किताबें', 'Kitaplar', 'Kitab', 'Kitab'],
  'f_gazal': ['গজল', 'Nasheed', 'الأناشيد', 'ناشید', 'नशीद', 'İlahiler', 'Nasyid', 'Nasyid'],
  'f_qshikkha': ['কুরআন শিক্ষা', 'Learn Quran', 'تعلّم القرآن', 'قرآن سیکھیں', 'क़ुरआन सीखें', "Kur'an Öğren", "Belajar Al-Qur'an", 'Belajar Al-Quran'],
  'f_dua': ["দু'আ", 'Duas', 'الأدعية', 'دعائیں', 'दुआएँ', 'Dualar', 'Doa', 'Doa'],
  'f_quiz': ['তালীমে কুইজ', 'Islamic Quiz', 'اختبار تعليمي', 'تعلیمی کوئز', 'तालीमी क्विज़', 'Bilgi Yarışması', 'Kuis Islami', 'Kuiz Islam'],
  'f_amal': ['আমল ট্রাকার', 'Amal Tracker', 'متتبع الأعمال', 'عمل ٹریکر', 'अमल ट्रैकर', 'Amel Takibi', 'Pelacak Amal', 'Penjejak Amal'],
  'f_ai': ['AI জিজ্ঞাসা', 'Ask AI', 'اسأل الذكاء الاصطناعي', 'AI سے پوچھیں', 'AI से पूछें', 'Yapay Zekâya Sor', 'Tanya AI', 'Tanya AI'],
  'f_bibaho': ['বিবাহ', 'Marriage', 'الزواج', 'نکاح', 'निकाह', 'Evlilik', 'Pernikahan', 'Perkahwinan'],

  // ---- banners ----
  'b_discount': ['মাস শেষে\nবিশেষ ছাড়', 'Month-end\nspecial offer', 'عرض خاص\nنهاية الشهر', 'مہینے کے آخر میں\nخصوصی رعایت', 'महीने के अंत में\nविशेष छूट', 'Ay sonu\nözel indirim', 'Diskon spesial\nakhir bulan', 'Tawaran istimewa\nakhir bulan'],
  'b_ramadan': ['রমযানের\nপ্রস্তুতি', 'Getting ready\nfor Ramadan', 'الاستعداد\nلرمضان', 'رمضان کی\nتیاری', 'रमज़ान की\nतैयारी', 'Ramazan\nHazırlığı', 'Persiapan\nRamadan', 'Persediaan\nRamadan'],
  'b_course': ['কুরআন শিক্ষা\nকোর্স', 'Quran learning\ncourse', 'دورة تعلّم\nالقرآن', 'قرآن سیکھنے\nکا کورس', 'क़ुरआन सीखने\nका कोर्स', "Kur'an öğrenme\nkursu", "Kursus belajar\nAl-Qur'an", 'Kursus belajar\nAl-Quran'],
  'b_newkitab': ['নতুন কিতাব\nএসেছে', 'New books\nhave arrived', 'وصلت كتب\nجديدة', 'نئی کتابیں\nآ گئیں', 'नई किताबें\nआ गई हैं', 'Yeni kitaplar\ngeldi', 'Kitab baru\ntelah tiba', 'Kitab baharu\ntelah tiba'],

  // ---- prayer ----
  'p_fajr': ['ফজর', 'Fajr', 'الفجر', 'فجر', 'फ़ज्र', 'Sabah', 'Subuh', 'Subuh'],
  'p_sunrise': ['সূর্যোদয়', 'Sunrise', 'الشروق', 'طلوعِ آفتاب', 'सूर्योदय', 'Güneş', 'Terbit', 'Syuruk'],
  'p_dhuhr': ['যোহর', 'Dhuhr', 'الظهر', 'ظہر', 'ज़ुहर', 'Öğle', 'Zuhur', 'Zohor'],
  'p_asr': ['আসর', 'Asr', 'العصر', 'عصر', 'अस्र', 'İkindi', 'Asar', 'Asar'],
  'p_maghrib': ['মাগরিব', 'Maghrib', 'المغرب', 'مغرب', 'मग़रिब', 'Akşam', 'Magrib', 'Maghrib'],
  'p_isha': ['ইশা', 'Isha', 'العشاء', 'عشاء', 'इशा', 'Yatsı', 'Isya', 'Isyak'],
  'p_ends': ['{p} শেষ', '{p} ends', 'نهاية {p}', '{p} ختم', '{p} समाप्त', '{p} bitiyor', '{p} berakhir', '{p} tamat'],
  'p_dhuhr_start': ['যোহর শুরু', 'Dhuhr begins', 'بداية الظهر', 'ظہر شروع', 'ज़ुहर शुरू', 'Öğle başlıyor', 'Zuhur dimulai', 'Zohor bermula'],
  'p_none': ['এখন ওয়াক্ত নেই', 'No prayer time now', 'لا وقت صلاة الآن', 'اس وقت کوئی نماز نہیں', 'अभी कोई वक़्त नहीं', 'Şu an vakit yok', 'Belum ada waktu salat', 'Tiada waktu solat'],
  'p_running': ['চলমান', 'Ongoing', 'جارٍ', 'جاری', 'जारी', 'Devam ediyor', 'Berlangsung', 'Sedang berlangsung'],
  'p_next': ['পরবর্তী ওয়াক্ত', 'Next prayer', 'الصلاة التالية', 'اگلی نماز', 'अगली नमाज़', 'Sonraki vakit', 'Waktu salat berikutnya', 'Waktu solat seterusnya'],
  'left_hm': ['{h} ঘণ্টা {m} মিনিট বাকি', '{h}h {m}m left', 'متبقي {h} س {m} د', '{h} گھنٹے {m} منٹ باقی', '{h} घंटे {m} मिनट बाकी', '{h} sa {m} dk kaldı', 'sisa {h} jam {m} mnt', '{h} jam {m} min lagi'],
  'left_m': ['{m} মিনিট বাকি', '{m} min left', 'متبقي {m} د', '{m} منٹ باقی', '{m} मिनट बाकी', '{m} dk kaldı', 'sisa {m} mnt', '{m} min lagi'],
  'calc_note': [
    'গণনা: ইউনিভার্সিটি অব ইসলামিক সায়েন্সেস, করাচি পদ্ধতি (ফজর/ইশা ১৮°), হানাফী আসর। সময় বাংলাদেশ মান সময় (UTC+৬) অনুযায়ী; স্থানীয় মসজিদের জামাআতের সময়ের সাথে সামান্য ব্যবধান হতে পারে।',
    "Calculation: University of Islamic Sciences, Karachi method (Fajr/Isha 18°), Hanafi Asr. Times follow Bangladesh Standard Time (UTC+6); they may differ slightly from your local mosque's jama'at times.",
    'الحساب: طريقة جامعة العلوم الإسلامية بكراتشي (الفجر/العشاء 18°)، العصر حنفي. التوقيت حسب توقيت بنغلاديش (UTC+6) وقد يختلف قليلًا عن أوقات جماعة المسجد المحلي.',
    'حساب: یونیورسٹی آف اسلامک سائنسز کراچی کا طریقہ (فجر/عشاء 18°)، حنفی عصر۔ وقت بنگلہ دیش معیاری وقت (UTC+6) کے مطابق ہے؛ مقامی مسجد کی جماعت کے وقت سے معمولی فرق ہو سکتا ہے۔',
    'गणना: यूनिवर्सिटी ऑफ़ इस्लामिक साइंसेज़, कराची पद्धति (फ़ज्र/इशा 18°), हनफ़ी अस्र। समय बांग्लादेश मानक समय (UTC+6) के अनुसार है; स्थानीय मस्जिद की जमात के समय से थोड़ा अंतर हो सकता है।',
    'Hesaplama: Karaçi İslami Bilimler Üniversitesi yöntemi (Sabah/Yatsı 18°), Hanefi ikindi. Saatler Bangladeş saatine (UTC+6) göredir; yerel caminin cemaat saatinden küçük farklar olabilir.',
    'Perhitungan: metode University of Islamic Sciences, Karachi (Subuh/Isya 18°), Asar Hanafi. Waktu mengikuti Waktu Standar Bangladesh (UTC+6); bisa sedikit berbeda dengan jadwal jamaah masjid setempat.',
    'Pengiraan: kaedah University of Islamic Sciences, Karachi (Subuh/Isyak 18°), Asar Hanafi. Waktu mengikut Waktu Piawai Bangladesh (UTC+6); mungkin berbeza sedikit daripada waktu jemaah masjid tempatan.',
  ],

  // ---- profile ----
  'pf_name_title': ['আপনার নাম', 'Your name', 'اسمك', 'آپ کا نام', 'आपका नाम', 'Adınız', 'Nama Anda', 'Nama anda'],
  'pf_name_hint': ['নাম লিখুন', 'Enter name', 'أدخل الاسم', 'نام لکھیں', 'नाम लिखें', 'Adınızı yazın', 'Masukkan nama', 'Masukkan nama'],
  'pf_set_name': ['আপনার নাম দিন', 'Set your name', 'أدخل اسمك', 'اپنا نام درج کریں', 'अपना नाम डालें', 'Adınızı girin', 'Isi nama Anda', 'Isi nama anda'],
  'pf_reset_title': ['সব ডেটা মুছবেন?', 'Delete all data?', 'حذف جميع البيانات؟', 'تمام ڈیٹا حذف کریں؟', 'सारा डेटा मिटाएँ?', 'Tüm veriler silinsin mi?', 'Hapus semua data?', 'Padam semua data?'],
  'pf_reset_body': [
    'বুকমার্ক, আমল ট্রাকার, কিতাবের তালিকা, API কী ও সেটিংস স্থায়ীভাবে মুছে যাবে।',
    'Bookmarks, amal tracker, book list, API key and settings will be permanently deleted.',
    'سيتم حذف العلامات وتتبع الأعمال وقائمة الكتب ومفتاح API والإعدادات نهائيًا.',
    'بک مارکس، عمل ٹریکر، کتابوں کی فہرست، API کلید اور سیٹنگز ہمیشہ کے لیے حذف ہو جائیں گی۔',
    'बुकमार्क, अमल ट्रैकर, किताबों की सूची, API कुंजी और सेटिंग्स हमेशा के लिए मिट जाएँगी।',
    'Yer imleri, amel takibi, kitap listesi, API anahtarı ve ayarlar kalıcı olarak silinecek.',
    'Bookmark, pelacak amal, daftar kitab, kunci API, dan pengaturan akan dihapus permanen.',
    'Penanda, penjejak amal, senarai kitab, kunci API dan tetapan akan dipadam secara kekal.',
  ],
  'pf_deleted': ['ডেটা মুছে ফেলা হয়েছে', 'Data deleted', 'تم حذف البيانات', 'ڈیٹا حذف ہو گیا', 'डेटा मिटा दिया गया', 'Veriler silindi', 'Data dihapus', 'Data dipadam'],
  'pf_today_amal': ['আজকের আমল', "Today's amal", 'أعمال اليوم', 'آج کے اعمال', 'आज के अमल', 'Bugünkü amel', 'Amal hari ini', 'Amal hari ini'],
  'pf_streak': ['দিনের ধারা', 'Day streak', 'أيام متتالية', 'مسلسل دن', 'लगातार दिन', 'Gün serisi', 'Hari beruntun', 'Hari berturut-turut'],
  'pf_bookmarks': ['বুকমার্ক', 'Bookmarks', 'العلامات', 'بک مارکس', 'बुकमार्क', 'Yer imleri', 'Bookmark', 'Penanda'],
  'pf_books_done': ['কিতাব পড়া শেষ', 'Books finished', 'كتب مكتملة', 'مکمل کتابیں', 'पढ़ी हुई किताबें', 'Biten kitaplar', 'Kitab selesai', 'Kitab selesai'],
  'pf_last_surah': ['শেষ পড়া সূরা', 'Last read surah', 'آخر سورة قرأتها', 'آخری پڑھی سورت', 'आख़िरी पढ़ी सूरह', 'Son okunan sure', 'Surah terakhir dibaca', 'Surah terakhir dibaca'],
  'pf_shortcuts': ['শর্টকাট', 'Shortcuts', 'اختصارات', 'شارٹ کٹس', 'शॉर्टकट', 'Kısayollar', 'Pintasan', 'Pintasan'],
  'pf_quran_bm': ['কুরআনের বুকমার্ক', 'Quran bookmarks', 'علامات القرآن', 'قرآن کے بک مارکس', 'क़ुरआन बुकमार्क', "Kur'an yer imleri", "Bookmark Al-Qur'an", 'Penanda Al-Quran'],
  'pf_area': ['এলাকা (নামাযের সময়ের জন্য)', 'Area (for prayer times)', 'المنطقة (لمواقيت الصلاة)', 'علاقہ (نماز کے اوقات کے لیے)', 'क्षेत्र (नमाज़ के समय के लिए)', 'Bölge (namaz vakitleri için)', 'Wilayah (untuk waktu salat)', 'Kawasan (untuk waktu solat)'],
  'pf_app': ['অ্যাপ', 'App', 'التطبيق', 'ایپ', 'ऐप', 'Uygulama', 'Aplikasi', 'Aplikasi'],
  'pf_about': ['নূর অ্যাপ সম্পর্কে', 'About Noor app', 'حول تطبيق نور', 'نور ایپ کے بارے میں', 'नूर ऐप के बारे में', 'Noor uygulaması hakkında', 'Tentang aplikasi Noor', 'Tentang aplikasi Noor'],
  'pf_about_body': [
    'বাংলা ইসলামিক অ্যাপ।\n\nকুরআনের বাংলা অনুবাদ: মুহিউদ্দীন খান (tanzil.net)।',
    'A Bangla Islamic app.\n\nQuran Bangla translation: Muhiuddin Khan (tanzil.net).',
    'تطبيق إسلامي باللغة البنغالية.\n\nترجمة القرآن إلى البنغالية: محيي الدين خان (tanzil.net).',
    'بنگلہ اسلامی ایپ۔\n\nقرآن کا بنگلہ ترجمہ: محی الدین خان (tanzil.net)۔',
    'बांग्ला इस्लामिक ऐप।\n\nक़ुरआन का बांग्ला अनुवाद: मुहिउद्दीन ख़ान (tanzil.net)।',
    "Bengalce İslami uygulama.\n\nKur'an'ın Bengalce meali: Muhiuddin Khan (tanzil.net).",
    "Aplikasi Islami berbahasa Bengali.\n\nTerjemahan Al-Qur'an Bengali: Muhiuddin Khan (tanzil.net).",
    'Aplikasi Islam berbahasa Bengali.\n\nTerjemahan Al-Quran Bengali: Muhiuddin Khan (tanzil.net).',
  ],
  'pf_reset': ['সব ডেটা মুছুন', 'Delete all data', 'حذف جميع البيانات', 'تمام ڈیٹا حذف کریں', 'सारा डेटा मिटाएँ', 'Tüm verileri sil', 'Hapus semua data', 'Padam semua data'],

  // ---- auth / account ----
  'auth_welcome': ['নূর-এ স্বাগতম', 'Welcome to Noor', 'مرحبًا بك في نور', 'نور میں خوش آمدید', 'नूर में आपका स्वागत है', 'Noor\'a hoş geldiniz', 'Selamat datang di Noor', 'Selamat datang ke Noor'],
  'auth_sub': ['প্রোফাইল তৈরি করে শুরু করুন', 'Create your profile to get started', 'أنشئ ملفك الشخصي للبدء', 'شروع کرنے کے لیے اپنی پروفائل بنائیں', 'शुरू करने के लिए अपनी प्रोफ़ाइल बनाएँ', 'Başlamak için profilinizi oluşturun', 'Buat profil Anda untuk memulai', 'Cipta profil anda untuk bermula'],
  'auth_sub_login': ['আপনার অ্যাকাউন্টে ঢুকুন', 'Log in to your account', 'سجّل الدخول إلى حسابك', 'اپنے اکاؤنٹ میں لاگ اِن کریں', 'अपने खाते में लॉग इन करें', 'Hesabınıza giriş yapın', 'Masuk ke akun Anda', 'Log masuk ke akaun anda'],
  'auth_register': ['রেজিস্ট্রেশন', 'Register', 'تسجيل', 'رجسٹر کریں', 'रजिस्टर करें', 'Kayıt ol', 'Daftar', 'Daftar'],
  'auth_login': ['লগইন', 'Log in', 'تسجيل الدخول', 'لاگ اِن', 'लॉग इन', 'Giriş yap', 'Masuk', 'Log masuk'],
  'auth_name': ['নাম', 'Name', 'الاسم', 'نام', 'नाम', 'Ad', 'Nama', 'Nama'],
  'auth_email': ['ইমেইল', 'Email', 'البريد الإلكتروني', 'ای میل', 'ईमेल', 'E-posta', 'Email', 'E-mel'],
  'auth_phone': ['মোবাইল নম্বর (ঐচ্ছিক)', 'Mobile number (optional)', 'رقم الجوال (اختياري)', 'موبائل نمبر (اختیاری)', 'मोबाइल नंबर (वैकल्पिक)', 'Cep telefonu (isteğe bağlı)', 'Nomor ponsel (opsional)', 'Nombor telefon (pilihan)'],
  'auth_pass': ['পাসওয়ার্ড', 'Password', 'كلمة المرور', 'پاس ورڈ', 'पासवर्ड', 'Şifre', 'Kata sandi', 'Kata laluan'],
  'auth_pass2': ['পাসওয়ার্ড আবার দিন', 'Confirm password', 'تأكيد كلمة المرور', 'پاس ورڈ دوبارہ لکھیں', 'पासवर्ड दोबारा डालें', 'Şifreyi doğrulayın', 'Konfirmasi kata sandi', 'Sahkan kata laluan'],
  'auth_google': ['গুগল দিয়ে চালিয়ে যান', 'Continue with Google', 'المتابعة باستخدام Google', 'Google کے ساتھ جاری رکھیں', 'Google से जारी रखें', 'Google ile devam et', 'Lanjutkan dengan Google', 'Teruskan dengan Google'],
  'auth_or': ['অথবা', 'or', 'أو', 'یا', 'या', 'veya', 'atau', 'atau'],
  'auth_to_login': ['আগে থেকে অ্যাকাউন্ট আছে? লগইন করুন', 'Already have an account? Log in', 'لديك حساب؟ سجّل الدخول', 'اکاؤنٹ ہے؟ لاگ اِن کریں', 'पहले से खाता है? लॉग इन करें', 'Hesabınız var mı? Giriş yapın', 'Sudah punya akun? Masuk', 'Sudah ada akaun? Log masuk'],
  'auth_to_reg': ['অ্যাকাউন্ট নেই? রেজিস্ট্রেশন করুন', 'New here? Register', 'جديد هنا؟ سجّل', 'نئے ہیں؟ رجسٹر کریں', 'नए हैं? रजिस्टर करें', 'Yeni misiniz? Kayıt olun', 'Baru di sini? Daftar', 'Baru di sini? Daftar'],
  'e_name': ['নাম লিখুন', 'Enter your name', 'أدخل اسمك', 'اپنا نام لکھیں', 'अपना नाम लिखें', 'Adınızı girin', 'Masukkan nama Anda', 'Masukkan nama anda'],
  'e_email': ['সঠিক ইমেইল দিন', 'Enter a valid email', 'أدخل بريدًا إلكترونيًا صحيحًا', 'درست ای میل لکھیں', 'सही ईमेल डालें', 'Geçerli bir e-posta girin', 'Masukkan email yang valid', 'Masukkan e-mel yang sah'],
  'e_pass': ['পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে', 'Password must be at least 6 characters', 'يجب أن تكون كلمة المرور 6 أحرف على الأقل', 'پاس ورڈ کم از کم 6 حروف کا ہو', 'पासवर्ड कम से कम 6 अक्षरों का हो', 'Şifre en az 6 karakter olmalı', 'Kata sandi minimal 6 karakter', 'Kata laluan mesti sekurang-kurangnya 6 aksara'],
  'e_match': ['দুই পাসওয়ার্ড মেলেনি', 'Passwords do not match', 'كلمتا المرور غير متطابقتين', 'پاس ورڈ مماثل نہیں', 'पासवर्ड मेल नहीं खाते', 'Şifreler eşleşmiyor', 'Kata sandi tidak cocok', 'Kata laluan tidak sepadan'],
  'e_exists': ['এই ইমেইলে আগেই অ্যাকাউন্ট আছে, লগইন করুন', 'An account with this email already exists. Please log in', 'يوجد حساب بهذا البريد بالفعل، سجّل الدخول', 'اس ای میل سے اکاؤنٹ پہلے سے موجود ہے، لاگ اِن کریں', 'इस ईमेल से खाता पहले से है, लॉग इन करें', 'Bu e-postayla zaten bir hesap var, giriş yapın', 'Akun dengan email ini sudah ada, silakan masuk', 'Akaun dengan e-mel ini sudah wujud, sila log masuk'],
  'e_cred': ['ইমেইল বা পাসওয়ার্ড ভুল', 'Wrong email or password', 'البريد أو كلمة المرور غير صحيحة', 'ای میل یا پاس ورڈ غلط ہے', 'ईमेल या पासवर्ड गलत है', 'E-posta veya şifre hatalı', 'Email atau kata sandi salah', 'E-mel atau kata laluan salah'],
  'e_googleonly': ['এই অ্যাকাউন্ট গুগল দিয়ে বানানো, "গুগল দিয়ে চালিয়ে যান" চাপুন', 'This account uses Google. Tap "Continue with Google"', 'هذا الحساب عبر Google، اضغط "المتابعة باستخدام Google"', 'یہ اکاؤنٹ Google سے ہے، "Google کے ساتھ جاری رکھیں" دبائیں', 'यह खाता Google से बना है, "Google से जारी रखें" दबाएँ', 'Bu hesap Google ile açılmış, "Google ile devam et" seçin', 'Akun ini dibuat lewat Google, ketuk "Lanjutkan dengan Google"', 'Akaun ini dibuat melalui Google, ketik "Teruskan dengan Google"'],
  'e_google': ['গুগল লগইন হয়নি, আবার চেষ্টা করুন', 'Google sign-in failed. Please try again', 'فشل تسجيل الدخول عبر Google، حاول مجددًا', 'Google لاگ اِن ناکام، دوبارہ کوشش کریں', 'Google लॉग इन विफल, फिर से कोशिश करें', 'Google girişi başarısız, tekrar deneyin', 'Login Google gagal, coba lagi', 'Log masuk Google gagal, cuba lagi'],

  // ---- settings / update / avatar ----
  'settings': ['সেটিংস', 'Settings', 'الإعدادات', 'سیٹنگز', 'सेटिंग्स', 'Ayarlar', 'Pengaturan', 'Tetapan'],
  'st_look': ['চেহারা', 'Appearance', 'المظهر', 'ظاہری شکل', 'दिखावट', 'Görünüm', 'Tampilan', 'Paparan'],
  'st_color': ['অ্যাপের রঙ', 'App color', 'لون التطبيق', 'ایپ کا رنگ', 'ऐप का रंग', 'Uygulama rengi', 'Warna aplikasi', 'Warna aplikasi'],
  'th_green': ['সবুজ', 'Green', 'أخضر', 'سبز', 'हरा', 'Yeşil', 'Hijau', 'Hijau'],
  'th_ocean': ['সাগর', 'Ocean', 'محيطي', 'سمندری', 'समुद्री', 'Okyanus', 'Samudra', 'Lautan'],
  'th_purple': ['বেগুনি', 'Purple', 'بنفسجي', 'جامنی', 'बैंगनी', 'Mor', 'Ungu', 'Ungu'],
  'th_rose': ['গোলাপি', 'Rose', 'وردي', 'گلابی', 'गुलाबी', 'Gül', 'Mawar', 'Mawar'],
  'th_sand': ['মরুভূমি', 'Desert', 'صحراوي', 'صحرائی', 'रेगिस्तानी', 'Çöl', 'Gurun', 'Gurun'],
  'th_night': ['মধ্যরাত', 'Midnight', 'منتصف الليل', 'آدھی رات', 'मध्यरात्रि', 'Gece', 'Tengah malam', 'Tengah malam'],
  'st_version': ['অ্যাপ ভার্সন', 'App version', 'إصدار التطبيق', 'ایپ ورژن', 'ऐप संस्करण', 'Uygulama sürümü', 'Versi aplikasi', 'Versi aplikasi'],
  'st_version_body': ['ভার্সন {v} (বিল্ড {b})', 'Version {v} (build {b})', 'الإصدار {v} (البناء {b})', 'ورژن {v} (بلڈ {b})', 'संस्करण {v} (बिल्ड {b})', 'Sürüm {v} (derleme {b})', 'Versi {v} (build {b})', 'Versi {v} (binaan {b})'],
  'st_contact': ['যোগাযোগ করুন', 'Contact us', 'اتصل بنا', 'ہم سے رابطہ کریں', 'संपर्क करें', 'Bize ulaşın', 'Hubungi kami', 'Hubungi kami'],
  'st_email_copied': ['ইমেইল ঠিকানা কপি হয়েছে', 'Email address copied', 'تم نسخ البريد', 'ای میل ایڈریس کاپی ہو گیا', 'ईमेल पता कॉपी हुआ', 'E-posta adresi kopyalandı', 'Alamat email disalin', 'Alamat e-mel disalin'],
  'st_update': ['অ্যাপ আপডেট', 'Update app', 'تحديث التطبيق', 'ایپ اپ ڈیٹ', 'ऐप अपडेट', 'Uygulamayı güncelle', 'Perbarui aplikasi', 'Kemas kini aplikasi'],
  'st_checking': ['আপডেট খোঁজা হচ্ছে...', 'Checking for updates...', 'جارٍ البحث عن تحديث...', 'اپ ڈیٹ تلاش ہو رہی ہے...', 'अपडेट खोजा जा रहा है...', 'Güncelleme aranıyor...', 'Memeriksa pembaruan...', 'Menyemak kemas kini...'],
  'st_uptodate': ['আপনার অ্যাপ সর্বশেষ ভার্সনে আছে', 'Your app is up to date', 'تطبيقك محدّث', 'آپ کی ایپ تازہ ترین ہے', 'आपका ऐप अप-टू-डेट है', 'Uygulamanız güncel', 'Aplikasi Anda sudah terbaru', 'Aplikasi anda sudah terkini'],
  'st_newver': ['নতুন ভার্সন {v} পাওয়া গেছে', 'New version {v} is available', 'يتوفر إصدار جديد {v}', 'نیا ورژن {v} دستیاب ہے', 'नया संस्करण {v} उपलब्ध है', 'Yeni sürüm {v} mevcut', 'Versi baru {v} tersedia', 'Versi baharu {v} tersedia'],
  'st_download': ['ডাউনলোড ও ইনস্টল', 'Download & install', 'تنزيل وتثبيت', 'ڈاؤن لوڈ اور انسٹال', 'डाउनलोड और इंस्टॉल', 'İndir ve kur', 'Unduh & pasang', 'Muat turun & pasang'],
  'st_later': ['পরে', 'Later', 'لاحقًا', 'بعد میں', 'बाद में', 'Sonra', 'Nanti', 'Kemudian'],
  'st_ok': ['ঠিক আছে', 'OK', 'حسنًا', 'ٹھیک ہے', 'ठीक है', 'Tamam', 'OK', 'OK'],
  'st_repo_title': ['আপডেটের GitHub রিপো', 'GitHub repo for updates', 'مستودع GitHub للتحديثات', 'اپ ڈیٹس کے لیے GitHub ریپو', 'अपडेट के लिए GitHub रिपो', 'Güncellemeler için GitHub deposu', 'Repo GitHub untuk pembaruan', 'Repo GitHub untuk kemas kini'],
  'st_upd_fail': ['আপডেট খোঁজা যায়নি। ইন্টারনেট বা রিপোর নাম দেখুন (রিপো Public হতে হবে, Release থাকতে হবে)।', 'Could not check for updates. Check the internet and repo name (repo must be public with a Release).', 'تعذر البحث عن تحديث. تحقق من الإنترنت واسم المستودع.', 'اپ ڈیٹ چیک نہیں ہو سکی۔ انٹرنیٹ اور ریپو کا نام دیکھیں۔', 'अपडेट नहीं मिल सका। इंटरनेट और रिपो का नाम देखें।', 'Güncelleme kontrol edilemedi. İnterneti ve depo adını kontrol edin.', 'Gagal memeriksa pembaruan. Periksa internet dan nama repo.', 'Gagal menyemak kemas kini. Semak internet dan nama repo.'],
  'st_change_repo': ['রিপো বদলান', 'Change repo', 'تغيير المستودع', 'ریپو بدلیں', 'रिपो बदलें', 'Depoyu değiştir', 'Ganti repo', 'Tukar repo'],
  'pf_avatar': ['প্রোফাইল আইকন বাছুন', 'Choose a profile icon', 'اختر أيقونة الملف الشخصي', 'پروفائل آئیکن چنیں', 'प्रोफ़ाइल आइकन चुनें', 'Profil simgesi seçin', 'Pilih ikon profil', 'Pilih ikon profil'],
  'pf_edit': ['প্রোফাইল সম্পাদনা', 'Edit profile', 'تعديل الملف الشخصي', 'پروفائل میں ترمیم', 'प्रोफ़ाइल संपादित करें', 'Profili düzenle', 'Edit profil', 'Sunting profil'],
  'pf_account': ['অ্যাকাউন্ট', 'Account', 'الحساب', 'اکاؤنٹ', 'खाता', 'Hesap', 'Akun', 'Akaun'],
  'pf_email_fixed': ['ইমেইল বদলানো যায় না', 'Email cannot be changed', 'لا يمكن تغيير البريد', 'ای میل تبدیل نہیں ہو سکتی', 'ईमेल बदला नहीं जा सकता', 'E-posta değiştirilemez', 'Email tidak dapat diubah', 'E-mel tidak boleh diubah'],
  'pf_saved': ['প্রোফাইল আপডেট হয়েছে', 'Profile updated', 'تم تحديث الملف الشخصي', 'پروفائل اپ ڈیٹ ہو گئی', 'प्रोफ़ाइल अपडेट हो गई', 'Profil güncellendi', 'Profil diperbarui', 'Profil dikemas kini'],
  'pf_logout': ['লগআউট', 'Log out', 'تسجيل الخروج', 'لاگ آؤٹ', 'लॉग आउट', 'Çıkış yap', 'Keluar', 'Log keluar'],
  'pf_logout_title': ['লগআউট করবেন?', 'Log out?', 'تسجيل الخروج؟', 'لاگ آؤٹ کریں؟', 'लॉग आउट करें?', 'Çıkış yapılsın mı?', 'Keluar?', 'Log keluar?'],
  'pf_logout_body': ['আবার লগইন করলেই আপনার প্রোফাইল ফিরে পাবেন।', 'Log in again to get your profile back.', 'سجّل الدخول مجددًا لاستعادة ملفك الشخصي.', 'دوبارہ لاگ اِن کریں تو آپ کی پروفائل واپس مل جائے گی۔', 'फिर से लॉग इन करने पर आपकी प्रोफ़ाइल वापस मिल जाएगी।', 'Tekrar giriş yaparak profilinize ulaşabilirsiniz.', 'Masuk lagi untuk mendapatkan profil Anda kembali.', 'Log masuk semula untuk mendapatkan profil anda kembali.'],
  'pf_logout_yes': ['হ্যাঁ, লগআউট', 'Yes, log out', 'نعم، سجّل الخروج', 'ہاں، لاگ آؤٹ', 'हाँ, लॉग आउट', 'Evet, çıkış yap', 'Ya, keluar', 'Ya, log keluar'],

  // ---- gazal ----
  'gz_add_tip': ['ফোন থেকে গজল যোগ করুন', 'Add nasheed from phone', 'أضف نشيدًا من الهاتف', 'فون سے ناشید شامل کریں', 'फ़ोन से नशीद जोड़ें', 'Telefondan ilahi ekle', 'Tambah nasyid dari ponsel', 'Tambah nasyid dari telefon'],
  'gz_add': ['গজল যোগ করুন', 'Add nasheed', 'إضافة نشيد', 'ناشید شامل کریں', 'नशीद जोड़ें', 'İlahi ekle', 'Tambah nasyid', 'Tambah nasyid'],
  'gz_sync_tip': ['অনলাইন গজল আপডেট করুন', 'Refresh online nasheeds', 'تحديث الأناشيد عبر الإنترنت', 'آن لائن ناشید اپڈیٹ کریں', 'ऑनलाइन नशीद अपडेट करें', 'Çevrimiçi ilahileri yenile', 'Perbarui nasyid online', 'Kemas kini nasyid dalam talian'],
  'gz_src_tip': ['অনলাইন সোর্স (GitHub / Drive)', 'Online sources (GitHub / Drive)', 'المصادر (GitHub / Drive)', 'آن لائن ذرائع (GitHub / Drive)', 'ऑनलाइन स्रोत (GitHub / Drive)', 'Çevrimiçi kaynaklar (GitHub / Drive)', 'Sumber online (GitHub / Drive)', 'Sumber dalam talian (GitHub / Drive)'],
  'gz_empty': [
    'এখনো কোনো গজল নেই।\nফোন থেকে যোগ করুন, অথবা ক্লাউড আইকনে GitHub / Google Drive সংযুক্ত করুন।',
    'No nasheeds yet.\nAdd from your phone, or connect GitHub / Google Drive with the cloud icon.',
    'لا توجد أناشيد بعد.\nأضف من هاتفك أو اربط GitHub / Google Drive من أيقونة السحابة.',
    'ابھی کوئی ناشید نہیں۔\nفون سے شامل کریں، یا کلاؤڈ آئیکن سے GitHub / Google Drive جوڑیں۔',
    'अभी कोई नशीद नहीं है।\nफ़ोन से जोड़ें, या क्लाउड आइकन से GitHub / Google Drive जोड़ें।',
    'Henüz ilahi yok.\nTelefondan ekleyin veya bulut simgesiyle GitHub / Google Drive bağlayın.',
    'Belum ada nasyid.\nTambahkan dari ponsel, atau hubungkan GitHub / Google Drive lewat ikon awan.',
    'Belum ada nasyid.\nTambah dari telefon, atau sambungkan GitHub / Google Drive melalui ikon awan.',
  ],
  'gz_fail_add': ['ফাইল যোগ করা যায়নি', 'Could not add the file', 'تعذّرت إضافة الملف', 'فائل شامل نہیں ہو سکی', 'फ़ाइल जोड़ी नहीं जा सकी', 'Dosya eklenemedi', 'Tidak dapat menambahkan file', 'Tidak dapat menambah fail'],
  'gz_play_err': ['প্লে করা যায়নি। ফাইল বা ইন্টারনেট চেক করুন।', 'Could not play. Check the file or your internet.', 'تعذّر التشغيل. تحقق من الملف أو الإنترنت.', 'چل نہیں سکا۔ فائل یا انٹرنیٹ چیک کریں۔', 'चल नहीं सका। फ़ाइल या इंटरनेट जाँचें।', 'Oynatılamadı. Dosyayı veya interneti kontrol edin.', 'Tidak dapat diputar. Periksa file atau internet.', 'Tidak dapat dimainkan. Semak fail atau internet.'],
  'gz_online': ['অনলাইন', 'Online', 'عبر الإنترنت', 'آن لائن', 'ऑनलाइन', 'Çevrimiçi', 'Online', 'Dalam talian'],
  'gz_mine': ['আমার গজল', 'My nasheeds', 'أناشيدي', 'میرے ناشید', 'मेरे नशीद', 'İlahilerim', 'Nasyid saya', 'Nasyid saya'],
  'gz_src_title': ['অনলাইন সোর্স', 'Online sources', 'المصادر عبر الإنترنت', 'آن لائن ذرائع', 'ऑनलाइन स्रोत', 'Çevrimiçi kaynaklar', 'Sumber online', 'Sumber dalam talian'],
  'gz_src_help': [
    'এখানে লিংক দিলে অ্যাপ নিজে থেকেই নতুন অডিও খুঁজে তালিকা আপডেট করবে। রিপো/ফোল্ডার অবশ্যই পাবলিক হতে হবে।',
    'Add a link here and the app will find new audio and update the list by itself. The repo/folder must be public.',
    'أضف رابطًا هنا وسيبحث التطبيق عن الصوتيات الجديدة ويحدّث القائمة تلقائيًا. يجب أن يكون المستودع/المجلد عامًا.',
    'یہاں لنک دیں تو ایپ خود نئی آڈیو تلاش کر کے فہرست اپڈیٹ کرے گی۔ ریپو/فولڈر پبلک ہونا ضروری ہے۔',
    'यहाँ लिंक दें तो ऐप खुद नई ऑडियो खोजकर सूची अपडेट करेगा। रिपो/फ़ोल्डर पब्लिक होना ज़रूरी है।',
    'Buraya bağlantı ekleyin; uygulama yeni sesleri kendisi bulup listeyi günceller. Depo/klasör herkese açık olmalı.',
    'Tambahkan tautan di sini dan aplikasi akan menemukan audio baru lalu memperbarui daftar sendiri. Repo/folder harus publik.',
    'Tambah pautan di sini dan aplikasi akan mencari audio baharu serta mengemas kini senarai sendiri. Repo/folder mesti awam.',
  ],
  'gz_github_label': ['GitHub রিপো', 'GitHub repo', 'مستودع GitHub', 'GitHub ریپو', 'GitHub रिपो', 'GitHub deposu', 'Repo GitHub', 'Repo GitHub'],
  'gz_drive_label': ['Google Drive ফোল্ডার (লিংক বা ID)', 'Google Drive folder (link or ID)', 'مجلد Google Drive (رابط أو ID)', 'Google Drive فولڈر (لنک یا ID)', 'Google Drive फ़ोल्डर (लिंक या ID)', 'Google Drive klasörü (bağlantı veya ID)', 'Folder Google Drive (tautan atau ID)', 'Folder Google Drive (pautan atau ID)'],
  'gz_key_label': ['Google API key (Drive API চালু করা)', 'Google API key (Drive API enabled)', 'مفتاح Google API (مع تفعيل Drive API)', 'Google API key (Drive API فعال)', 'Google API key (Drive API चालू)', 'Google API anahtarı (Drive API etkin)', 'Kunci Google API (Drive API aktif)', 'Kunci Google API (Drive API diaktifkan)'],
  'gz_synced': ['গজলের তালিকা আপডেট হয়েছে', 'Nasheed list updated', 'تم تحديث قائمة الأناشيد', 'ناشید کی فہرست اپڈیٹ ہو گئی', 'नशीद की सूची अपडेट हुई', 'İlahi listesi güncellendi', 'Daftar nasyid diperbarui', 'Senarai nasyid dikemas kini'],
  'gz_sync_fail': ['আপডেট করা যায়নি — ইন্টারনেট বা লিংক চেক করুন', 'Could not update — check internet or links', 'تعذّر التحديث — تحقق من الإنترنت أو الروابط', 'اپڈیٹ نہیں ہو سکا — انٹرنیٹ یا لنک چیک کریں', 'अपडेट नहीं हो सका — इंटरनेट या लिंक जाँचें', 'Güncellenemedi — interneti veya bağlantıları kontrol edin', 'Gagal memperbarui — periksa internet atau tautan', 'Gagal mengemas kini — semak internet atau pautan'],
  'gz_not_set': ['অনলাইন সোর্স সেট করা নেই', 'No online source set', 'لم يتم تعيين مصدر عبر الإنترنت', 'کوئی آن لائن ذریعہ سیٹ نہیں', 'कोई ऑनलाइन स्रोत सेट नहीं है', 'Çevrimiçi kaynak ayarlanmadı', 'Sumber online belum diatur', 'Sumber dalam talian belum ditetapkan'],

  // ---- calendar ----
  'hijri_suffix': ['হি.', 'AH', 'هـ', 'ھ', 'हि.', 'H.', 'H', 'H'],
};

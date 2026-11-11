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
String localizeDigits(String s, [String? lang]) {
  final set = _digitSets[lang ?? appLang.value];
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
  'e_net': ['ইন্টারনেট সংযোগ চেক করুন', 'Check your internet connection', 'تحقق من اتصال الإنترنت', 'اپنا انٹرنیٹ کنکشن چیک کریں', 'इंटरनेट कनेक्शन जाँचें', 'İnternet bağlantınızı kontrol edin', 'Periksa koneksi internet Anda', 'Semak sambungan internet anda'],
  'e_fail': ['কিছু একটা সমস্যা হয়েছে, আবার চেষ্টা করুন', 'Something went wrong. Please try again', 'حدث خطأ ما، حاول مجددًا', 'کچھ غلط ہو گیا، دوبارہ کوشش کریں', 'कुछ गड़बड़ हुई, फिर से कोशिश करें', 'Bir şeyler ters gitti, tekrar deneyin', 'Terjadi kesalahan, coba lagi', 'Sesuatu tidak kena, cuba lagi'],

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

  // ---- settings pages ----
  'st_look_sub': ['রঙ বেছে নিন', 'Choose a colour theme', 'اختر لون التطبيق', 'رنگ منتخب کریں', 'रंग चुनें', 'Renk teması seçin', 'Pilih tema warna', 'Pilih tema warna'],
  'st_update_sub': ['নতুন ভার্সন আছে কি না দেখুন', 'Check for a newer version', 'تحقق من وجود إصدار جديد', 'نیا ورژن چیک کریں', 'नया संस्करण देखें', 'Yeni sürümü kontrol et', 'Periksa versi baru', 'Semak versi baharu'],
  'st_version_sub': ['ভার্সন ও বিল্ড নম্বর', 'Version and build number', 'رقم الإصدار والبناء', 'ورژن اور بلڈ نمبر', 'संस्करण और बिल्ड नंबर', 'Sürüm ve derleme numarası', 'Versi dan nomor build', 'Versi dan nombor binaan'],
  'st_about_sub': ['অ্যাপ ও ডেভেলপার পরিচিতি', 'About the app and developer', 'عن التطبيق والمطوّر', 'ایپ اور ڈیولپر کا تعارف', 'ऐप और डेवलपर के बारे में', 'Uygulama ve geliştirici hakkında', 'Tentang aplikasi dan pengembang', 'Tentang aplikasi dan pembangun'],
  'st_contact_sub': ['সরাসরি অ্যাপ থেকে বার্তা পাঠান', 'Send us a message from the app', 'أرسل لنا رسالة من التطبيق', 'ایپ سے ہمیں پیغام بھیجیں', 'ऐप से हमें संदेश भेजें', 'Uygulamadan bize mesaj gönderin', 'Kirim pesan langsung dari aplikasi', 'Hantar mesej terus dari aplikasi'],
  'st_lang_hint': ['ভাষা বদলালে অ্যাপ হোমে ফিরে যাবে।', 'The app returns to Home when the language changes.', 'سيعود التطبيق إلى الرئيسية عند تغيير اللغة.', 'زبان بدلنے پر ایپ ہوم پر واپس آ جائے گی۔', 'भाषा बदलने पर ऐप होम पर लौट जाएगा।', 'Dil değişince uygulama ana sayfaya döner.', 'Aplikasi kembali ke Beranda saat bahasa diubah.', 'Aplikasi kembali ke Laman Utama apabila bahasa ditukar.'],
  'ab_tagline': ['আপনার দৈনন্দিন ইসলামিক সঙ্গী', 'Your daily Islamic companion', 'رفيقك الإسلامي اليومي', 'آپ کا روزانہ کا اسلامی ساتھی', 'आपका रोज़ का इस्लामिक साथी', 'Günlük İslami yol arkadaşınız', 'Pendamping Islami harian Anda', 'Teman Islam harian anda'],
  'ab_desc': [
    'নূর একটি আধুনিক, বিজ্ঞাপনমুক্ত ও সহজ বাংলা ইসলামিক অ্যাপ। কুরআন তিলাওয়াত ও অনুবাদ, নামাযের সময়, দোয়া, হাদিস, গজল এবং দৈনন্দিন আমল ট্র্যাকার — সবকিছু এক জায়গায়, সুন্দর ও সহজ ইন্টারফেসে।',
    'Noor is a modern, clean and easy-to-use Islamic app. Quran recitation and translation, prayer times, duas, hadith, nasheeds and a daily amal tracker — all in one place with a beautiful interface.',
    'نور تطبيق إسلامي عصري وسهل الاستخدام: تلاوة القرآن وترجمته، مواقيت الصلاة، الأدعية، الأحاديث، الأناشيد ومتتبع الأعمال اليومية في مكان واحد.',
    'نور ایک جدید اور آسان اسلامی ایپ ہے: قرآن کی تلاوت و ترجمہ، نماز کے اوقات، دعائیں، حدیث، ناشید اور روزانہ اعمال کا ٹریکر ایک ہی جگہ۔',
    'नूर एक आधुनिक और आसान इस्लामिक ऐप है: क़ुरआन तिलावत व अनुवाद, नमाज़ के समय, दुआएँ, हदीस, नशीद और रोज़ाना अमल ट्रैकर, सब एक जगह।',
    "Noor; modern ve kullanımı kolay bir İslami uygulamadır: Kur'an tilaveti ve meali, namaz vakitleri, dualar, hadisler, ilahiler ve günlük amel takibi tek yerde.",
    "Noor adalah aplikasi Islami modern dan mudah digunakan: tilawah dan terjemah Al-Qur'an, waktu salat, doa, hadis, nasyid, dan pelacak amal harian dalam satu tempat.",
    'Noor ialah aplikasi Islam moden dan mudah digunakan: tilawah dan terjemahan Al-Quran, waktu solat, doa, hadis, nasyid dan penjejak amal harian di satu tempat.',
  ],
  'ab_features': ['মূল সুবিধা', 'Highlights', 'أبرز الميزات', 'نمایاں خصوصیات', 'मुख्य विशेषताएँ', 'Öne çıkanlar', 'Fitur utama', 'Ciri utama'],
  'ab_f1': ['কুরআন — বাংলা অনুবাদ ও তিলাওয়াত', 'Quran with Bangla translation and recitation', 'القرآن بترجمة بنغالية وتلاوة', 'قرآن بنگلہ ترجمہ اور تلاوت کے ساتھ', 'क़ुरआन: बांग्ला अनुवाद और तिलावत', "Bengalce mealli Kur'an ve tilavet", "Al-Qur'an dengan terjemah Bengali dan tilawah", 'Al-Quran dengan terjemahan Bengali dan tilawah'],
  'ab_f2': ['নামাযের সময় ও ইসলামিক ক্যালেন্ডার', 'Prayer times and Islamic calendar', 'مواقيت الصلاة والتقويم الهجري', 'نماز کے اوقات اور اسلامی کیلنڈر', 'नमाज़ के समय और इस्लामिक कैलेंडर', 'Namaz vakitleri ve İslami takvim', 'Waktu salat dan kalender Islam', 'Waktu solat dan kalendar Islam'],
  'ab_f3': ['দোয়া, হাদিস ও ইসলামিক কিতাব', 'Duas, hadith and Islamic books', 'أدعية وأحاديث وكتب إسلامية', 'دعائیں، حدیث اور اسلامی کتب', 'दुआएँ, हदीस और इस्लामिक किताबें', 'Dualar, hadisler ve İslami kitaplar', 'Doa, hadis, dan buku Islami', 'Doa, hadis dan buku Islam'],
  'ab_f4': ['গজল, কুইজ ও দৈনিক আমল ট্র্যাকার', 'Nasheeds, quiz and daily amal tracker', 'أناشيد واختبارات ومتتبع الأعمال', 'ناشید، کوئز اور روزانہ اعمال ٹریکر', 'नशीद, क्विज़ और रोज़ाना अमल ट्रैकर', 'İlahiler, quiz ve günlük amel takibi', 'Nasyid, kuis, dan pelacak amal harian', 'Nasyid, kuiz dan penjejak amal harian'],
  'ab_dev': ['ডেভেলপার', 'Developer', 'المطوّر', 'ڈیولپر', 'डेवलपर', 'Geliştirici', 'Pengembang', 'Pembangun'],
  'ab_dev_note': [
    'সবার জন্য সহজ, নির্ভরযোগ্য ও সুন্দর একটি ইসলামিক অ্যাপ তৈরির লক্ষ্যে নিরলস কাজ করে যাচ্ছি। আপনার মতামত ও পরামর্শ অ্যাপকে আরও উন্নত করতে সাহায্য করে।',
    'Built with care to be simple, reliable and beautiful for everyone. Your feedback and suggestions help make the app better with every update.',
    'بُني بعناية ليكون بسيطًا وموثوقًا وجميلًا للجميع. ملاحظاتكم واقتراحاتكم تساعد على تحسينه مع كل تحديث.',
    'سب کے لیے آسان، قابلِ اعتماد اور خوبصورت بنانے کی کوشش کی گئی ہے۔ آپ کی رائے ایپ کو بہتر بناتی ہے۔',
    'सबके लिए आसान, भरोसेमंद और सुंदर बनाने की कोशिश की गई है। आपकी राय ऐप को बेहतर बनाती है।',
    'Herkes için basit, güvenilir ve güzel olması için özenle hazırlandı. Geri bildirimleriniz uygulamayı geliştirir.',
    'Dibuat dengan penuh perhatian agar sederhana, andal, dan indah untuk semua. Masukan Anda membantu aplikasi menjadi lebih baik.',
    'Dibina dengan teliti supaya ringkas, boleh dipercayai dan cantik untuk semua. Maklum balas anda membantu menambah baik aplikasi.',
  ],
  'ab_credits': ['কৃতজ্ঞতা', 'Credits', 'شكر وتقدير', 'شکریہ', 'आभार', 'Teşekkür', 'Penghargaan', 'Penghargaan'],
  'ab_credits_body': [
    'কুরআনের বাংলা অনুবাদ: মুহিউদ্দীন খান (tanzil.net)।',
    'Quran Bangla translation: Muhiuddin Khan (tanzil.net).',
    'ترجمة القرآن إلى البنغالية: محيي الدين خان (tanzil.net).',
    'قرآن کا بنگلہ ترجمہ: محی الدین خان (tanzil.net)۔',
    'क़ुरआन का बांग्ला अनुवाद: मुहिउद्दीन ख़ान (tanzil.net)।',
    "Kur'an'ın Bengalce meali: Muhiuddin Khan (tanzil.net).",
    "Terjemahan Al-Qur'an Bengali: Muhiuddin Khan (tanzil.net).",
    'Terjemahan Al-Quran Bengali: Muhiuddin Khan (tanzil.net).',
  ],
  'ab_feedback': ['মতামত পাঠান', 'Send feedback', 'أرسل ملاحظاتك', 'رائے بھیجیں', 'फ़ीडबैक भेजें', 'Geri bildirim gönder', 'Kirim masukan', 'Hantar maklum balas'],
  'ab_rights': ['সর্বস্বত্ব সংরক্ষিত', 'All rights reserved', 'جميع الحقوق محفوظة', 'جملہ حقوق محفوظ ہیں', 'सर्वाधिकार सुरक्षित', 'Tüm hakları saklıdır', 'Hak cipta dilindungi', 'Hak cipta terpelihara'],
  'ct_intro': [
    'কোনো প্রশ্ন, সমস্যা বা পরামর্শ থাকলে নিচে লিখুন। বার্তাটি সরাসরি অ্যাপ থেকেই আমাদের কাছে পৌঁছে যাবে।',
    'Have a question, problem or suggestion? Write it below and it will be delivered to us directly from the app.',
    'لديك سؤال أو مشكلة أو اقتراح؟ اكتبه أدناه وسيصلنا مباشرة من التطبيق.',
    'کوئی سوال، مسئلہ یا تجویز ہو تو نیچے لکھیں، پیغام سیدھا ایپ سے ہم تک پہنچ جائے گا۔',
    'कोई सवाल, समस्या या सुझाव हो तो नीचे लिखें, संदेश सीधे ऐप से हम तक पहुँचेगा।',
    'Soru, sorun veya öneriniz mi var? Aşağıya yazın, mesaj doğrudan uygulamadan bize ulaşır.',
    'Punya pertanyaan, masalah, atau saran? Tulis di bawah dan pesan terkirim langsung dari aplikasi.',
    'Ada soalan, masalah atau cadangan? Tulis di bawah dan mesej dihantar terus dari aplikasi.',
  ],
  'ct_name': ['আপনার নাম', 'Your name', 'اسمك', 'آپ کا نام', 'आपका नाम', 'Adınız', 'Nama Anda', 'Nama anda'],
  'ct_reply': ['উত্তরের জন্য ইমেইল (ঐচ্ছিক)', 'Email for reply (optional)', 'بريدك للرد (اختياري)', 'جواب کے لیے ای میل (اختیاری)', 'जवाब के लिए ईमेल (वैकल्पिक)', 'Yanıt için e-posta (isteğe bağlı)', 'Email untuk balasan (opsional)', 'E-mel untuk balasan (pilihan)'],
  'ct_subject': ['বিষয়', 'Subject', 'الموضوع', 'موضوع', 'विषय', 'Konu', 'Subjek', 'Subjek'],
  'ct_message': ['আপনার বার্তা', 'Your message', 'رسالتك', 'آپ کا پیغام', 'आपका संदेश', 'Mesajınız', 'Pesan Anda', 'Mesej anda'],
  'ct_send': ['পাঠান', 'Send', 'إرسال', 'بھیجیں', 'भेजें', 'Gönder', 'Kirim', 'Hantar'],
  'ct_sending': ['পাঠানো হচ্ছে...', 'Sending...', 'جارٍ الإرسال...', 'بھیجا جا رہا ہے...', 'भेजा जा रहा है...', 'Gönderiliyor...', 'Mengirim...', 'Menghantar...'],
  'ct_sent': ['ধন্যবাদ! আপনার বার্তা পাঠানো হয়েছে।', 'Thank you! Your message has been sent.', 'شكرًا! تم إرسال رسالتك.', 'شکریہ! آپ کا پیغام بھیج دیا گیا۔', 'धन्यवाद! आपका संदेश भेज दिया गया।', 'Teşekkürler! Mesajınız gönderildi.', 'Terima kasih! Pesan Anda terkirim.', 'Terima kasih! Mesej anda telah dihantar.'],
  'ct_fail': ['পাঠানো যায়নি। ইন্টারনেট চেক করে আবার চেষ্টা করুন।', 'Could not send. Check your internet and try again.', 'تعذّر الإرسال. تحقق من الإنترنت وحاول مجددًا.', 'بھیج نہیں سکا۔ انٹرنیٹ چیک کر کے دوبارہ کوشش کریں۔', 'भेजा नहीं जा सका। इंटरनेट जाँचकर फिर कोशिश करें।', 'Gönderilemedi. İnterneti kontrol edip tekrar deneyin.', 'Gagal mengirim. Periksa internet lalu coba lagi.', 'Gagal dihantar. Semak internet dan cuba lagi.'],
  'ct_empty': ['অনুগ্রহ করে বার্তা লিখুন', 'Please write a message', 'يرجى كتابة رسالة', 'براہِ کرم پیغام لکھیں', 'कृपया संदेश लिखें', 'Lütfen bir mesaj yazın', 'Silakan tulis pesan', 'Sila tulis mesej'],
  'ct_bad_email': ['ইমেইল ঠিকানাটি সঠিক নয়', 'That email address looks invalid', 'عنوان البريد غير صالح', 'ای میل ایڈریس درست نہیں', 'ईमेल पता सही नहीं है', 'E-posta adresi geçersiz', 'Alamat email tidak valid', 'Alamat e-mel tidak sah'],
  'ct_s_general': ['সাধারণ মতামত', 'General feedback', 'ملاحظات عامة', 'عمومی رائے', 'सामान्य फ़ीडबैक', 'Genel geri bildirim', 'Masukan umum', 'Maklum balas am'],
  'ct_s_bug': ['সমস্যা জানান', 'Report a problem', 'الإبلاغ عن مشكلة', 'مسئلہ بتائیں', 'समस्या बताएँ', 'Sorun bildir', 'Laporkan masalah', 'Laporkan masalah'],
  'ct_s_feature': ['নতুন ফিচারের অনুরোধ', 'Feature request', 'طلب ميزة', 'نئی خصوصیت کی درخواست', 'नए फ़ीचर का अनुरोध', 'Özellik isteği', 'Permintaan fitur', 'Permintaan ciri'],
  'ct_s_content': ['কনটেন্ট সংশোধন', 'Content correction', 'تصحيح المحتوى', 'مواد کی اصلاح', 'सामग्री सुधार', 'İçerik düzeltmesi', 'Koreksi konten', 'Pembetulan kandungan'],

  // ---- notifications ----
  'st_area_sub': ['নামাযের সময়ের জন্য এলাকা বদলান', 'Change the area used for prayer times', 'غيّر المنطقة لمواقيت الصلاة', 'نماز کے اوقات کے لیے علاقہ بدلیں', 'नमाज़ के समय के लिए क्षेत्र बदलें', 'Namaz vakitleri için bölgeyi değiştirin', 'Ubah wilayah untuk waktu salat', 'Tukar kawasan untuk waktu solat'],
  'nt_today': ['আজকের নামাযের সময়', "Today's prayer times", 'مواقيت صلاة اليوم', 'آج کے نماز کے اوقات', 'आज के नमाज़ के समय', 'Bugünkü namaz vakitleri', 'Waktu salat hari ini', 'Waktu solat hari ini'],
  'nt_reminders': ['রিমাইন্ডার', 'Reminders', 'تذكيرات', 'یاد دہانیاں', 'रिमाइंडर', 'Hatırlatmalar', 'Pengingat', 'Peringatan'],
  'nt_in_area': ['এলাকা', 'Area', 'المنطقة', 'علاقہ', 'क्षेत्र', 'Bölge', 'Wilayah', 'Kawasan'],
  'nt_soon': ['শীঘ্রই', 'Soon', 'قريبًا', 'جلد', 'जल्द', 'Yakında', 'Segera', 'Tidak lama lagi'],
  'nt_done': ['সময় হয়েছে', 'Time has begun', 'دخل الوقت', 'وقت ہو چکا', 'समय हो चुका', 'Vakit girdi', 'Waktu telah masuk', 'Waktu telah masuk'],
  'nt_upcoming': ['আসছে', 'Upcoming', 'قادم', 'آنے والا', 'आने वाला', 'Yaklaşan', 'Akan datang', 'Akan datang'],
  'nt_jumuah_t': ['আজ জুমার দিন', "Today is Jumu'ah", 'اليوم يوم الجمعة', 'آج جمعہ کا دن ہے', 'आज जुमा का दिन है', 'Bugün Cuma', "Hari ini Jumat", 'Hari ini Jumaat'],
  'nt_jumuah_b': ['গোসল, সূরা কাহফ তিলাওয়াত ও বেশি বেশি দরূদ পাঠ করুন।', 'Take ghusl, recite Surah Al-Kahf and send abundant salawat.', 'اغتسل واقرأ سورة الكهف وأكثر من الصلاة على النبي ﷺ.', 'غسل کریں، سورۃ الکہف پڑھیں اور کثرت سے درود بھیجیں۔', 'ग़ुस्ल करें, सूरह कहफ़ पढ़ें और खूब दरूद भेजें।', 'Gusül alın, Kehf suresini okuyun ve çokça salavat getirin.', 'Mandi sunnah, baca Surah Al-Kahfi, dan perbanyak shalawat.', 'Mandi sunat, baca Surah Al-Kahfi dan perbanyakkan selawat.'],
  'nt_amal_t': ['আজকের আমল', "Today's amal", 'أعمال اليوم', 'آج کے اعمال', 'आज के अमल', 'Bugünkü ameller', 'Amal hari ini', 'Amal hari ini'],
  'nt_amal_b': ['আজকের আমলগুলো সম্পন্ন করে ট্র্যাকারে টিক দিন।', 'Complete your daily amal and tick it off in the tracker.', 'أتمّ أعمالك اليومية وضع علامة في المتتبع.', 'روزانہ اعمال مکمل کر کے ٹریکر میں ٹک کریں۔', 'रोज़ाना के अमल पूरे करके ट्रैकर में टिक करें।', 'Günlük amellerinizi tamamlayıp takipçide işaretleyin.', 'Selesaikan amal harian dan centang di pelacak.', 'Lengkapkan amal harian dan tanda di penjejak.'],
  'nt_quran_t': ['কুরআন তিলাওয়াত', 'Quran recitation', 'تلاوة القرآن', 'قرآن کی تلاوت', 'क़ुरआन तिलावत', "Kur'an tilaveti", "Tilawah Al-Qur'an", 'Tilawah Al-Quran'],
  'nt_quran_b': ['প্রতিদিন অন্তত কয়েকটি আয়াত পড়ার অভ্যাস গড়ুন।', 'Build the habit of reading a few verses every day.', 'اجعل قراءة بضع آيات كل يوم عادة لك.', 'روزانہ چند آیات پڑھنے کی عادت بنائیں۔', 'रोज़ कुछ आयतें पढ़ने की आदत बनाएँ।', 'Her gün birkaç ayet okumayı alışkanlık edinin.', 'Biasakan membaca beberapa ayat setiap hari.', 'Biasakan membaca beberapa ayat setiap hari.'],
  'nt_hint': ['নামাযের সময় ও অন্যান্য আপডেট এখানে দেখা যাবে।', 'Prayer times and other updates appear here.', 'تظهر هنا مواقيت الصلاة والتحديثات الأخرى.', 'نماز کے اوقات اور دیگر اپڈیٹس یہاں نظر آئیں گی۔', 'नमाज़ के समय और अन्य अपडेट यहाँ दिखेंगे।', 'Namaz vakitleri ve diğer güncellemeler burada görünür.', 'Waktu salat dan pembaruan lain muncul di sini.', 'Waktu solat dan kemas kini lain dipaparkan di sini.'],

  // ---- ramadan countdown ----
  'rm_start': ['রমযান শুরু', 'Ramadan begins', 'بداية رمضان', 'رمضان کا آغاز', 'रमज़ान की शुरुआत', 'Ramazan başlangıcı', 'Awal Ramadan', 'Awal Ramadan'],
  'rm_running': ['রমযান চলছে', 'Ramadan is running', 'رمضان مستمر', 'رمضان جاری ہے', 'रमज़ान चल रहा है', 'Ramazan devam ediyor', 'Ramadan sedang berlangsung', 'Ramadan sedang berlangsung'],
  'rm_ends': ['ঈদুল ফিতর', 'Eid al-Fitr', 'عيد الفطر', 'عید الفطر', 'ईद उल-फ़ित्र', 'Ramazan Bayramı', 'Idulfitri', 'Aidilfitri'],
  'rm_approx': ['আনুমানিক · চাঁদ দেখা সাপেক্ষে', 'Estimated · depends on moon sighting', 'تقديري · حسب رؤية الهلال', 'تخمینی · چاند نظر آنے پر منحصر', 'अनुमानित · चाँद दिखने पर निर्भर', 'Tahmini · hilal görülmesine bağlı', 'Perkiraan · tergantung rukyat hilal', 'Anggaran · bergantung pada anak bulan'],
  'rm_days_left': ['{n} দিন বাকি', '{n} days left', 'متبقي {n} يوم', '{n} دن باقی', '{n} दिन बाकी', '{n} gün kaldı', 'sisa {n} hari', '{n} hari lagi'],
  'rm_day_of': ['রমযানের {d} নং দিন', 'Ramadan day {d} of 30', 'اليوم {d} من رمضان', 'رمضان کا دن {d}', 'रमज़ान का दिन {d}', "Ramazan'ın {d}. günü", 'Hari ke-{d} Ramadan', 'Hari ke-{d} Ramadan'],
  'rm_d': ['দিন', 'Days', 'أيام', 'دن', 'दिन', 'Gün', 'Hari', 'Hari'],
  'rm_h': ['ঘণ্টা', 'Hours', 'ساعات', 'گھنٹے', 'घंटे', 'Saat', 'Jam', 'Jam'],
  'rm_m': ['মিনিট', 'Min', 'دقائق', 'منٹ', 'मिनट', 'Dk', 'Menit', 'Minit'],
  'rm_s': ['সেকেন্ড', 'Sec', 'ثوانٍ', 'سیکنڈ', 'सेकंड', 'Sn', 'Detik', 'Saat'],

  // ---- app update ----
  'up_current': ['বর্তমান ভার্সন', 'Current version', 'الإصدار الحالي', 'موجودہ ورژن', 'वर्तमान संस्करण', 'Mevcut sürüm', 'Versi saat ini', 'Versi semasa'],
  'up_latest': ['নতুন ভার্সন', 'New version', 'الإصدار الجديد', 'نیا ورژن', 'नया संस्करण', 'Yeni sürüm', 'Versi baru', 'Versi baharu'],
  'up_downloading': ['ডাউনলোড হচ্ছে...', 'Downloading...', 'جارٍ التنزيل...', 'ڈاؤن لوڈ ہو رہا ہے...', 'डाउनलोड हो रहा है...', 'İndiriliyor...', 'Mengunduh...', 'Memuat turun...'],
  'up_installing': ['ইনস্টলার খোলা হচ্ছে...', 'Opening the installer...', 'جارٍ فتح المثبّت...', 'انسٹالر کھولا جا رہا ہے...', 'इंस्टॉलर खोला जा रहा है...', 'Yükleyici açılıyor...', 'Membuka pemasang...', 'Membuka pemasang...'],
  'up_install_hint': ['ইনস্টল না হলে "অজানা উৎস থেকে ইনস্টল" অনুমতি দিন, তারপর আবার চাপুন।', 'If it does not install, allow "Install unknown apps" for Noor, then tap again.', 'إن لم يبدأ التثبيت، اسمح بـ"تثبيت التطبيقات غير المعروفة" ثم اضغط مجددًا.', 'اگر انسٹال نہ ہو تو "نامعلوم ایپس انسٹال" کی اجازت دے کر دوبارہ دبائیں۔', 'इंस्टॉल न हो तो "अज्ञात ऐप्स इंस्टॉल" की अनुमति देकर फिर दबाएँ।', 'Yüklenmezse "Bilinmeyen uygulamaları yükle" iznini verip tekrar dokunun.', 'Jika tidak terpasang, izinkan "Pasang aplikasi tidak dikenal" lalu ketuk lagi.', 'Jika tidak dipasang, benarkan "Pasang apl tidak dikenali" kemudian ketik semula.'],
  'up_fail': ['আপডেট খোঁজা যায়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।', 'Could not check for updates. Check your internet connection and try again.', 'تعذّر البحث عن تحديث. تحقق من الاتصال بالإنترنت وحاول مجددًا.', 'اپ ڈیٹ چیک نہیں ہو سکی۔ انٹرنیٹ دیکھ کر دوبارہ کوشش کریں۔', 'अपडेट नहीं मिल सका। इंटरनेट जाँचकर फिर कोशिश करें।', 'Güncelleme kontrol edilemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.', 'Gagal memeriksa pembaruan. Periksa koneksi internet lalu coba lagi.', 'Gagal menyemak kemas kini. Semak sambungan internet dan cuba lagi.'],
  'up_dl_fail': ['ডাউনলোড ব্যর্থ হয়েছে। আবার চেষ্টা করুন।', 'Download failed. Please try again.', 'فشل التنزيل. حاول مجددًا.', 'ڈاؤن لوڈ ناکام ہو گیا۔ دوبارہ کوشش کریں۔', 'डाउनलोड विफल रहा। फिर कोशिश करें।', 'İndirme başarısız. Tekrar deneyin.', 'Unduhan gagal. Coba lagi.', 'Muat turun gagal. Cuba lagi.'],
  'up_retry': ['আবার চেষ্টা করুন', 'Try again', 'حاول مجددًا', 'دوبارہ کوشش کریں', 'फिर कोशिश करें', 'Tekrar dene', 'Coba lagi', 'Cuba lagi'],
  'up_check_again': ['আবার চেক করুন', 'Check again', 'تحقق مجددًا', 'دوبارہ چیک کریں', 'फिर जाँचें', 'Tekrar kontrol et', 'Periksa lagi', 'Semak semula'],
  'up_available': ['নতুন আপডেট এসেছে!', 'A new update is available!', 'يتوفر تحديث جديد!', 'نیا اپ ڈیٹ دستیاب ہے!', 'नया अपडेट उपलब्ध है!', 'Yeni bir güncelleme var!', 'Pembaruan baru tersedia!', 'Kemas kini baharu tersedia!'],

  // ---- gazal ----
  'gz_add_tip': ['ফোন থেকে গজল যোগ করুন', 'Add nasheed from phone', 'أضف نشيدًا من الهاتف', 'فون سے ناشید شامل کریں', 'फ़ोन से नशीद जोड़ें', 'Telefondan ilahi ekle', 'Tambah nasyid dari ponsel', 'Tambah nasyid dari telefon'],
  'gz_add': ['গজল যোগ করুন', 'Add nasheed', 'إضافة نشيد', 'ناشید شامل کریں', 'नशीद जोड़ें', 'İlahi ekle', 'Tambah nasyid', 'Tambah nasyid'],
  'gz_sync_tip': ['অনলাইন গজল আপডেট করুন', 'Refresh online nasheeds', 'تحديث الأناشيد عبر الإنترنت', 'آن لائن ناشید اپڈیٹ کریں', 'ऑनलाइन नशीद अपडेट करें', 'Çevrimiçi ilahileri yenile', 'Perbarui nasyid online', 'Kemas kini nasyid dalam talian'],
  'gz_src_tip': ['অনলাইন সোর্স (GitHub / Drive)', 'Online sources (GitHub / Drive)', 'المصادر (GitHub / Drive)', 'آن لائن ذرائع (GitHub / Drive)', 'ऑनलाइन स्रोत (GitHub / Drive)', 'Çevrimiçi kaynaklar (GitHub / Drive)', 'Sumber online (GitHub / Drive)', 'Sumber dalam talian (GitHub / Drive)'],
  'gz_empty': [
    'এখনো কোনো গজল নেই।\nক্লাউড আইকনে GitHub / Google Drive সংযুক্ত করুন।',
    'No nasheeds yet.\nConnect GitHub / Google Drive with the cloud icon.',
    'لا توجد أناشيد بعد.\nاربط GitHub / Google Drive من أيقونة السحابة.',
    'ابھی کوئی ناشید نہیں۔\nکلاؤڈ آئیکن سے GitHub / Google Drive جوڑیں۔',
    'अभी कोई नशीद नहीं है।\nक्लाउड आइकन से GitHub / Google Drive जोड़ें।',
    'Henüz ilahi yok.\nBulut simgesiyle GitHub / Google Drive bağlayın.',
    'Belum ada nasyid.\nHubungkan GitHub / Google Drive lewat ikon awan.',
    'Belum ada nasyid.\nSambungkan GitHub / Google Drive melalui ikon awan.',
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

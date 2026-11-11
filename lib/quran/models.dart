import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Verse {
  final int id;
  final String text;
  final String translation;
  const Verse(this.id, this.text, this.translation);
}

class Surah {
  final int id;
  final String name; // Arabic
  final String transliteration;
  final String meaning; // Bangla meaning
  final String type; // meccan / medinan
  final int totalVerses;
  final List<Verse> verses;

  const Surah(this.id, this.name, this.transliteration, this.meaning, this.type,
      this.totalVerses, this.verses);

  String get typeBn => type == 'meccan' ? 'মক্কী' : 'মাদানী';
}

List<Surah> parseQuran(String raw) {
  final list = jsonDecode(raw) as List;
  return list.map((e) {
    final m = e as Map<String, dynamic>;
    final verses = (m['verses'] as List)
        .map((v) => Verse(v['id'] as int, v['text'] as String, v['translation'] as String))
        .toList();
    return Surah(
      m['id'] as int,
      m['name'] as String,
      m['transliteration'] as String,
      m['translation'] as String,
      m['type'] as String,
      m['total_verses'] as int,
      verses,
    );
  }).toList();
}

class QuranRepo {
  static List<Surah>? _cache;

  static Future<List<Surah>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/quran_bn.json');
    _cache = await compute(parseQuran, raw);
    return _cache!;
  }
}

/// Bookmark ar "shesh pora" shurokkhito rakhe (shared_preferences)
class QuranStore {
  static const _kBookmarks = 'bookmarks';
  static const _kLastSurah = 'last_surah';

  static Future<Set<String>> bookmarks() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_kBookmarks) ?? <String>[]).toSet();
  }

  static Future<void> saveBookmarks(Set<String> b) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kBookmarks, b.toList());
  }

  static Future<int?> lastSurah() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kLastSurah);
  }

  static Future<void> setLastSurah(int id) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLastSurah, id);
  }

  static String key(int surah, int verse) => '$surah:$verse';
}

String toBn(int n) {
  const d = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}

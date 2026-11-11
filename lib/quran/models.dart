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

/// One surah in the history: when it was last read / listened and how often.
class SurahHistoryEntry {
  final int surah;
  final DateTime at;
  final int reads;
  final int listens;
  const SurahHistoryEntry(this.surah, this.at, this.reads, this.listens);
}

/// Every surah the person reads or listens to is remembered here
/// (newest first). Shown on Profile -> History.
class SurahHistory {
  static const _key = 'surah_history_v1';

  static Future<List<SurahHistoryEntry>> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final out = <SurahHistoryEntry>[];
      for (final e in jsonDecode(raw) as List) {
        final m = e as Map;
        out.add(SurahHistoryEntry(
            m['s'] as int,
            DateTime.fromMillisecondsSinceEpoch(m['t'] as int),
            (m['r'] as int?) ?? 0,
            (m['l'] as int?) ?? 0));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<void> record(int surah, {bool listen = false}) async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = await load();
      var r = 0, l = 0;
      final i = list.indexWhere((e) => e.surah == surah);
      if (i >= 0) {
        r = list[i].reads;
        l = list[i].listens;
        list.removeAt(i);
      }
      if (listen) {
        l++;
      } else {
        r++;
      }
      list.insert(0, SurahHistoryEntry(surah, DateTime.now(), r, l));
      if (list.length > 114) list.removeRange(114, list.length);
      await p.setString(
          _key,
          jsonEncode([
            for (final e in list)
              {'s': e.surah, 't': e.at.millisecondsSinceEpoch, 'r': e.reads, 'l': e.listens}
          ]));
    } catch (_) {}
  }
}

/// Optional Bangla pronunciation (uccharon) of every ayah.
/// File: assets/ucharon/quran_ucharon_bn.json  ->  {"1": ["...", ...], "2": [...]}
/// (one list per surah, one string per ayah). Not shown when the file is absent.
class QuranUcharon {
  static Map<int, List<String>>? _cache;
  static bool _tried = false;

  static Future<Map<int, List<String>>?> load() async {
    if (_tried) return _cache;
    _tried = true;
    try {
      final raw = await rootBundle.loadString('assets/ucharon/quran_ucharon_bn.json');
      final m = jsonDecode(raw) as Map<String, dynamic>;
      _cache = m.map((k, v) =>
          MapEntry(int.parse(k), (v as List).map((e) => e.toString()).toList()));
    } catch (_) {
      _cache = null;
    }
    return _cache;
  }
}

String toBn(int n) {
  const d = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}

import 'package:flutter/material.dart';
import '../i18n.dart';
import '../quran/surah_list_screen.dart';
import '../ui/glass.dart';
import 'amal_tracker_screen.dart';
import 'bibaho_screen.dart';
import 'common.dart';
import 'dua_screen.dart';
import 'hadith_screen.dart';
import 'ai_screen.dart';
import 'gazal_screen.dart';
import 'kitab_screen.dart';
import 'prayer_times_screen.dart';
import 'quiz_screen.dart';
import 'quran_shikkha_screen.dart';
import 'tilawat_screen.dart';

class Feature {
  final String id; // translation key is 'f_<id>'
  final IconData icon;
  final Color color;
  final Widget Function() build;
  const Feature(this.id, this.icon, this.color, this.build);

  String get label => tr('f_$id');

  void open(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => build()));
  }
}

final List<Feature> ilmFeatures = [
  Feature('quran', Icons.menu_book_rounded, const Color(0xFFFFC857), () => const SurahListScreen()),
  Feature('hadith', Icons.auto_stories_rounded, const Color(0xFF5EEAD4), () => const HadithScreen()),
  Feature('prayer', Icons.access_time_filled_rounded, const Color(0xFF7DD3FC),
      () => const PrayerTimesScreen()),
  Feature('tilawat', Icons.record_voice_over_rounded, const Color(0xFFFDBA74),
      () => const TilawatScreen()),
  Feature('kitab', Icons.library_books_rounded, const Color(0xFFFCA5A5), () => const KitabScreen()),
  Feature('gazal', Icons.headphones_rounded, const Color(0xFFFDE68A), () => const GazalScreen()),
  Feature('qshikkha', Icons.school_rounded, const Color(0xFFC4B5FD),
      () => const QuranShikkhaScreen()),
  Feature('dua', Icons.back_hand_rounded, const Color(0xFFF9A8D4), () => const DuaScreen()),
];

final List<Feature> shebaFeatures = [
  Feature('quiz', Icons.lightbulb_rounded, const Color(0xFFBEF264), () => const QuizScreen()),
  Feature('amal', Icons.checklist_rounded, const Color(0xFF93C5FD),
      () => const AmalTrackerScreen()),
  Feature('ai', Icons.auto_awesome_rounded, const Color(0xFF6EE7B7),
      () => const AiScreen()),
  Feature('bibaho', Icons.diversity_1_rounded, const Color(0xFFFDA4AF), () => const BibahoScreen()),
];

List<Feature> get allFeatures => [...ilmFeatures, ...shebaFeatures];

/// Finds a menu item by its id (used by the home banners).
Feature? featureById(String id) {
  for (final f in allFeatures) {
    if (f.id == id) return f;
  }
  return null;
}

/// Search over every menu item.
class FeatureSearchScreen extends StatefulWidget {
  const FeatureSearchScreen({super.key});

  @override
  State<FeatureSearchScreen> createState() => _FeatureSearchScreenState();
}

class _FeatureSearchScreenState extends State<FeatureSearchScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim();
    final ql = q.toLowerCase();
    final list = allFeatures
        .where((f) => q.isEmpty || f.label.toLowerCase().contains(ql))
        .toList();
    return GlassPage(
      title: tr('search'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: GlassCard(
              radius: 26,
              blur: 0,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: tr('search_menu'),
                  hintStyle: TextStyle(color: wh(.6)),
                  prefixIcon: Icon(Icons.search_rounded, color: wh(.8)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final f = list[i];
                return GlassCard(
                  blur: 0,
                  radius: 18,
                  opacity: 0.10,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: () => f.open(context),
                  child: Row(
                    children: [
                      Icon(f.icon, color: f.color),
                      const SizedBox(width: 14),
                      Expanded(child: Text(f.label, style: const TextStyle(fontSize: 17))),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

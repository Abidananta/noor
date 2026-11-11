import 'package:flutter/material.dart';
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
  final String label;
  final IconData icon;
  final Color color;
  final Widget Function() build;
  const Feature(this.label, this.icon, this.color, this.build);

  void open(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => build()));
  }
}

final List<Feature> ilmFeatures = [
  Feature('কুরআন', Icons.menu_book_rounded, const Color(0xFFFFC857), () => const SurahListScreen()),
  Feature('হাদীস', Icons.auto_stories_rounded, const Color(0xFF5EEAD4), () => const HadithScreen()),
  Feature('নামাযের সময়', Icons.access_time_filled_rounded, const Color(0xFF7DD3FC),
      () => const PrayerTimesScreen()),
  Feature('তিলাওয়াত', Icons.record_voice_over_rounded, const Color(0xFFFDBA74),
      () => const TilawatScreen()),
  Feature('কিতাব', Icons.library_books_rounded, const Color(0xFFFCA5A5), () => const KitabScreen()),
  Feature('গজল', Icons.headphones_rounded, const Color(0xFFFDE68A), () => const GazalScreen()),
  Feature('কুরআন শিক্ষা', Icons.school_rounded, const Color(0xFFC4B5FD),
      () => const QuranShikkhaScreen()),
  Feature("দু'আ", Icons.back_hand_rounded, const Color(0xFFF9A8D4), () => const DuaScreen()),
];

final List<Feature> shebaFeatures = [
  Feature('তালীমে কুইজ', Icons.lightbulb_rounded, const Color(0xFFBEF264), () => const QuizScreen()),
  Feature('আমল ট্রাকার', Icons.checklist_rounded, const Color(0xFF93C5FD),
      () => const AmalTrackerScreen()),
  Feature('AI জিজ্ঞাসা', Icons.auto_awesome_rounded, const Color(0xFF6EE7B7),
      () => const AiScreen()),
  Feature('বিবাহ', Icons.diversity_1_rounded, const Color(0xFFFDA4AF), () => const BibahoScreen()),
];

List<Feature> get allFeatures => [...ilmFeatures, ...shebaFeatures];

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
    final list = allFeatures.where((f) => q.isEmpty || f.label.contains(q)).toList();
    return GlassPage(
      title: 'খুঁজুন',
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
                  hintText: 'মেনু খুঁজুন',
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

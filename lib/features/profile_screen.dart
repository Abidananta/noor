import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_service.dart';
import '../auth/edit_profile_screen.dart';
import '../auth/user_avatar.dart';
import '../i18n.dart';
import '../quran/bookmarks_screen.dart';
import '../quran/models.dart';
import '../quran/reader_screen.dart';
import '../ui/glass.dart';
import 'amal_tracker_screen.dart';
import 'common.dart';
import 'prayer_times_screen.dart';
import 'gazal_screen.dart';
import 'history_screen.dart';
import 'kitab_data.dart';

/// User's display name (empty = not set yet).
final ValueNotifier<String> profileName = ValueNotifier<String>('');

Future<void> loadProfile() async {
  final p = await SharedPreferences.getInstance();
  profileName.value = p.getString('profile_name') ?? '';
}

/// First letter of the name for avatars; "SM" until a name is set.
String initialOf(String name) {
  final t = name.trim();
  if (t.isEmpty) return 'SM';
  return String.fromCharCode(t.runes.first).toUpperCase();
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _amalToday = 0;
  int _streak = 0;
  int _bookmarks = 0;
  int _booksDone = 0;
  Surah? _last;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _amalKey(DateTime d) =>
      'amal_${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayCount = (p.getStringList(_amalKey(today)) ?? <String>[]).length;
    // streak = consecutive days (ending today, or yesterday if today is empty) with any amal
    int streak = 0;
    for (int i = todayCount > 0 ? 0 : 1; i < 400; i++) {
      final d = today.subtract(Duration(days: i));
      if ((p.getStringList(_amalKey(d)) ?? <String>[]).isEmpty) break;
      streak++;
    }

    final booksDone = await KitabHistory.finishedCount();

    final bm = (await QuranStore.bookmarks()).length;
    Surah? last;
    final lastId = await QuranStore.lastSurah();
    if (lastId != null) {
      try {
        final all = await QuranRepo.load();
        if (lastId >= 1 && lastId <= all.length) last = all[lastId - 1];
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _amalToday = todayCount;
      _streak = streak;
      _bookmarks = bm;
      _booksDone = booksDone;
      _last = last;
    });
  }

  Future<void> _go(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panelColor,
        title: Text(tr('pf_logout_title')),
        content: Text(tr('pf_logout_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('no'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('pf_logout_yes'), style: const TextStyle(color: Color(0xFFF87171)))),
        ],
      ),
    );
    if (ok != true) return;
    // The app switches back to the register / login screen by itself.
    await logoutAccount();
  }

  Future<void> _resetAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panelColor,
        title: Text(tr('pf_reset_title')),
        content: Text(tr('pf_reset_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('no'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('yes_delete'), style: const TextStyle(color: Color(0xFFF87171)))),
        ],
      ),
    );
    if (ok != true) return;
    final p = await SharedPreferences.getInstance();
    await p.clear();
    profileName.value = '';
    cityIndex.value = 0;
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('pf_deleted')), duration: const Duration(seconds: 1)));
    }
    // Accounts were deleted too, so go back to register / login.
    await resetAuthState();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        children: [
          Text(tr('profile'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ValueListenableBuilder<String>(
            valueListenable: profileName,
            builder: (_, name, __) => GlassCard(
              blur: 0,
              padding: const EdgeInsets.all(18),
              onTap: () => _go(const EditProfileScreen()),
              child: Row(
                children: [
                  const UserAvatar(radius: 32, fontSize: 26),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.isEmpty ? tr('pf_set_name') : name,
                            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                        if ((currentAccount.value?.email ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(currentAccount.value!.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: wh(.7))),
                        ],
                        const SizedBox(height: 4),
                        ValueListenableBuilder<int>(
                          valueListenable: cityIndex,
                          builder: (_, c, __) => Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: kGold),
                              const SizedBox(width: 4),
                              Text(kCities[c].label,
                                  style: TextStyle(fontSize: 14, color: wh(.8))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_rounded, color: wh(.7)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _Stat(Icons.checklist_rounded, bnDigits('$_amalToday/9'), tr('pf_today_amal'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _Stat(Icons.local_fire_department_rounded, bnDigits('$_streak'), tr('pf_streak'))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Stat(Icons.bookmark_rounded, bnDigits('$_bookmarks'), tr('pf_bookmarks'))),
              const SizedBox(width: 10),
              Expanded(child: _Stat(Icons.library_books_rounded, bnDigits('$_booksDone'), tr('pf_books_done'))),
            ],
          ),
          if (_last != null) ...[
            const SizedBox(height: 14),
            GlassCard(
              tint: kGold,
              opacity: 0.14,
              blur: 0,
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () => _go(ReaderScreen(surah: _last!)),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: kGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('pf_last_surah'), style: TextStyle(fontSize: 12.5, color: wh(.75))),
                        Text(_last!.transliteration,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(tr('pf_shortcuts'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _Tile(Icons.history_rounded, tr('pf_history'), () => _go(const HistoryScreen())),
          _Tile(Icons.access_time_filled_rounded, tr('f_prayer'), () => _go(const PrayerTimesScreen())),
          _Tile(Icons.bookmark_border_rounded, tr('pf_quran_bm'), () => _go(const BookmarksScreen())),
          _Tile(Icons.checklist_rounded, tr('f_amal'), () => _go(const AmalTrackerScreen())),
          _Tile(Icons.headphones_rounded, tr('f_gazal'), () => _go(const GazalScreen())),
          const SizedBox(height: 18),
          Text(tr('pf_area'),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: cityIndex,
            builder: (_, sel, __) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < kCities.length; i++)
                  ChoiceChip(
                    label: Text(kCities[i].label),
                    selected: i == sel,
                    onSelected: (_) => saveCity(i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(tr('pf_app'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _Tile(Icons.delete_outline_rounded, tr('pf_reset'), _resetAll,
              color: const Color(0xFFF87171)),
          const SizedBox(height: 12),
          Text(tr('pf_account'),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _Tile(Icons.edit_rounded, tr('pf_edit'), () => _go(const EditProfileScreen())),
          _Tile(Icons.logout_rounded, tr('pf_logout'), _logout,
              color: const Color(0xFFFB923C)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 0,
      radius: 18,
      opacity: 0.10,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: kGold, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: wh(.72))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _Tile(this.icon, this.label, this.onTap, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        blur: 0,
        radius: 18,
        opacity: 0.10,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: color ?? kMint),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 16, color: color))),
            Icon(Icons.chevron_right_rounded, color: wh(.6)),
          ],
        ),
      ),
    );
  }
}

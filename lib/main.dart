import 'dart:async';
import 'package:flutter/material.dart';
import 'auth/auth_screen.dart';
import 'auth/auth_service.dart';
import 'auth/user_avatar.dart';
import 'features/calendar_util.dart';
import 'features/common.dart';
import 'features/feature.dart';
import 'features/prayer_times_screen.dart';
import 'features/profile_screen.dart';
import 'features/settings_screen.dart';
import 'i18n.dart';
import 'ui/glass.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadLang();
  loadCity();
  loadProfile();
  await loadTheme();
  await loadAuth();
  runApp(const NoorApp());
}

class NoorApp extends StatelessWidget {
  const NoorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The key makes the whole app rebuild when the language changes.
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (_, lang, __) => _buildApp(lang),
    );
  }

  Widget _buildApp(String lang) {
    // Rebuild the theme when the person picks another app colour.
    return ValueListenableBuilder<int>(
      valueListenable: themeIndex,
      builder: (_, __, ___) => _materialApp(lang),
    );
  }

  Widget _materialApp(String lang) {
    return MaterialApp(
      key: ValueKey(lang),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      title: 'Noor',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: currentTheme.seed,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Remembered so the same tab is shown again after a language change.
int _lastTab = 0;

/// Register / login screen until someone is signed in, then the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Account?>(
      valueListenable: currentAccount,
      builder: (_, acc, __) {
        if (acc == null) {
          _lastTab = 0;
          return const AuthScreen();
        }
        return const RootScreen();
      },
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = _lastTab;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const MenuScreen(),
      const SettingsScreen(),
      const ProfileScreen(),
    ];
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: SafeArea(bottom: false, child: pages[_index]),
        bottomNavigationBar: _GlassNav(
          index: _index,
          onChanged: (i) => setState(() {
            _index = i;
            _lastTab = i;
          }),
        ),
      ),
    );
  }
}

class _GlassNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _GlassNav({required this.index, required this.onChanged});

  static const _icons = [
    Icons.menu_book_rounded,
    Icons.grid_view_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: GlassCard(
          radius: 32,
          blur: 24,
          opacity: 0.14,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 4; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: i == index
                          ? LinearGradient(colors: [kGold.withOpacity(.45), kGold.withOpacity(.18)])
                          : null,
                      border: i == index ? Border.all(color: kGold.withOpacity(.55)) : null,
                    ),
                    child: i == 3
                        ? const UserAvatar(radius: 14, fontSize: 11)
                        : Icon(_icons[i],
                            size: 26, color: i == index ? Colors.white : wh(.75)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Home ----------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        const _Header(),
        const SizedBox(height: 16),
        const _DateCard(),
        const SizedBox(height: 14),
        const _PrayerCard(),
        const SizedBox(height: 14),
        const BannerCarousel(),
        const SizedBox(height: 22),
        _SectionTitle(tr('sec_ilm'), kMint, showSearch: true),
        const SizedBox(height: 12),
        _Grid(items: ilmFeatures),
        const SizedBox(height: 22),
        _SectionTitle(tr('sec_seba'), kGold),
        const SizedBox(height: 12),
        _Grid(items: shebaFeatures),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  void _pickCity(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: panelColor,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(tr('pick_area'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (int i = 0; i < kCities.length; i++)
              ListTile(
                title: Text(kCities[i].label),
                trailing: i == cityIndex.value
                    ? const Icon(Icons.check_rounded, color: kGold)
                    : null,
                onTap: () {
                  saveCity(i);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bd = DateTime.now().toUtc().add(const Duration(hours: 6));
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: wh(.6), width: 1.5),
          ),
          child: const UserAvatar(radius: 21, fontSize: 16),
        ),
        const SizedBox(width: 10),
        _Pill(icon: Icons.calendar_month_outlined, text: shortDateBn(bd)),
        const Spacer(),
        ValueListenableBuilder<int>(
          valueListenable: cityIndex,
          builder: (_, c, __) => _Pill(
            icon: Icons.location_on_outlined,
            text: kCities[c].label,
            trailing: const Icon(Icons.keyboard_arrow_down, size: 20),
            onTap: () => _pickCity(context),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _Pill({required this.icon, required this.text, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      blur: 12,
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: kGold),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 15.5)),
          if (trailing != null) ...[const SizedBox(width: 2), trailing!],
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard();

  @override
  Widget build(BuildContext context) {
    final bd = DateTime.now().toUtc().add(const Duration(hours: 6));
    return GlassCard(
      blur: 18,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Text('${hijriBn(bd)} · ${weekdayBn(bd)} 🌙',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            // The Bangla (Bongabdo) calendar line only makes sense in Bangla.
            if (appLang.value == 'bn')
              Text(banglaDateBn(bd), style: TextStyle(fontSize: 13.5, color: wh(.72))),
          ],
        ),
      ),
    );
  }
}

class _PrayerCard extends StatefulWidget {
  const _PrayerCard();

  @override
  State<_PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<_PrayerCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  PrayerTimes _on(DateTime bd, City c) =>
      computePrayerTimes(bd.year, bd.month, bd.day, c.lat, c.lng);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: cityIndex,
      builder: (context, ci, _) {
        final c = kCities[ci];
        final nowUtc = DateTime.now().toUtc();
        final bd = nowUtc.add(const Duration(hours: 6));
        final y = _on(bd.subtract(const Duration(days: 1)), c);
        final t = _on(bd, c);
        final n = _on(bd.add(const Duration(days: 1)), c);

        // segment i runs from bounds[i] to bounds[i + 1]
        final bounds = <DateTime>[y.isha, t.fajr, t.sunrise, t.dhuhr, t.asr, t.maghrib, t.isha, n.fajr];
        final names = [
          tr('p_isha'),
          tr('p_fajr'),
          tr('p_sunrise'),
          tr('p_dhuhr'),
          tr('p_asr'),
          tr('p_maghrib'),
          tr('p_isha'),
        ];
        int idx = 0;
        for (int i = 0; i < names.length; i++) {
          if (!nowUtc.isBefore(bounds[i])) idx = i;
        }
        final start = bounds[idx];
        final end = bounds[idx + 1];
        final total = end.difference(start).inSeconds;
        final done = nowUtc.difference(start).inSeconds;
        double frac = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0).toDouble();
        if (frac < 0.02) frac = 0.02;

        final sunSpan = t.maghrib.difference(t.sunrise).inSeconds;
        final sunT = sunSpan <= 0
            ? 0.0
            : (nowUtc.difference(t.sunrise).inSeconds / sunSpan).clamp(0.0, 1.0).toDouble();

        final gap = idx == 2; // between sunrise and Dhuhr: no prayer time
        final title = gap ? tr('p_dhuhr_start') : trf('p_ends', {'p': names[idx]});
        final remain = remainText(end.difference(nowUtc));

        return GlassCard(
          blur: 20,
          opacity: 0.13,
          padding: EdgeInsets.zero,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen())),
          child: Column(
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ArcPainter(sunT),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${tr('p_fajr')} ${bdTime(t.fajr)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('${tr('p_isha')} ${bdTime(t.isha)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SunTag(Icons.wb_twilight_rounded, bdTime(t.sunrise)),
                            _SunTag(Icons.wb_twilight_rounded, bdTime(t.maghrib)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: wh(.18)),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                        Text(bdTime(gap ? t.dhuhr : end),
                            style: const TextStyle(fontSize: 17, color: kGold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: wh(.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: frac,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                                colors: [Color(0xFF6EE7B7), Color(0xFFF2C46D)]),
                            boxShadow: [
                              BoxShadow(color: kGold.withOpacity(.45), blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.circle, size: 11, color: gap ? kGold : kMint),
                          const SizedBox(width: 6),
                          Text(gap ? tr('p_none') : tr('p_running'),
                              style: TextStyle(color: gap ? kGold : kMint, fontSize: 15.5)),
                        ]),
                        Text(bnDigits(remain), style: const TextStyle(fontSize: 15.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double t;
  _ArcPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p0 = Offset(28, size.height - 34);
    final p2 = Offset(size.width - 28, size.height - 34);
    final c = Offset(size.width / 2, -size.height * 0.15);
    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(c.dx, c.dy, p2.dx, p2.dy);

    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = wh(.28));

    final m = path.computeMetrics().first;
    canvas.drawPath(
        m.extractPath(0, m.length * t),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..color = kGold);

    final pos = m.getTangentForOffset(m.length * t)!.position;
    canvas.drawCircle(
        pos,
        18,
        Paint()
          ..color = kGold.withOpacity(.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    canvas.drawCircle(pos, 8, Paint()..color = kGold);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.t != t;
}

class _SunTag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SunTag(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: wh(.7)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: wh(.7), fontSize: 13)),
      ]);
}

// ---------------- Banner ----------------

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  // (text key, menu item id it opens, gradient start, gradient end)
  // To point a banner somewhere else, change the 2nd value to any Feature id
  // from lib/features/feature.dart (quran, hadith, prayer, tilawat, kitab,
  // gazal, qshikkha, dua, quiz, amal, ai, bibaho).
  static const _banners = [
    ('b_discount', 'kitab', Color(0xFFF59E0B), Color(0xFFB45309)),
    ('b_ramadan', 'amal', Color(0xFF10B981), Color(0xFF047857)),
    ('b_course', 'qshikkha', Color(0xFF38BDF8), Color(0xFF0369A1)),
    ('b_newkitab', 'kitab', Color(0xFFA78BFA), Color(0xFF6D28D9)),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % _banners.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: wh(.3)),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: SizedBox(
          height: 140,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: _banners.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final b = _banners[i];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => featureById(b.$2)?.open(context),
                    child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [b.$3, b.$4],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: wh(.16)),
                          ),
                        ),
                        Positioned(
                          right: 40,
                          bottom: -50,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: wh(.10)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Text(tr(b.$1),
                                style: const TextStyle(
                                    fontSize: 28,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                        ),
                        PositionedDirectional(
                          end: 16,
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: wh(.22)),
                            child: Icon(
                                isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                                size: 18,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _banners.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: i == _page ? Colors.white : wh(.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Sections & grid ----------------

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color bar;
  final bool showSearch;
  const _SectionTitle(this.text, this.bar, {this.showSearch = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: bar,
            boxShadow: [BoxShadow(color: bar.withOpacity(.6), blurRadius: 10)],
          ),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
        const Spacer(),
        if (showSearch)
          GlassCard(
            radius: 22,
            blur: 10,
            opacity: 0.16,
            tint: kMint,
            padding: const EdgeInsets.all(10),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FeatureSearchScreen())),
            child: const Icon(Icons.search_rounded, size: 24),
          ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Feature> items;
  const _Grid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.84,
      children: items
          .map((e) => GlassCard(
                radius: 20,
                blur: 12,
                opacity: 0.10,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                onTap: () => e.open(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [e.color.withOpacity(.38), e.color.withOpacity(.12)],
                        ),
                        border: Border.all(color: e.color.withOpacity(.45)),
                      ),
                      child: Icon(e.icon, size: 26, color: e.color),
                    ),
                    const SizedBox(height: 8),
                    Text(e.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, height: 1.2)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ---------------- Menu tab ----------------

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        Row(
          children: [
            Text(tr('menu'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const Spacer(),
            _Pill(
              icon: Icons.language_rounded,
              text: currentLangName,
              onTap: () => showLanguageSheet(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle(tr('sec_ilm'), kMint),
        const SizedBox(height: 12),
        _Grid(items: ilmFeatures),
        const SizedBox(height: 22),
        _SectionTitle(tr('sec_seba'), kGold),
        const SizedBox(height: 12),
        _Grid(items: shebaFeatures),
      ],
    );
  }
}

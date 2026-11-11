import 'dart:async';
import 'package:flutter/material.dart';
import 'features/calendar_util.dart';
import 'features/common.dart';
import 'features/feature.dart';
import 'features/prayer_times_screen.dart';
import 'features/profile_screen.dart';
import 'ui/glass.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  loadCity();
  loadProfile();
  runApp(const NoorApp());
}

class NoorApp extends StatelessWidget {
  const NoorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noor',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF2E9E3A),
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const MenuScreen(),
      const _Placeholder('নোটিফিকেশন'),
      const ProfileScreen(),
    ];
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: SafeArea(bottom: false, child: pages[_index]),
        bottomNavigationBar: _GlassNav(
          index: _index,
          onChanged: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(title, style: const TextStyle(fontSize: 20)));
}

class _GlassNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _GlassNav({required this.index, required this.onChanged});

  static const _icons = [
    Icons.menu_book_rounded,
    Icons.grid_view_rounded,
    Icons.notifications_none_rounded,
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
                        ? ValueListenableBuilder<String>(
                            valueListenable: profileName,
                            builder: (_, name, __) => CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFFE91E63),
                              child: Text(initialOf(name),
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          )
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
        const _SectionTitle('ইলম ও আমল', kMint, showSearch: true),
        const SizedBox(height: 12),
        _Grid(items: ilmFeatures),
        const SizedBox(height: 22),
        const _SectionTitle('সেবা', kGold),
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
      backgroundColor: const Color(0xFF0C3B31),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('এলাকা নির্বাচন করুন',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (int i = 0; i < kCities.length; i++)
              ListTile(
                title: Text(kCities[i].name),
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
          child: ValueListenableBuilder<String>(
            valueListenable: profileName,
            builder: (_, name, __) => CircleAvatar(
              radius: 21,
              backgroundColor: const Color(0xFFE91E63),
              child: Text(initialOf(name),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _Pill(icon: Icons.calendar_month_outlined, text: shortDateBn(bd)),
        const Spacer(),
        ValueListenableBuilder<int>(
          valueListenable: cityIndex,
          builder: (_, c, __) => _Pill(
            icon: Icons.location_on_outlined,
            text: kCities[c].name,
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
        const names = ['ইশা', 'ফজর', 'সূর্যোদয়', 'যোহর', 'আসর', 'মাগরিব', 'ইশা'];
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
        final title = gap ? 'যোহর শুরু' : '${names[idx]} শেষ';
        final left = end.difference(nowUtc);
        final h = left.inHours;
        final m = left.inMinutes % 60;
        final remain = h > 0 ? '$h ঘণ্টা $m মিনিট বাকি' : '${m < 1 ? 1 : m} মিনিট বাকি';

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
                            Text('ফজর ${bdTime(t.fajr)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('ইশা ${bdTime(t.isha)}',
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
                          Text(gap ? 'এখন ওয়াক্ত নেই' : 'চলমান',
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

  static const _banners = [
    ('মাস শেষে\nবিশেষ ছাড়', Color(0xFFF59E0B), Color(0xFFB45309)),
    ('রমযানের\nপ্রস্তুতি', Color(0xFF10B981), Color(0xFF047857)),
    ('কুরআন শিক্ষা\nকোর্স', Color(0xFF38BDF8), Color(0xFF0369A1)),
    ('নতুন কিতাব\nএসেছে', Color(0xFFA78BFA), Color(0xFF6D28D9)),
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
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [b.$2, b.$3],
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
                            child: Text(b.$1,
                                style: const TextStyle(
                                    fontSize: 28,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
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
        const Text('মেনু', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        const _SectionTitle('ইলম ও আমল', kMint),
        const SizedBox(height: 12),
        _Grid(items: ilmFeatures),
        const SizedBox(height: 22),
        const _SectionTitle('সেবা', kGold),
        const SizedBox(height: 12),
        _Grid(items: shebaFeatures),
      ],
    );
  }
}

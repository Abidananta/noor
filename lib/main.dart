import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const NoorApp());

const kGreen = Color(0xFF2E9E3A);
const kOrange = Color(0xFFFF9800);
const kBg = Color(0xFFF1F3F6);
const kTile = Color(0xFFEEF1F5);

class NoorApp extends StatelessWidget {
  const NoorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noor',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kGreen,
        scaffoldBackgroundColor: kBg,
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
      const _Placeholder('শপ'),
      const _Placeholder('মেনু'),
      const _Placeholder('নোটিফিকেশন'),
      const _Placeholder('প্রোফাইল'),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: kBg,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'হোম'),
          NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'শপ'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'মেনু'),
          NavigationDestination(icon: Icon(Icons.notifications_none), label: 'নোটিফিকেশন'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'প্রোফাইল'),
        ],
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

// ---------------- Home ----------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const ilm = [
    _Item('কুরআন', Icons.menu_book, Color(0xFFB8860B)),
    _Item('হাদীস', Icons.auto_stories, Color(0xFF2E7D6B)),
    _Item('নামাযের সময়', Icons.access_time_filled, Color(0xFF2B7BB9)),
    _Item('তিলাওয়াত', Icons.record_voice_over, Color(0xFF6D4C41)),
    _Item('কিতাব', Icons.library_books, Color(0xFFC0392B)),
    _Item('প্রবন্ধ', Icons.edit_note, Color(0xFFB8860B)),
    _Item('কুরআন শিক্ষা', Icons.school, Color(0xFF8D6E63)),
    _Item('দু\'আ', Icons.back_hand, Color(0xFFD99058)),
  ];

  static const sheba = [
    _Item('তালীমে কুইজ', Icons.lightbulb, Color(0xFF8BC34A)),
    _Item('আমল ট্রাকার', Icons.checklist, Color(0xFF455A64)),
    _Item('দ্বীনি জিজ্ঞাসা', Icons.phone_in_talk, Color(0xFF1E9E6A)),
    _Item('বিবাহ', Icons.diversity_1, Color(0xFF2E7D32)),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      children: [
        const _Header(),
        const SizedBox(height: 14),
        const _DateCard(),
        const SizedBox(height: 14),
        const _PrayerCard(),
        const SizedBox(height: 14),
        const BannerCarousel(),
        const SizedBox(height: 18),
        const _SectionTitle('ইলম ও আমল', kGreen, showSearch: true),
        const SizedBox(height: 10),
        _Grid(items: ilm),
        const SizedBox(height: 18),
        const _SectionTitle('সেবা', kOrange),
        const SizedBox(height: 10),
        _Grid(items: sheba),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFFE91E63),
          child: Text('SM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        const _Pill(icon: Icons.calendar_month_outlined, text: 'অক্টোবর ২৭'),
        const Spacer(),
        _Pill(
          icon: Icons.location_on_outlined,
          text: 'ঢাকা',
          trailing: const Icon(Icons.keyboard_arrow_down, size: 20),
          onTap: () {},
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
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF455A64), width: 1.2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 16)),
            if (trailing != null) ...[const SizedBox(width: 4), trailing!],
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDeco() => BoxDecoration(
      color: const Color(0xFFF8F9FB),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
    );

class _DateCard extends StatelessWidget {
  const _DateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: _cardDeco(),
      child: const Column(
        children: [
          Text('১৫ জুমাদাল উলা ১৪৪৮ হি. ইয়াওমুছ ছুলাছা 🌙',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('মঙ্গলবার, ১১ কার্তিক ১৪৩৩ বঙ্গাব্দ, হেমন্তকাল',
              style: TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard();

  // Pore Aladhan API theke real somoy ashbe. Ekhon static.
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDeco(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 120,
            color: const Color(0xFFEFF2F4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('তাহাজ্জুদ শেষ ৪:৪০ মি.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('ফজর ৪:৪৫ মি.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SunTag(Icons.wb_twilight, '৫:২৩'),
                    _SunTag(Icons.wb_twilight, '৬:০১'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('তাহাজ্জুদ শেষ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                    Text('০৪:৪০', style: TextStyle(fontSize: 17)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    value: 0.57,
                    minHeight: 14,
                    color: Color(0xFF12B31F),
                    backgroundColor: Color(0xFFE3E6EA),
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.circle, size: 12, color: kGreen),
                      SizedBox(width: 6),
                      Text('চলমান', style: TextStyle(color: kGreen, fontSize: 16)),
                    ]),
                    Text('৪ ঘণ্টা ১৭ মিনিট বাকি', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SunTag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SunTag(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.black54)),
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
    ('মাস শেষে বিশেষ ছাড়', Color(0xFF43A047), Color(0xFFA5D6A7)),
    ('রমযানের প্রস্তুতি', Color(0xFF00897B), Color(0xFF80CBC4)),
    ('কুরআন শিক্ষা কোর্স', Color(0xFF558B2F), Color(0xFFC5E1A5)),
    ('নতুন কিতাব এসেছে', Color(0xFF2E7D32), Color(0xFFA5D6A7)),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % _banners.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 130,
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
                    gradient: LinearGradient(colors: [b.$3, b.$2]),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(b.$1,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                );
              },
            ),
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _banners.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page ? Colors.black87 : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
          height: 30,
          decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
        const Spacer(),
        if (showSearch)
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
            child: const Icon(Icons.search, color: Colors.white),
          ),
      ],
    );
  }
}

class _Item {
  final String label;
  final IconData icon;
  final Color color;
  const _Item(this.label, this.icon, this.color);
}

class _Grid extends StatelessWidget {
  final List<_Item> items;
  const _Grid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.97,
      children: items
          .map((e) => Material(
                color: kTile,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${e.label} shighroi ashche'), duration: const Duration(seconds: 1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(e.icon, size: 36, color: e.color),
                      const SizedBox(height: 10),
                      Text(e.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n.dart';
import '../ui/glass.dart';
import 'bookmarks_screen.dart';
import 'models.dart';
import 'quran_audio.dart';

const _bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
const _kPos = 'full_quran_pos';

/// First ayah (surah, ayah) of each of the 30 paras (juz), standard Madani mushaf.
const _juzStart = <(int, int)>[
  (1, 1), (2, 142), (2, 253), (3, 93), (4, 24), (4, 148), (5, 82), (6, 111), (7, 88),
  (8, 41), (9, 93), (11, 6), (12, 53), (15, 1), (17, 1), (18, 75), (21, 1), (23, 1),
  (25, 21), (27, 56), (29, 46), (33, 31), (36, 28), (39, 32), (41, 47), (46, 1),
  (51, 31), (58, 1), (67, 1), (78, 1),
];

/// Traditional para names (first words).
const _juzName = <String>[
  'الٓمٓ', 'سَيَقُولُ', 'تِلْكَ الرُّسُلُ', 'لَنْ تَنَالُوا', 'وَالْمُحْصَنَاتُ',
  'لَا يُحِبُّ اللَّهُ', 'وَإِذَا سَمِعُوا', 'وَلَوْ أَنَّنَا', 'قَالَ الْمَلَأُ', 'وَاعْلَمُوا',
  'يَعْتَذِرُونَ', 'وَمَا مِنْ دَابَّةٍ', 'وَمَا أُبَرِّئُ', 'رُبَمَا', 'سُبْحَانَ الَّذِي',
  'قَالَ أَلَمْ', 'اقْتَرَبَ', 'قَدْ أَفْلَحَ', 'وَقَالَ الَّذِينَ', 'أَمَّنْ خَلَقَ',
  'اتْلُ مَا أُوحِيَ', 'وَمَنْ يَقْنُتْ', 'وَمَا لِيَ', 'فَمَنْ أَظْلَمُ', 'إِلَيْهِ يُرَدُّ',
  'حم', 'قَالَ فَمَا خَطْبُكُمْ', 'قَدْ سَمِعَ اللَّهُ', 'تَبَارَكَ الَّذِي', 'عَمَّ',
];

/// One row of the continuous Quran: a surah header (verse == -1)
/// or one ayah (verse = index inside surah.verses).
class _Item {
  final int surah;
  final int verse;
  const _Item(this.surah, this.verse);
}

/// The whole Quran in one scrolling page: Arabic, Bangla pronunciation
/// (when the data file is present) and Bangla translation, surah after surah.
/// The surah list lives in the Tilawat page.
class FullQuranScreen extends StatefulWidget {
  const FullQuranScreen({super.key});

  @override
  State<FullQuranScreen> createState() => _FullQuranScreenState();
}

class _FullQuranScreenState extends State<FullQuranScreen> {
  final ItemScrollController _ctrl = ItemScrollController();
  final ItemPositionsListener _positions = ItemPositionsListener.create();
  final ValueNotifier<int> _cur = ValueNotifier<int>(1);
  final ValueNotifier<int> _curJuz = ValueNotifier<int>(1);
  List<int> _juzIdx = []; // item index where each para starts
  final Map<int, int> _juzAt = {}; // item index -> para number

  List<Surah> _all = [];
  List<_Item> _items = [];
  List<int> _headerIdx = [];
  Map<int, List<String>>? _uch;
  Set<String> _marks = {};
  double _size = 28;
  int _start = 0;
  int _firstIdx = 0;
  int _recorded = 0;
  bool _ready = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final all = await QuranRepo.load();
      final uch = await QuranUcharon.load();
      final marks = await QuranStore.bookmarks();
      final p = await SharedPreferences.getInstance();
      final items = <_Item>[];
      final hi = List<int>.filled(all.length + 2, 0);
      for (final s in all) {
        hi[s.id] = items.length;
        items.add(_Item(s.id, -1));
        for (int i = 0; i < s.verses.length; i++) {
          items.add(_Item(s.id, i));
        }
      }
      final juzIdx = <int>[];
      _juzAt.clear();
      for (int j = 0; j < _juzStart.length; j++) {
        final (sid, ay) = _juzStart[j];
        if (sid >= hi.length) continue;
        final at = ay <= 1 ? hi[sid] : hi[sid] + ay;
        juzIdx.add(at);
        _juzAt[at] = j + 1;
      }
      var start = p.getInt(_kPos) ?? 0;
      if (start < 0 || start >= items.length) start = 0;
      if (!mounted) return;
      setState(() {
        _all = all;
        _uch = uch;
        _marks = marks;
        _items = items;
        _headerIdx = hi;
        _juzIdx = juzIdx;
        _start = start;
        _firstIdx = start;
        _ready = true;
      });
      _cur.value = items[start].surah;
      _curJuz.value = _juzOf(start);
      _positions.itemPositions.addListener(_onPos);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  int _juzOf(int itemIndex) {
    for (int j = _juzIdx.length - 1; j >= 0; j--) {
      if (_juzIdx[j] <= itemIndex) return j + 1;
    }
    return 1;
  }

  void _onPos() {
    final pos = _positions.itemPositions.value;
    if (pos.isEmpty) return;
    var first = -1;
    for (final p in pos) {
      if (p.itemTrailingEdge > 0 && (first == -1 || p.index < first)) first = p.index;
    }
    if (first < 0 || first >= _items.length) return;
    _firstIdx = first;
    final s = _items[first].surah;
    if (_cur.value != s) _cur.value = s;
    final jz = _juzOf(first);
    if (_curJuz.value != jz) _curJuz.value = jz;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), _persist);
  }

  Future<void> _persist() async {
    if (_items.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kPos, _firstIdx);
    final s = _items[_firstIdx].surah;
    QuranStore.setLastSurah(s);
    if (s != _recorded) {
      _recorded = s;
      SurahHistory.record(s);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_ready) {
      _positions.itemPositions.removeListener(_onPos);
      _persist();
    }
    _cur.dispose();
    _curJuz.dispose();
    super.dispose();
  }

  Future<void> _jump() async {
    final index = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: panelColor,
      builder: (_) => _JumpSheet(
        all: _all,
        headerIdx: _headerIdx,
        juzIdx: _juzIdx,
        current: _cur.value,
        currentJuz: _curJuz.value,
      ),
    );
    if (index == null || index < 0 || index >= _items.length) return;
    _ctrl.jumpTo(index: index);
  }

  Future<void> _toggleMark(int surah, int verseNo) async {
    final k = QuranStore.key(surah, verseNo);
    setState(() => _marks.contains(k) ? _marks.remove(k) : _marks.add(k));
    await QuranStore.saveBookmarks(_marks);
  }

  void _copy(Surah s, Verse v) {
    Clipboard.setData(ClipboardData(
        text: '${v.text}\n\n${v.translation}\n\n(${s.transliteration} ${s.id}:${v.id})'));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কপি হয়েছে'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: AnimatedBuilder(
            animation: Listenable.merge([_cur, _curJuz]),
            builder: (_, __) {
              final id = _cur.value;
              if (!_ready || id < 1 || id > _all.length) return Text(tr('f_quran'));
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${toBn(id)}. ${_all[id - 1].transliteration}',
                      style: const TextStyle(fontSize: 18)),
                  Text('পারা ${toBn(_curJuz.value)}',
                      style: TextStyle(fontSize: 12, color: wh(.75))),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              tooltip: 'সূরা / পারা',
              icon: const Icon(Icons.format_list_numbered_rounded),
              onPressed: _ready ? _jump : null,
            ),
            IconButton(
              tooltip: 'বুকমার্ক',
              icon: const Icon(Icons.bookmark_border_rounded),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const BookmarksScreen())),
            ),
            PopupMenuButton<int>(
              icon: const Icon(Icons.text_fields_rounded),
              onSelected: (d) =>
                  setState(() => _size = (_size + d).clamp(20, 44).toDouble()),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 2, child: Text('লেখা বড় করুন')),
                PopupMenuItem(value: -2, child: Text('লেখা ছোট করুন')),
              ],
            ),
          ],
        ),
        body: _error != null
            ? Center(child: Text('লোড করা যায়নি: $_error'))
            : !_ready
                ? const Center(child: CircularProgressIndicator())
                : ScrollablePositionedList.builder(
                    itemScrollController: _ctrl,
                    itemPositionsListener: _positions,
                    initialScrollIndex: _start,
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                    itemCount: _items.length + 1,
                    itemBuilder: (_, i) {
                      if (i == _items.length) return const _Credit();
                      final it = _items[i];
                      final s = _all[it.surah - 1];
                      final juz = _juzAt[i];
                      if (it.verse < 0) {
                        return _Header(s: s, size: _size, juz: juz);
                      }
                      if (juz != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [_JuzBanner(juz: juz), _verseCard(s, it.verse)],
                        );
                      }
                      return _verseCard(s, it.verse);
                    },
                  ),
      ),
    );
  }

  Widget _verseCard(Surah s, int idx) {
    final v = s.verses[idx];
    final marked = _marks.contains(QuranStore.key(s.id, v.id));
    final list = _uch?[s.id];
    final uch = (list != null && idx < list.length) ? list[idx].trim() : '';
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      radius: 20,
      blur: 0,
      opacity: 0.10,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  color: kGold.withOpacity(.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kGold.withOpacity(.5)),
                ),
                child: Text('${toBn(s.id)}:${toBn(v.id)}',
                    style: const TextStyle(color: kGold, fontSize: 13)),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.copy_rounded, size: 20, color: wh(.8)),
                onPressed: () => _copy(s, v),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(marked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    size: 23, color: marked ? kGold : wh(.8)),
                onPressed: () => _toggleMark(s.id, v.id),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Text(
              v.text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: _size, height: 2.0),
            ),
          ),
          if (uch.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(uch,
                style: TextStyle(fontSize: 15.5, height: 1.55, color: kMint.withOpacity(.95))),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: wh(.15)),
          const SizedBox(height: 10),
          Text(v.translation, style: TextStyle(fontSize: 16, height: 1.55, color: wh(.9))),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Surah s;
  final double size;
  final int? juz;
  const _Header({required this.s, required this.size, this.juz});

  @override
  Widget build(BuildContext context) {
    final showBismillah = s.id != 1 && s.id != 9;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14, top: 8),
      tint: kGold,
      opacity: 0.12,
      blur: 0,
      radius: 26,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            if (juz != null) ...[
              _JuzBanner(juz: juz!),
              const SizedBox(height: 4),
            ],
            Text(s.name, style: const TextStyle(fontSize: 36, color: kGold)),
            const SizedBox(height: 4),
            Text('${toBn(s.id)}. ${s.transliteration}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${s.meaning} · ${toBn(s.totalVerses)} আয়াত · ${s.typeBn}',
                style: TextStyle(color: wh(.8))),
            if (showBismillah) ...[
              const SizedBox(height: 16),
              Divider(color: wh(.2)),
              const SizedBox(height: 10),
              Text(_bismillah,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: size, height: 1.8)),
            ],
            const SizedBox(height: 14),
            SurahListenButton(surah: s.id),
          ],
        ),
      ),
    );
  }
}

/// "পারা ১৫ · سُبْحَانَ الَّذِي" line shown where a para begins.
class _JuzBanner extends StatelessWidget {
  final int juz;
  const _JuzBanner({required this.juz});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: kMint.withOpacity(.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kMint.withOpacity(.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('পারা ${toBn(juz)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: kMint)),
          const SizedBox(width: 10),
          Text(_juzName[juz - 1],
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 18, color: kMint)),
        ],
      ),
    );
  }
}

class _Credit extends StatelessWidget {
  const _Credit();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'বাংলা অনুবাদ: মুহিউদ্দীন খান (tanzil.net)\nআরবি পাঠ: The Noble Qur\'an Encyclopedia',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: wh(.5)),
      ),
    );
  }
}

/// Bottom sheet: pick a surah or a para (juz) to jump to.
/// Pops with the item index to scroll to.
class _JumpSheet extends StatefulWidget {
  final List<Surah> all;
  final List<int> headerIdx;
  final List<int> juzIdx;
  final int current;
  final int currentJuz;
  const _JumpSheet({
    required this.all,
    required this.headerIdx,
    required this.juzIdx,
    required this.current,
    required this.currentJuz,
  });

  @override
  State<_JumpSheet> createState() => _JumpSheetState();
}

class _JumpSheetState extends State<_JumpSheet> {
  String _q = '';

  bool _match(Surah s) {
    if (_q.isEmpty) return true;
    final q = _q.toLowerCase().trim();
    return s.transliteration.toLowerCase().contains(q) ||
        s.meaning.contains(q) ||
        s.name.contains(q) ||
        s.id.toString() == q ||
        toBn(s.id) == q;
  }

  Widget _surahTab() {
    final list = widget.all.where(_match).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'সূরা খুঁজুন (নাম বা নম্বর)',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: wh(.08),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final s = list[i];
              final sel = s.id == widget.current;
              return ListTile(
                leading: CircleAvatar(
                  radius: 17,
                  backgroundColor: kGold,
                  child: Text(toBn(s.id),
                      style: const TextStyle(
                          color: Color(0xFF3B2A05), fontWeight: FontWeight.w800, fontSize: 13)),
                ),
                title: Text(s.transliteration,
                    style: TextStyle(
                        fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                        color: sel ? kGold : null)),
                subtitle: Text('${s.meaning} · ${toBn(s.totalVerses)} আয়াত'),
                trailing: Text(s.name, style: const TextStyle(fontSize: 20, color: kGold)),
                onTap: () => Navigator.pop(context, widget.headerIdx[s.id]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _juzTab() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 6),
      itemCount: _juzStart.length,
      itemBuilder: (_, i) {
        final (sid, ay) = _juzStart[i];
        final sel = i + 1 == widget.currentJuz;
        final sName = (sid >= 1 && sid <= widget.all.length)
            ? widget.all[sid - 1].transliteration
            : '';
        return ListTile(
          leading: CircleAvatar(
            radius: 17,
            backgroundColor: kMint,
            child: Text(toBn(i + 1),
                style: const TextStyle(
                    color: Color(0xFF052A21), fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          title: Text('পারা ${toBn(i + 1)}',
              style: TextStyle(
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                  color: sel ? kMint : null)),
          subtitle: Text('$sName ${toBn(sid)}:${toBn(ay)}'),
          trailing: Text(_juzName[i], style: const TextStyle(fontSize: 18, color: kMint)),
          onTap: i < widget.juzIdx.length ? () => Navigator.pop(context, widget.juzIdx[i]) : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.78;
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: h,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration:
                    BoxDecoration(color: wh(.3), borderRadius: BorderRadius.circular(2)),
              ),
              const TabBar(
                tabs: [Tab(text: 'সূরা (১১৪)'), Tab(text: 'পারা (৩০)')],
              ),
              Expanded(child: TabBarView(children: [_surahTab(), _juzTab()])),
            ],
          ),
        ),
      ),
    );
  }
}

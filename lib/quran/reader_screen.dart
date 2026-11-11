import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/glass.dart';
import 'models.dart';
import 'quran_audio.dart';

const _bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

class ReaderScreen extends StatefulWidget {
  final Surah surah;
  const ReaderScreen({super.key, required this.surah});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  double _arabicSize = 28;
  Set<String> _marks = {};

  @override
  void initState() {
    super.initState();
    QuranStore.setLastSurah(widget.surah.id);
    QuranStore.bookmarks().then((b) {
      if (mounted) setState(() => _marks = b);
    });
  }

  Future<void> _toggle(Verse v) async {
    final k = QuranStore.key(widget.surah.id, v.id);
    setState(() => _marks.contains(k) ? _marks.remove(k) : _marks.add(k));
    await QuranStore.saveBookmarks(_marks);
  }

  void _copy(Verse v) {
    final s = widget.surah;
    Clipboard.setData(ClipboardData(
        text: '${v.text}\n\n${v.translation}\n\n(${s.transliteration} ${s.id}:${v.id})'));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কপি হয়েছে'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.surah;
    final showBismillah = s.id != 1 && s.id != 9;
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(s.transliteration),
          actions: [
            IconButton(
              icon: const Icon(Icons.text_decrease_rounded),
              onPressed: () =>
                  setState(() => _arabicSize = (_arabicSize - 2).clamp(20, 44).toDouble()),
            ),
            IconButton(
              icon: const Icon(Icons.text_increase_rounded),
              onPressed: () =>
                  setState(() => _arabicSize = (_arabicSize + 2).clamp(20, 44).toDouble()),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
                child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
          itemCount: s.verses.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return _SurahHeader(s: s, showBismillah: showBismillah, size: _arabicSize);
            }
            final v = s.verses[i - 1];
            final marked = _marks.contains(QuranStore.key(s.id, v.id));
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
                        onPressed: () => _copy(v),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                            marked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 23,
                            color: marked ? kGold : wh(.8)),
                        onPressed: () => _toggle(v),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      v.text,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: _arabicSize, height: 2.0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: wh(.15)),
                  const SizedBox(height: 10),
                  Text(v.translation,
                      style: TextStyle(fontSize: 16, height: 1.55, color: wh(.9))),
                ],
              ),
            );
          },
        )),
          ],
        ),
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  final Surah s;
  final bool showBismillah;
  final double size;
  const _SurahHeader({required this.s, required this.showBismillah, required this.size});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14, top: 4),
      tint: kGold,
      opacity: 0.12,
      blur: 18,
      radius: 26,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Text(s.name, style: const TextStyle(fontSize: 36, color: kGold)),
            const SizedBox(height: 4),
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

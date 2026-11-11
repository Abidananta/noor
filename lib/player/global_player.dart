import 'dart:async';
import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/material.dart';
import '../audio_focus.dart';
import '../features/common.dart' show bnDigits;
import '../features/gazal_screen.dart' show GazalEngine, Track;
import '../i18n.dart';
import '../quran/models.dart';
import '../quran/quran_audio.dart';
import '../ui/glass.dart';

enum _Src { none, quran, gazal }

_Src _active() {
  final q = QuranAudio.current.value != null;
  final g = GazalEngine.current.value != null;
  if (q && g) return audioOwner.value == 'gazal' ? _Src.gazal : _Src.quran;
  if (q) return _Src.quran;
  if (g) return _Src.gazal;
  return _Src.none;
}

/// Fires whenever a recitation / gazal starts or is closed.
final Listenable playerChanges =
    Listenable.merge([QuranAudio.current, GazalEngine.current, audioOwner]);

/// true while the bottom player is on screen.
bool playerActive() => _active() != _Src.none;

/// true while the home / menu / settings / profile pages (the ones with the
/// bottom navigation bar) are on top. The player is hidden there, so the nav
/// bar is always shown; the player only appears on the audio pages.
final ValueNotifier<bool> onRootPage = ValueNotifier<bool>(true);

/// Lets [RootScreen] tell [onRootPage] when another page is opened over it.
final RouteObserver<PageRoute<dynamic>> rootRouteObserver = RouteObserver<PageRoute<dynamic>>();

/// Wraps the whole app (background only). The audio player is NOT drawn
/// here any more: it lives inside the Gazal and Tilawat pages only, through
/// [GazalPlayerDock] and [QuranPlayerDock].
class PlayerHost extends StatelessWidget {
  final Widget child;
  const PlayerHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) => GlassBackground(child: child);
}

/// Player shown at the bottom of the Gazal page while a gazal is loaded.
class GazalPlayerDock extends StatelessWidget {
  const GazalPlayerDock({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(top: false, child: const _GazalBar()),
    );
  }
}

/// Player shown at the bottom of the Tilawat page while a surah is loaded.
class QuranPlayerDock extends StatelessWidget {
  const QuranPlayerDock({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(top: false, child: const _QuranBar()),
    );
  }
}

String _fmt(Duration d) {
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return bnDigits(d.inHours > 0 ? '${d.inHours}:$m:$s' : '${d.inMinutes}:$s');
}

/// The compact player card (title, seek bar, previous / play / next).
class _BarView extends StatelessWidget {
  final String title;
  final String? arabic;
  final String? error;
  final bool playing;
  final bool loading;
  final Duration pos;
  final Duration dur;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onPlay;
  final VoidCallback onNext;
  final VoidCallback onClose;
  final VoidCallback onSeekStart;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onSeekEnd;

  const _BarView({
    required this.title,
    this.arabic,
    this.error,
    required this.playing,
    required this.loading,
    required this.pos,
    required this.dur,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onPlay,
    required this.onNext,
    required this.onClose,
    required this.onSeekStart,
    required this.onSeek,
    required this.onSeekEnd,
  });

  @override
  Widget build(BuildContext context) {
    final maxMs = dur.inMilliseconds < 1 ? 1.0 : dur.inMilliseconds.toDouble();
    final posMs = pos.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();
    // Same look as the gazal player: title, gold seek bar,
    // time | previous  (play)  next | time.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GlassCard(
        blur: 16,
        radius: 26,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    tooltip: 'বন্ধ করুন',
                    padding: EdgeInsets.zero,
                    iconSize: 22,
                    color: wh(.8),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: onClose,
                  ),
                ),
              ],
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFFF87171))),
              )
            else
              SizedBox(
                height: 34,
                child: _SeekBar(
                  value: posMs,
                  max: maxMs,
                  onStart: onSeekStart,
                  onChanged: (v) => onSeek(Duration(milliseconds: v.round())),
                  onEnd: (v) => onSeekEnd(Duration(milliseconds: v.round())),
                ),
              ),
            Row(
              children: [
                Text(_fmt(pos), style: TextStyle(fontSize: 12, color: wh(.75))),
                const Spacer(),
                IconButton(
                  iconSize: 34,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  color: wh(.85),
                  disabledColor: wh(.35),
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: canPrev ? onPrev : null,
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onPlay,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: kGold),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 32, color: const Color(0xFF3B2A05)),
                        if (loading)
                          const SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Color(0xFF3B2A05)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  iconSize: 34,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  color: wh(.85),
                  disabledColor: wh(.35),
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: canNext ? onNext : null,
                ),
                const Spacer(),
                Text(_fmt(dur), style: TextStyle(fontSize: 12, color: wh(.75))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Seek bar drawn by hand (gold progress, dark track, round gold thumb, fully
/// transparent background), so it looks the same on every Flutter version.
class _SeekBar extends StatefulWidget {
  final double value;
  final double max;
  final VoidCallback onStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onEnd;
  const _SeekBar({
    required this.value,
    required this.max,
    required this.onStart,
    required this.onChanged,
    required this.onEnd,
  });

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  static const double _pad = 10; // room for the thumb at both ends
  double _last = 0;

  double _toValue(double dx, double width) {
    final track = width - _pad * 2;
    if (track <= 0) return 0;
    return ((dx - _pad) / track).clamp(0.0, 1.0) * widget.max;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final frac = widget.max <= 0 ? 0.0 : (widget.value / widget.max).clamp(0.0, 1.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final v = _toValue(d.localPosition.dx, w);
            widget.onStart();
            widget.onChanged(v);
            widget.onEnd(v);
          },
          onHorizontalDragStart: (d) {
            widget.onStart();
            _last = _toValue(d.localPosition.dx, w);
            widget.onChanged(_last);
          },
          onHorizontalDragUpdate: (d) {
            _last = _toValue(d.localPosition.dx, w);
            widget.onChanged(_last);
          },
          onHorizontalDragEnd: (_) => widget.onEnd(_last),
          onHorizontalDragCancel: () => widget.onEnd(_last),
          child: CustomPaint(
            size: Size(w, 34),
            painter: _SeekPainter(frac, _pad),
          ),
        );
      },
    );
  }
}

class _SeekPainter extends CustomPainter {
  final double frac;
  final double pad;
  _SeekPainter(this.frac, this.pad);

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final left = pad;
    final right = size.width - pad;
    final x = left + (right - left) * frac;
    const h = 4.0;
    final inactive = Paint()..color = const Color(0xFF263535);
    final active = Paint()..color = kGold;
    canvas.drawRRect(
        RRect.fromLTRBR(left, cy - h / 2, right, cy + h / 2, const Radius.circular(h / 2)),
        inactive);
    canvas.drawRRect(
        RRect.fromLTRBR(left, cy - h / 2, x, cy + h / 2, const Radius.circular(h / 2)),
        active);
    canvas.drawCircle(Offset(x, cy), 9, active);
  }

  @override
  bool shouldRepaint(_SeekPainter o) => o.frac != frac || o.pad != pad;
}

// ---------------- Quran ----------------

class _QuranBar extends StatefulWidget {
  const _QuranBar();

  @override
  State<_QuranBar> createState() => _QuranBarState();
}

class _QuranBarState extends State<_QuranBar> {
  List<Surah> _all = const [];

  @override
  void initState() {
    super.initState();
    QuranRepo.load().then((l) {
      if (mounted) setState(() => _all = l);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final listenable = Listenable.merge([
      QuranAudio.current,
      QuranAudio.state,
      QuranAudio.loading,
      QuranAudio.failed,
      QuranAudio.position,
      QuranAudio.duration,
    ]);
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final id = QuranAudio.current.value;
        if (id == null) return const SizedBox.shrink();
        Surah? s;
        if (id >= 1 && id <= _all.length) s = _all[id - 1];
        return _BarView(
          title: s == null ? bnDigits('$id') : '${bnDigits('$id')}. ${s.transliteration}',
          arabic: s?.name,
          error: QuranAudio.failed.value ? tr('qa_err') : null,
          playing: QuranAudio.state.value == PlayerState.playing,
          loading: QuranAudio.loading.value,
          pos: QuranAudio.position.value,
          dur: QuranAudio.duration.value,
          canPrev: id > 1,
          canNext: id < 114,
          onPrev: () => QuranAudio.step(-1),
          onPlay: QuranAudio.playPause,
          onNext: () => QuranAudio.step(1),
          onClose: QuranAudio.stop,
          onSeekStart: () => QuranAudio.dragging = true,
          onSeek: (d) => QuranAudio.position.value = d,
          onSeekEnd: (d) async {
            await QuranAudio.seek(d);
            QuranAudio.dragging = false;
          },
        );
      },
    );
  }
}

// ---------------- Gazal ----------------

class _GazalBar extends StatefulWidget {
  const _GazalBar();

  @override
  State<_GazalBar> createState() => _GazalBarState();
}

class _GazalBarState extends State<_GazalBar> {
  PlayerState _state = GazalEngine.player.state;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _drag = false;
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void initState() {
    super.initState();
    final p = GazalEngine.player;
    _subs.add(p.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    }));
    _subs.add(p.onPositionChanged.listen((d) {
      if (mounted && !_drag) setState(() => _pos = d);
    }));
    _subs.add(p.onDurationChanged.listen((d) {
      if (mounted) setState(() => _dur = d);
    }));
    _initial();
  }

  Future<void> _initial() async {
    try {
      final d = await GazalEngine.player.getDuration();
      final pos = await GazalEngine.player.getCurrentPosition();
      if (mounted) {
        setState(() {
          _dur = d ?? Duration.zero;
          _pos = pos ?? Duration.zero;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Track?>(
      valueListenable: GazalEngine.current,
      builder: (_, cur, __) {
        if (cur == null) return const SizedBox.shrink();
        return ValueListenableBuilder<String?>(
          valueListenable: GazalEngine.error,
          builder: (_, err, __) => _BarView(
            title: cur.title,
            error: err,
            playing: _state == PlayerState.playing,
            loading: false,
            pos: _pos,
            dur: _dur,
            canPrev: true,
            canNext: true,
            onPrev: GazalEngine.prev,
            onPlay: GazalEngine.toggle,
            onNext: GazalEngine.next,
            onClose: GazalEngine.stop,
            onSeekStart: () => _drag = true,
            onSeek: (d) => setState(() => _pos = d),
            onSeekEnd: (d) async {
              await GazalEngine.player.seek(d);
              _drag = false;
            },
          ),
        );
      },
    );
  }
}

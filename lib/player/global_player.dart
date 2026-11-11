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

/// Wraps the whole app, so the same small player shows on every page while
/// audio is playing (and the pages above it simply get a bit shorter).
class PlayerHost extends StatelessWidget {
  final Widget child;
  const PlayerHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: AnimatedBuilder(
        animation: playerChanges,
        builder: (context, _) {
          final src = _active();
          return Column(
            children: [
              Expanded(
                // Same widget types in both cases, so the pages keep their state.
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: src != _Src.none,
                  child: child,
                ),
              ),
              if (src != _Src.none)
                Material(
                  type: MaterialType.transparency,
                  child: SafeArea(
                    top: false,
                    child: src == _Src.quran ? const _QuranBar() : const _GazalBar(),
                  ),
                ),
            ],
          );
        },
      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: GlassCard(
        blur: 14,
        radius: 22,
        opacity: 0.12,
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.4)),
                ),
                if (arabic != null) ...[
                  const SizedBox(width: 8),
                  Text(arabic!,
                      style: const TextStyle(fontSize: 17, color: kGold, height: 1.4)),
                ],
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 30),
                  iconSize: 19,
                  icon: Icon(Icons.close_rounded, color: wh(.7)),
                  onPressed: onClose,
                ),
              ],
            ),
            if (error != null)
              Text(error!,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFF87171)))
            else
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Row(
                  children: [
                    Text(_fmt(pos), style: TextStyle(fontSize: 10.5, color: wh(.7))),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 11),
                          activeTrackColor: kGold,
                          inactiveTrackColor: wh(.22),
                          thumbColor: kGold,
                        ),
                        child: SizedBox(
                          height: 24,
                          child: Slider(
                            value: posMs,
                            max: maxMs,
                            onChangeStart: (_) => onSeekStart(),
                            onChanged: (v) => onSeek(Duration(milliseconds: v.round())),
                            onChangeEnd: (v) =>
                                onSeekEnd(Duration(milliseconds: v.round())),
                          ),
                        ),
                      ),
                    ),
                    Text(_fmt(dur), style: TextStyle(fontSize: 10.5, color: wh(.7))),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 26,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: canPrev ? onPrev : null,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 42,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          iconSize: 38,
                          padding: EdgeInsets.zero,
                          color: kGold,
                          icon: Icon(playing
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded),
                          onPressed: onPlay,
                        ),
                        if (loading)
                          const IgnorePointer(
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Color(0xFF3B2A05)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    iconSize: 26,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: canNext ? onNext : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../audio_focus.dart';
import '../features/common.dart' show bnDigits;
import '../i18n.dart';
import '../ui/glass.dart';
import 'models.dart';

/// Reciter used for the full-surah recitation (Mishary Rashid Alafasy).
/// Other identifiers can be found at https://alquran.cloud/cdn
const String kQuranReciter = 'ar.alafasy';
const int kQuranBitrate = 128;

String quranAudioUrl(int surah) =>
    'https://cdn.islamic.network/quran/audio-surah/$kQuranBitrate/$kQuranReciter/$surah.mp3';

/// One shared player, so the recitation keeps going while you move around the app.
class QuranAudio {
  QuranAudio._();

  static final AudioPlayer player = AudioPlayer();
  static final ValueNotifier<int?> current = ValueNotifier<int?>(null);
  static final ValueNotifier<PlayerState> state =
      ValueNotifier<PlayerState>(PlayerState.stopped);
  static final ValueNotifier<Duration> position = ValueNotifier<Duration>(Duration.zero);
  static final ValueNotifier<Duration> duration = ValueNotifier<Duration>(Duration.zero);
  static final ValueNotifier<bool> failed = ValueNotifier<bool>(false);

  static bool _started = false;
  static int _token = 0;

  static void _init() {
    if (_started) return;
    _started = true;
    player.onPlayerStateChanged.listen((s) => state.value = s);
    player.onPositionChanged.listen((d) {
      position.value = d;
      if (d > Duration.zero && failed.value) failed.value = false;
    });
    player.onDurationChanged.listen((d) => duration.value = d);
    player.onPlayerComplete.listen((_) => _onComplete());
    audioOwner.addListener(() {
      if (audioOwner.value != 'quran' && state.value == PlayerState.playing) {
        player.pause();
      }
    });
  }

  /// After a surah ends, carry on with the next one.
  static void _onComplete() {
    final c = current.value;
    if (c != null && c < 114) {
      play(c + 1);
    } else {
      position.value = Duration.zero;
    }
  }

  static Future<void> play(int surah) async {
    _init();
    audioOwner.value = 'quran';
    final token = ++_token;
    current.value = surah;
    failed.value = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    try {
      await player.stop();
      await player.play(UrlSource(quranAudioUrl(surah)));
    } catch (_) {
      if (token == _token) failed.value = true;
      return;
    }
    // Nothing started after a while -> probably no internet.
    Future<void>.delayed(const Duration(seconds: 20), () {
      if (token == _token &&
          position.value == Duration.zero &&
          state.value != PlayerState.paused) {
        failed.value = true;
      }
    });
  }

  /// Play this surah, or pause / resume it when it is already the current one.
  static Future<void> toggle(int surah) async {
    _init();
    if (current.value == surah) {
      if (state.value == PlayerState.playing) {
        await player.pause();
        return;
      }
      if (state.value == PlayerState.paused) {
        audioOwner.value = 'quran';
        await player.resume();
        return;
      }
    }
    await play(surah);
  }

  static Future<void> playPause() async {
    final c = current.value;
    if (c != null) await toggle(c);
  }

  static Future<void> step(int delta) async {
    final c = current.value;
    if (c == null) return;
    final n = c + delta;
    if (n >= 1 && n <= 114) await play(n);
  }

  static Future<void> seek(Duration d) async {
    try {
      await player.seek(d);
    } catch (_) {}
  }

  static Future<void> stop() async {
    _token++;
    try {
      await player.stop();
    } catch (_) {}
    current.value = null;
    failed.value = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }
}

/// Small round play / pause button for a surah row.
class SurahPlayButton extends StatelessWidget {
  final int surah;
  const SurahPlayButton({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: QuranAudio.current,
      builder: (_, cur, __) => ValueListenableBuilder<PlayerState>(
        valueListenable: QuranAudio.state,
        builder: (_, st, __) {
          final playing = cur == surah && st == PlayerState.playing;
          return IconButton(
            tooltip: playing ? tr('qa_pause') : tr('qa_listen'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            iconSize: 34,
            color: kGold,
            icon: Icon(playing
                ? Icons.pause_circle_filled_rounded
                : Icons.play_circle_outline_rounded),
            onPressed: () => QuranAudio.toggle(surah),
          );
        },
      ),
    );
  }
}

/// "Listen" pill shown in the reader's surah header.
class SurahListenButton extends StatelessWidget {
  final int surah;
  const SurahListenButton({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: QuranAudio.current,
      builder: (_, cur, __) => ValueListenableBuilder<PlayerState>(
        valueListenable: QuranAudio.state,
        builder: (_, st, __) {
          final playing = cur == surah && st == PlayerState.playing;
          return OutlinedButton.icon(
            onPressed: () => QuranAudio.toggle(surah),
            icon: Icon(playing ? Icons.pause_rounded : Icons.headphones_rounded,
                color: kGold),
            label: Text(playing ? tr('qa_pause') : tr('qa_listen'),
                style: const TextStyle(color: kGold, fontSize: 15)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kGold.withOpacity(.6)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          );
        },
      ),
    );
  }
}

/// Bottom player: appears as soon as a surah is started.
class QuranPlayerBar extends StatefulWidget {
  const QuranPlayerBar({super.key});

  @override
  State<QuranPlayerBar> createState() => _QuranPlayerBarState();
}

class _QuranPlayerBarState extends State<QuranPlayerBar> {
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
    return ValueListenableBuilder<int?>(
      valueListenable: QuranAudio.current,
      builder: (context, id, _) {
        if (id == null) return const SizedBox.shrink();
        Surah? s;
        if (id >= 1 && id <= _all.length) s = _all[id - 1];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: GlassCard(
            blur: 16,
            radius: 24,
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s == null
                            ? bnDigits('$id')
                            : '${bnDigits('$id')}. ${s.transliteration}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (s != null)
                      Text(s.name, style: const TextStyle(fontSize: 21, color: kGold)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded, color: wh(.7)),
                      onPressed: QuranAudio.stop,
                    ),
                  ],
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: QuranAudio.failed,
                  builder: (_, f, __) => f
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(tr('qa_err'),
                              style: const TextStyle(
                                  fontSize: 12.5, color: Color(0xFFF87171))),
                        )
                      : const SizedBox.shrink(),
                ),
                const _Progress(),
                _Controls(id: id),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress();

  String _fmt(Duration d) {
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return bnDigits(d.inHours > 0 ? '${d.inHours}:$m:$s' : '${d.inMinutes}:$s');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: QuranAudio.duration,
      builder: (_, dur, __) => ValueListenableBuilder<Duration>(
        valueListenable: QuranAudio.position,
        builder: (_, pos, __) {
          final maxMs = dur.inMilliseconds < 1 ? 1.0 : dur.inMilliseconds.toDouble();
          final posMs = pos.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();
          return Row(
            children: [
              Text(_fmt(pos), style: TextStyle(fontSize: 11.5, color: wh(.7))),
              Expanded(
                child: Slider(
                  value: posMs,
                  max: maxMs,
                  activeColor: kGold,
                  onChanged: (v) =>
                      QuranAudio.position.value = Duration(milliseconds: v.round()),
                  onChangeEnd: (v) =>
                      QuranAudio.seek(Duration(milliseconds: v.round())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(_fmt(dur), style: TextStyle(fontSize: 11.5, color: wh(.7))),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final int id;
  const _Controls({required this.id});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: id > 1 ? () => QuranAudio.step(-1) : null,
        ),
        ValueListenableBuilder<PlayerState>(
          valueListenable: QuranAudio.state,
          builder: (_, st, __) => IconButton(
            iconSize: 46,
            color: kGold,
            icon: Icon(st == PlayerState.playing
                ? Icons.pause_circle_filled_rounded
                : Icons.play_circle_fill_rounded),
            onPressed: QuranAudio.playPause,
          ),
        ),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: id < 114 ? () => QuranAudio.step(1) : null,
        ),
      ],
    );
  }
}

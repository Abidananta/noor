import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:just_audio/just_audio.dart' as ja;
import 'package:flutter/material.dart';
import '../audio_focus.dart';
import '../i18n.dart';
import '../ui/glass.dart';

/// Reciter used for the full-surah recitation (Mishary Rashid Alafasy).
/// Other identifiers can be found at https://alquran.cloud/cdn
const String kQuranReciter = 'ar.alafasy';
const int kQuranBitrate = 128;

String quranAudioUrl(int surah) =>
    'https://cdn.islamic.network/quran/audio-surah/$kQuranBitrate/$kQuranReciter/$surah.mp3';

/// One shared player, so the recitation keeps going while you move around the app.
///
/// Uses just_audio (ExoPlayer on Android): it starts playing after the first
/// few seconds are buffered instead of waiting for a big part of the file,
/// which is why a long surah now starts much faster than before.
class QuranAudio {
  QuranAudio._();

  static final ja.AudioPlayer player = ja.AudioPlayer();
  static final ValueNotifier<int?> current = ValueNotifier<int?>(null);
  static final ValueNotifier<PlayerState> state =
      ValueNotifier<PlayerState>(PlayerState.stopped);
  static final ValueNotifier<Duration> position = ValueNotifier<Duration>(Duration.zero);
  static final ValueNotifier<Duration> duration = ValueNotifier<Duration>(Duration.zero);
  static final ValueNotifier<bool> failed = ValueNotifier<bool>(false);

  /// true while the audio is being fetched / buffered (spinner on the button).
  static final ValueNotifier<bool> loading = ValueNotifier<bool>(false);

  static bool _started = false;
  static bool dragging = false;
  static int _token = 0;

  static void _init() {
    if (_started) return;
    _started = true;
    player.playerStateStream.listen((s) {
      final busy = s.processingState == ja.ProcessingState.loading ||
          s.processingState == ja.ProcessingState.buffering;
      loading.value = busy && current.value != null;
      if (s.processingState == ja.ProcessingState.completed) {
        state.value = PlayerState.completed;
        _onComplete();
      } else if (s.processingState == ja.ProcessingState.idle) {
        state.value = PlayerState.stopped;
      } else {
        state.value = s.playing ? PlayerState.playing : PlayerState.paused;
      }
    });
    player.positionStream.listen((d) {
      if (dragging) return;
      position.value = d;
      if (d > Duration.zero && failed.value) failed.value = false;
    });
    player.durationStream.listen((d) {
      if (d != null) duration.value = d;
    });
    audioOwner.addListener(() {
      if (audioOwner.value != 'quran' && player.playing) {
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
    loading.value = true;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    try {
      await player.setUrl(quranAudioUrl(surah));
      if (token != _token) return; // another surah was chosen meanwhile
      // Not awaited: the future only completes when the playback ends.
      player.play();
    } catch (_) {
      if (token == _token) {
        failed.value = true;
        loading.value = false;
      }
    }
  }

  /// Play this surah, or pause / resume it when it is already the current one.
  static Future<void> toggle(int surah) async {
    _init();
    if (current.value == surah && player.processingState != ja.ProcessingState.idle) {
      if (player.playing) {
        await player.pause();
      } else {
        audioOwner.value = 'quran';
        player.play();
      }
      return;
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
    loading.value = false;
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

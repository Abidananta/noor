import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n.dart';
import '../ui/glass.dart';
import 'common.dart';
import 'gazal_remote.dart';

/// kind: 0 = bundled asset, 1 = internet URL, 2 = file added from the phone
class Track {
  final String title;
  final String artist;
  final int kind;
  final String ref;
  const Track(this.title, this.artist, this.kind, this.ref);

  String get id => '$kind|$ref';

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;

  Source get source {
    switch (kind) {
      case 0:
        return AssetSource(ref);
      case 1:
        return UrlSource(ref);
      default:
        return DeviceFileSource(ref);
    }
  }
}

/// One shared player so music keeps playing while you move around the app.
class GazalEngine {
  static final AudioPlayer player = AudioPlayer();
  static final ValueNotifier<Track?> current = ValueNotifier<Track?>(null);
  static final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  static List<Track> queue = [];
  static bool _started = false;

  static void init() {
    if (_started) return;
    _started = true;
    player.onPlayerComplete.listen((_) => next());
  }

  static Future<void> play(Track t, List<Track> q) async {
    init();
    queue = q;
    current.value = t;
    error.value = null;
    try {
      await player.stop();
      await player.play(t.source);
    } catch (e) {
      error.value = tr('gz_play_err');
    }
  }

  static Future<void> toggle() async {
    if (player.state == PlayerState.playing) {
      await player.pause();
    } else if (current.value != null) {
      if (player.state == PlayerState.paused) {
        await player.resume();
      } else {
        await play(current.value!, queue);
      }
    }
  }

  static Future<void> step(int delta) async {
    final c = current.value;
    if (c == null || queue.isEmpty) return;
    final i = queue.indexOf(c);
    final n = ((i < 0 ? 0 : i) + delta) % queue.length;
    await play(queue[n < 0 ? n + queue.length : n], queue);
  }

  static Future<void> next() => step(1);
  static Future<void> prev() => step(-1);
}

const _userKey = 'gazal_user';

class GazalScreen extends StatefulWidget {
  const GazalScreen({super.key});

  @override
  State<GazalScreen> createState() => _GazalScreenState();
}

class _GazalScreenState extends State<GazalScreen> with WidgetsBindingObserver {
  List<Track> _bundled = [];
  List<Track> _remote = [];
  List<Track> _mine = [];
  bool _loaded = false;
  bool _syncing = false;

  PlayerState _state = GazalEngine.player.state;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  final List<StreamSubscription<dynamic>> _subs = [];

  List<Track> get _all {
    final seen = <String>{};
    return [..._bundled, ..._remote, ..._mine].where((t) => seen.add(t.id)).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    GazalEngine.init();
    _load();
    final p = GazalEngine.player;
    _subs.add(p.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    }));
    _subs.add(p.onPositionChanged.listen((d) {
      if (mounted) setState(() => _pos = d);
    }));
    _subs.add(p.onDurationChanged.listen((d) {
      if (mounted) setState(() => _dur = d);
    }));
    _syncNow();
  }

  Future<void> _syncNow() async {
    final d = await GazalEngine.player.getDuration();
    final pos = await GazalEngine.player.getCurrentPosition();
    if (mounted) {
      setState(() {
        _dur = d ?? Duration.zero;
        _pos = pos ?? Duration.zero;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app: pick up files added to GitHub / Drive meanwhile.
    if (state == AppLifecycleState.resumed) _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final bundled = <Track>[];
    try {
      final raw = await rootBundle.loadString('assets/gazal.json');
      for (final e in jsonDecode(raw) as List) {
        final m = e as Map<String, dynamic>;
        final title = (m['title'] ?? '') as String;
        final artist = (m['artist'] ?? '') as String;
        if (m['asset'] != null) {
          bundled.add(Track(title, artist, 0, m['asset'] as String));
        } else if (m['url'] != null) {
          bundled.add(Track(title, artist, 1, m['url'] as String));
        }
      }
    } catch (_) {}

    final mine = <Track>[];
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_userKey);
    if (saved != null) {
      try {
        for (final e in jsonDecode(saved) as List) {
          final m = e as Map<String, dynamic>;
          mine.add(Track((m['title'] ?? '') as String, tr('gz_mine'), 2, (m['path'] ?? '') as String));
        }
      } catch (_) {}
    }
    final cached = await GazalRemote.cached();
    if (!mounted) return;
    setState(() {
      _bundled = bundled;
      _remote = [for (final r in cached) Track(r.title, tr('gz_online'), 1, r.url)];
      _mine = mine;
      _loaded = true;
    });
    _sync();
  }

  /// Downloads the newest list from GitHub / Drive (quietly unless [manual]).
  Future<void> _sync({bool manual = false}) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    SyncResult? result;
    try {
      result = await GazalRemote.sync();
    } catch (_) {}
    if (!mounted) return;
    final r = result;
    setState(() {
      _syncing = false;
      if (r != null) {
        _remote = [for (final i in r.items) Track(i.title, tr('gz_online'), 1, i.url)];
      }
    });
    if (manual) {
      final msg = r == null || !r.ok
          ? tr('gz_sync_fail')
          : (!r.configured ? tr('gz_not_set') : tr('gz_synced'));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _editSources() async {
    final cur = await GazalRemote.sources();
    final gh = TextEditingController(text: cur.github);
    final dr = TextEditingController(text: cur.driveFolder);
    final key = TextEditingController(text: cur.driveKey);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panelColor,
        title: Text(tr('gz_src_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('gz_src_help'), style: TextStyle(fontSize: 13, color: wh(.75), height: 1.4)),
              const SizedBox(height: 14),
              TextField(
                controller: gh,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: tr('gz_github_label'),
                  hintText: 'owner/repo/gazal',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dr,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(labelText: tr('gz_drive_label')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: key,
                decoration: InputDecoration(labelText: tr('gz_key_label')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('save'), style: const TextStyle(color: kGold))),
        ],
      ),
    );
    final g = gh.text, d = dr.text, k = key.text;
    gh.dispose();
    dr.dispose();
    key.dispose();
    if (saved != true) return;
    await GazalRemote.saveSources(g, d, k);
    _sync(manual: true);
  }

  Future<void> _saveMine() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _userKey, jsonEncode(_mine.map((t) => {'title': t.title, 'path': t.ref}).toList()));
  }

  Future<void> _addFromPhone() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
      if (res == null) return;
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/gazal');
      if (!await dir.exists()) await dir.create(recursive: true);
      for (final f in res.files) {
        final src = f.path;
        if (src == null) continue;
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final dest = '${dir.path}/${stamp}_${f.name}';
        await File(src).copy(dest);
        final dot = f.name.lastIndexOf('.');
        final title = dot > 0 ? f.name.substring(0, dot) : f.name;
        _mine.add(Track(title, tr('gz_mine'), 2, dest));
      }
      await _saveMine();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('gz_fail_add'))));
      }
    }
  }

  Future<void> _remove(Track t) async {
    if (GazalEngine.current.value == t) {
      await GazalEngine.player.stop();
      GazalEngine.current.value = null;
    }
    try {
      await File(t.ref).delete();
    } catch (_) {}
    setState(() => _mine.remove(t));
    await _saveMine();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return bnDigits('$m:$s');
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    return GlassPage(
      title: tr('f_gazal'),
      actions: [
        IconButton(
          tooltip: tr('gz_sync_tip'),
          icon: _syncing
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.sync_rounded),
          onPressed: _syncing ? null : () => _sync(manual: true),
        ),
        IconButton(
          tooltip: tr('gz_src_tip'),
          icon: const Icon(Icons.cloud_outlined),
          onPressed: _editSources,
        ),
        IconButton(
          tooltip: tr('gz_add_tip'),
          icon: const Icon(Icons.library_add_rounded),
          onPressed: _addFromPhone,
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : all.isEmpty
                    ? _empty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                        itemCount: all.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _tile(all[i], all),
                      ),
          ),
          ValueListenableBuilder<Track?>(
            valueListenable: GazalEngine.current,
            builder: (_, cur, __) => cur == null ? const SizedBox.shrink() : _nowPlaying(cur),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note_rounded, size: 52, color: kGold),
            const SizedBox(height: 12),
            Text(tr('gz_empty'),
                textAlign: TextAlign.center,
                style: TextStyle(color: wh(.8), height: 1.5, fontSize: 15.5)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _addFromPhone,
              icon: const Icon(Icons.library_add_rounded),
              label: Text(tr('gz_add')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(Track t, List<Track> all) {
    return ValueListenableBuilder<Track?>(
      valueListenable: GazalEngine.current,
      builder: (_, cur, __) {
        final active = cur == t;
        final playing = active && _state == PlayerState.playing;
        return GlassCard(
          blur: 0,
          radius: 18,
          tint: active ? kGold : null,
          opacity: active ? 0.18 : 0.10,
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          onTap: () => active ? GazalEngine.toggle() : GazalEngine.play(t, all),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? kGold : wh(.14),
                ),
                child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: active ? const Color(0xFF3B2A05) : Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
                    if (t.artist.isNotEmpty)
                      Text(t.artist, style: TextStyle(fontSize: 13, color: wh(.7))),
                  ],
                ),
              ),
              if (t.kind == 2)
                IconButton(
                  tooltip: tr('delete'),
                  icon: Icon(Icons.delete_outline_rounded, color: wh(.7)),
                  onPressed: () => _remove(t),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _nowPlaying(Track cur) {
    final maxMs = _dur.inMilliseconds < 1 ? 1.0 : _dur.inMilliseconds.toDouble();
    final posMs = _pos.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GlassCard(
        blur: 16,
        radius: 24,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(cur.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ValueListenableBuilder<String?>(
              valueListenable: GazalEngine.error,
              builder: (_, e, __) => e == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(e,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFFF87171))),
                    ),
            ),
            Slider(
              value: posMs,
              max: maxMs,
              activeColor: kGold,
              onChanged: (v) => setState(() => _pos = Duration(milliseconds: v.round())),
              onChangeEnd: (v) => GazalEngine.player.seek(Duration(milliseconds: v.round())),
            ),
            Row(
              children: [
                Text(_fmt(_pos), style: TextStyle(fontSize: 12, color: wh(.7))),
                const Spacer(),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: GazalEngine.prev,
                ),
                IconButton(
                  iconSize: 44,
                  color: kGold,
                  icon: Icon(_state == PlayerState.playing
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded),
                  onPressed: GazalEngine.toggle,
                ),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: GazalEngine.next,
                ),
                const Spacer(),
                Text(_fmt(_dur), style: TextStyle(fontSize: 12, color: wh(.7))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

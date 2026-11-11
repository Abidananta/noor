import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../i18n.dart';
import '../ui/glass.dart';
import 'app_update.dart';
import 'common.dart';

enum _Phase { checking, upToDate, available, downloading, installing, failed, downloadFailed }

/// Checks for a newer release, downloads the APK with a progress bar and
/// opens the installer. Everything happens on this page.
class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _shine;
  _Phase _phase = _Phase.checking;
  UpdateInfo? _info;
  int _got = 0;
  int _total = 0;
  int _dlId = 0; // bumping it cancels a running download

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _check();
  }

  @override
  void dispose() {
    _dlId++;
    _spin.dispose();
    _shine.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _phase = _Phase.checking);
    final started = DateTime.now();
    UpdateInfo? info;
    Object? err;
    try {
      final repo = await savedUpdateRepo();
      if (repo.isEmpty) throw StateError('no repo');
      info = await fetchLatestRelease(repo);
    } catch (e) {
      err = e;
    }
    // let the checking animation play for a moment, even on a fast network
    final spent = DateTime.now().difference(started);
    if (spent < const Duration(milliseconds: 1600)) {
      await Future<void>.delayed(const Duration(milliseconds: 1600) - spent);
    }
    if (!mounted) return;
    if (err != null || info == null) {
      setState(() => _phase = _Phase.failed);
      return;
    }
    _info = info;
    setState(() => _phase = isNewerVersion(info!.version, kAppVersion) ? _Phase.available : _Phase.upToDate);
  }

  Future<void> _download() async {
    final info = _info;
    if (info == null) return;
    if (!info.isApk) {
      // release has no APK file attached: open the release page instead
      try {
        await launchUrl(Uri.parse(info.url), mode: LaunchMode.externalApplication);
      } catch (_) {}
      return;
    }
    setState(() {
      _phase = _Phase.downloading;
      _got = 0;
      _total = info.size;
    });
    final myId = ++_dlId;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    IOSink? sink;
    File? file;
    try {
      final dir = await getTemporaryDirectory();
      file = File('${dir.path}/noor_${info.version}.apk');
      if (await file.exists()) await file.delete();

      final req = await client.getUrl(Uri.parse(info.url));
      req.headers.set('User-Agent', 'noor-app');
      final res = await req.close();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      if (res.contentLength > 0) _total = res.contentLength;

      sink = file.openWrite();
      var lastUi = DateTime.now();
      await for (final chunk in res) {
        if (myId != _dlId || !mounted) {
          await sink.close();
          sink = null;
          try {
            await file.delete();
          } catch (_) {}
          return;
        }
        sink.add(chunk);
        _got += chunk.length;
        final now = DateTime.now();
        if (now.difference(lastUi).inMilliseconds > 80) {
          lastUi = now;
          if (mounted) setState(() {});
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (!mounted) return;
      setState(() {
        _got = _total > 0 ? _total : _got;
        _phase = _Phase.installing;
      });
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await OpenFilex.open(file.path, type: 'application/vnd.android.package-archive');
      if (mounted) setState(() => _phase = _Phase.available); // allow tapping again
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {}
      if (mounted) setState(() => _phase = _Phase.downloadFailed);
    } finally {
      client.close();
    }
  }

  // ---------- UI pieces ----------

  String _mb(int bytes) => localizeDigits((bytes / 1048576).toStringAsFixed(1));

  double get _frac => _total > 0 ? (_got / _total).clamp(0.0, 1.0).toDouble() : 0.0;

  String get _heroGroup {
    switch (_phase) {
      case _Phase.checking:
        return 'check';
      case _Phase.upToDate:
        return 'ok';
      case _Phase.failed:
      case _Phase.downloadFailed:
        return 'fail';
      default:
        return 'update';
    }
  }

  Widget _hero() {
    switch (_phase) {
      case _Phase.checking:
        return _ringIcon(Icons.system_update_rounded, spinning: true, color: kMint);
      case _Phase.upToDate:
        return TweenAnimationBuilder<double>(
          key: const ValueKey('ok'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (_, v, __) => Transform.scale(
            scale: v.clamp(0.0, 1.2).toDouble(),
            child: _badge(Icons.check_rounded, kMint, size: 96),
          ),
        );
      case _Phase.available:
      case _Phase.downloading:
      case _Phase.installing:
        return AnimatedBuilder(
          animation: _spin,
          builder: (_, __) {
            final b = math.sin(_spin.value * 2 * math.pi);
            return Transform.translate(
              offset: Offset(0, -6 * b),
              child: _badge(
                _phase == _Phase.available ? Icons.system_update_rounded : Icons.downloading_rounded,
                kGold,
                size: 96,
                glow: 14 + 6 * b,
              ),
            );
          },
        );
      case _Phase.failed:
      case _Phase.downloadFailed:
        return _badge(Icons.cloud_off_rounded, const Color(0xFFFB7185), size: 96);
    }
  }

  Widget _badge(IconData icon, Color color, {double size = 96, double glow = 14}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(.16),
        border: Border.all(color: color.withOpacity(.7), width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(.35), blurRadius: glow)],
      ),
      child: Icon(icon, size: size * .46, color: color),
    );
  }

  Widget _ringIcon(IconData icon, {required bool spinning, required Color color}) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(
          animation: _spin,
          builder: (_, __) => CustomPaint(
            size: const Size(120, 120),
            painter: _SpinnerPainter(_spin.value, color),
          ),
        ),
        _badge(icon, color, size: 80, glow: 10),
      ]),
    );
  }

  Widget _versionRow() {
    final info = _info;
    Widget cell(String label, String v, Color c) => Expanded(
          child: Column(children: [
            Text(label, style: TextStyle(fontSize: 12.5, color: wh(.65))),
            const SizedBox(height: 4),
            Text(bnDigits('v$v'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: c)),
          ]),
        );
    return GlassCard(
      blur: 0,
      radius: 18,
      opacity: 0.10,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(children: [
        cell(tr('up_current'), kAppVersion, Colors.white),
        if (info != null && _phase != _Phase.upToDate) ...[
          Icon(Icons.arrow_forward_rounded, color: wh(.5)),
          cell(tr('up_latest'), info.version, kGold),
        ],
      ]),
    );
  }

  Widget _progress() {
    final pct = (_frac * 100).round();
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_total > 0 ? bnDigits('$pct%') : '',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: kGold)),
          Text(_total > 0 ? '${_mb(_got)} / ${_mb(_total)} MB' : '${_mb(_got)} MB',
              style: TextStyle(fontSize: 14, color: wh(.75))),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 14,
        child: LayoutBuilder(builder: (context, c) {
          return Stack(children: [
            Container(
              decoration: BoxDecoration(color: wh(.16), borderRadius: BorderRadius.circular(8)),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _total > 0 ? _frac : 0.06),
              duration: const Duration(milliseconds: 250),
              builder: (_, f, __) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: c.maxWidth * f,
                  height: 14,
                  child: AnimatedBuilder(
                    animation: _shine,
                    builder: (_, __) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: const [Color(0xFF6EE7B7), Color(0xFFF2C46D), Color(0xFF6EE7B7)],
                          begin: Alignment(-1.0 + _shine.value * 2, 0),
                          end: Alignment(1.0 + _shine.value * 2, 0),
                          tileMode: TileMode.mirror,
                        ),
                        boxShadow: [BoxShadow(color: kGold.withOpacity(.45), blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        }),
      ),
    ]);
  }

  Widget _button(String label, IconData icon, VoidCallback onTap, {bool outlined = false}) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(onPressed: onTap, icon: Icon(icon), label: child)
          : FilledButton.icon(onPressed: onTap, icon: Icon(icon), label: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title;
    switch (_phase) {
      case _Phase.checking:
        title = tr('st_checking');
        break;
      case _Phase.upToDate:
        title = tr('st_uptodate');
        break;
      case _Phase.available:
        title = tr('up_available');
        break;
      case _Phase.downloading:
        title = tr('up_downloading');
        break;
      case _Phase.installing:
        title = tr('up_installing');
        break;
      case _Phase.failed:
        title = tr('up_fail');
        break;
      case _Phase.downloadFailed:
        title = tr('up_dl_fail');
        break;
    }

    return GlassPage(
      title: tr('st_update'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
        children: [
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: SizedBox(key: ValueKey(_heroGroup), child: _hero()),
            ),
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(title,
                key: ValueKey(title),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.4)),
          ),
          const SizedBox(height: 22),
          if (_phase != _Phase.failed) _versionRow(),
          const SizedBox(height: 22),
          if (_phase == _Phase.downloading || _phase == _Phase.installing) _progress(),
          if (_phase == _Phase.installing)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(tr('up_install_hint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.5, color: wh(.65))),
            ),
          const SizedBox(height: 18),
          if (_phase == _Phase.available)
            _button(tr('st_download'), Icons.download_rounded, _download),
          if (_phase == _Phase.downloading)
            _button(tr('cancel'), Icons.close_rounded, () {
              _dlId++;
              setState(() => _phase = _Phase.available);
            }, outlined: true),
          if (_phase == _Phase.upToDate)
            _button(tr('up_check_again'), Icons.refresh_rounded, _check, outlined: true),
          if (_phase == _Phase.failed)
            _button(tr('up_retry'), Icons.refresh_rounded, _check),
          if (_phase == _Phase.downloadFailed)
            _button(tr('up_retry'), Icons.refresh_rounded, _download),
        ],
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double t;
  final Color color;
  _SpinnerPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = color.withOpacity(.18));
    final start = t * 2 * math.pi;
    canvas.drawArc(
      rect,
      start,
      math.pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 0.9,
          colors: [color.withOpacity(0), color],
          transform: GradientRotation(start),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter old) => old.t != t;
}

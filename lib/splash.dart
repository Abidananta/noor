import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'i18n.dart';
import 'ui/glass.dart';

/// True once the launch animation has played (a language change rebuilds the
/// app and must not replay it).
bool splashPlayed = false;

/// Crescent + star, drawn the same way as the launcher icon.
/// [t] runs 0 -> 1 over the whole intro.
class NoorLogoPainter extends CustomPainter {
  final double t;
  NoorLogoPainter(this.t);

  static double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);

    // glow
    final g = Curves.easeOut.transform(_seg(t, 0.0, 0.5));
    canvas.drawCircle(
      c,
      s * (0.30 + 0.22 * g),
      Paint()
        ..color = kGold.withOpacity(.30 * g)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.14),
    );

    // ring drawing itself
    final ringT = Curves.easeInOut.transform(_seg(t, 0.0, 0.7));
    final ringRect = Rect.fromCircle(center: c, radius: s * 0.46);
    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      2 * math.pi * ringT,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..strokeCap = StrokeCap.round
        ..color = kGold.withOpacity(.55),
    );

    // crescent
    final mt = Curves.easeOutBack.transform(_seg(t, 0.05, 0.6));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate((1 - mt) * -0.9);
    canvas.scale(0.55 + 0.45 * mt);
    canvas.translate(-c.dx, -c.dy);
    final outer = Path()
      ..addOval(Rect.fromCircle(center: Offset(s * .47, s * .53), radius: s * .285));
    final inner = Path()
      ..addOval(Rect.fromCircle(center: Offset(s * .565, s * .47), radius: s * .245));
    final moon = Path.combine(PathOperation.difference, outer, inner);
    final gold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFCE296), Color(0xFFF2C46D), Color(0xFFD69628)],
      ).createShader(Rect.fromLTWH(0, 0, s, s));
    canvas.drawShadow(moon, const Color(0x99000000), 6, true);
    canvas.drawPath(moon, gold);
    canvas.restore();

    // star pops in, then twinkles
    final st = Curves.elasticOut.transform(_seg(t, 0.35, 0.8));
    if (st > 0) {
      final twinkle = 1 + 0.08 * math.sin(t * math.pi * 6) * _seg(t, 0.8, 1.0);
      final sc = Offset(s * .665, s * .335);
      final ro = s * .075 * st * twinkle;
      final ri = ro * .42;
      final star = Path();
      for (int k = 0; k < 10; k++) {
        final a = -math.pi / 2 + k * math.pi / 5;
        final r = k.isEven ? ro : ri;
        final p = Offset(sc.dx + r * math.cos(a), sc.dy + r * math.sin(a));
        k == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      star.close();
      canvas.drawCircle(
          sc,
          s * .07 * st,
          Paint()
            ..color = kGold.withOpacity(.35)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .03));
      canvas.drawPath(star, gold);
    }
  }

  @override
  bool shouldRepaint(covariant NoorLogoPainter old) => old.t != t;
}

/// Launch screen: animated logo, name and tagline, then [onFinished].
class NoorSplash extends StatefulWidget {
  final VoidCallback onFinished;
  const NoorSplash({super.key, required this.onFinished});

  @override
  State<NoorSplash> createState() => _NoorSplashState();
}

class _NoorSplashState extends State<NoorSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300))
      ..addStatusListener((st) async {
        if (st == AnimationStatus.completed) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          if (mounted) widget.onFinished();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final t = _c.value;
              final txt = Curves.easeOut.transform(((t - 0.55) / 0.3).clamp(0.0, 1.0).toDouble());
              final sub = Curves.easeOut.transform(((t - 0.7) / 0.3).clamp(0.0, 1.0).toDouble());
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: CustomPaint(painter: NoorLogoPainter(t)),
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: txt,
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - txt)),
                      child: const Text('Noor',
                          style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: sub,
                    child: Text(tr('ab_tagline'), style: TextStyle(fontSize: 14.5, color: wh(.75))),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

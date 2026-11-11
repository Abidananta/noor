import 'dart:ui';
import 'package:flutter/material.dart';

const kGold = Color(0xFFF2C46D);
const kMint = Color(0xFF6EE7B7);

Color wh(double a) => Color.fromRGBO(255, 255, 255, a);

/// Gradient background with soft glowing blobs. Glass cards blur this.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF052A21), Color(0xFF0C5242), Color(0xFF117C79)],
            ),
          ),
        ),
        const Positioned(top: -90, left: -70, child: _Blob(280, kGold, .38)),
        const Positioned(top: 300, right: -130, child: _Blob(320, Color(0xFF34D399), .30)),
        const Positioned(bottom: -110, left: -90, child: _Blob(340, Color(0xFF22B8CF), .32)),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _Blob(this.size, this.color, this.opacity);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

/// Frosted glass card. blur = 0 skips BackdropFilter (use for long lists).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final double opacity;
  final Color? tint;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 22,
    this.blur = 16,
    this.opacity = 0.12,
    this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final base = tint ?? Colors.white;

    Widget inner = Padding(padding: padding, child: child);
    if (onTap != null) {
      inner = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      );
    }

    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base.withOpacity(opacity + 0.12), base.withOpacity(opacity)],
        ),
        border: Border.all(color: wh(0.26), width: 1),
      ),
      child: inner,
    );

    Widget clipped = ClipRRect(
      borderRadius: r,
      child: blur > 0
          ? BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: box)
          : box,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: const [
          BoxShadow(color: Color(0x26000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: clipped,
    );
  }
}

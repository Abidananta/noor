import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kGold = Color(0xFFF2C46D);
const kMint = Color(0xFF6EE7B7);

Color wh(double a) => Color.fromRGBO(255, 255, 255, a);

/// One selectable app colour scheme (background gradient + panels).
class NoorTheme {
  final String id; // translation key is 'th_<id>'
  final Color bg1, bg2, bg3; // gradient, dark -> light
  final Color panel; // dialogs / bottom sheets
  final Color seed; // Material colour seed
  final Color blob2, blob3; // glowing blobs
  const NoorTheme(this.id, this.bg1, this.bg2, this.bg3, this.panel, this.seed, this.blob2, this.blob3);
}

const List<NoorTheme> kThemes = [
  NoorTheme('green', Color(0xFF052A21), Color(0xFF0C5242), Color(0xFF117C79), Color(0xFF0C3B31),
      Color(0xFF2E9E3A), Color(0xFF34D399), Color(0xFF22B8CF)),
  NoorTheme('ocean', Color(0xFF071E3D), Color(0xFF0B3A6B), Color(0xFF0E6E8C), Color(0xFF0B2B4F),
      Color(0xFF2563EB), Color(0xFF38BDF8), Color(0xFF22D3EE)),
  NoorTheme('purple', Color(0xFF1E1038), Color(0xFF3B1D6B), Color(0xFF6D3FA0), Color(0xFF2A1650),
      Color(0xFF7C3AED), Color(0xFFA78BFA), Color(0xFFE879F9)),
  NoorTheme('rose', Color(0xFF3A0D22), Color(0xFF6B1B3E), Color(0xFFA33A5E), Color(0xFF4A1230),
      Color(0xFFE11D48), Color(0xFFFB7185), Color(0xFFF472B6)),
  NoorTheme('sand', Color(0xFF2B1A0E), Color(0xFF5A3A1E), Color(0xFF8A5A2B), Color(0xFF3D2615),
      Color(0xFFB45309), Color(0xFFFBBF24), Color(0xFFFB923C)),
  NoorTheme('night', Color(0xFF05070D), Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A),
      Color(0xFF64748B), Color(0xFF475569), Color(0xFF334155)),
];

/// Index into [kThemes]; the whole app listens to this.
final ValueNotifier<int> themeIndex = ValueNotifier<int>(0);

NoorTheme get currentTheme => kThemes[themeIndex.value.clamp(0, kThemes.length - 1)];

/// Background colour for dialogs and bottom sheets.
Color get panelColor => currentTheme.panel;

Future<void> loadTheme() async {
  try {
    final p = await SharedPreferences.getInstance();
    final i = p.getInt('app_theme') ?? 0;
    if (i >= 0 && i < kThemes.length) themeIndex.value = i;
  } catch (_) {}
}

Future<void> setTheme(int i) async {
  if (i < 0 || i >= kThemes.length) return;
  themeIndex.value = i;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setInt('app_theme', i);
  } catch (_) {}
}

/// Gradient background with soft glowing blobs. Glass cards blur this.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeIndex,
      builder: (_, __, ___) {
        final t = currentTheme;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [t.bg1, t.bg2, t.bg3],
                ),
              ),
            ),
            const Positioned(top: -90, left: -70, child: _Blob(280, kGold, .38)),
            Positioned(top: 300, right: -130, child: _Blob(320, t.blob2, .30)),
            Positioned(bottom: -110, left: -90, child: _Blob(340, t.blob3, .32)),
            child,
          ],
        );
      },
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

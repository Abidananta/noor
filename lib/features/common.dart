import 'package:flutter/material.dart';
import '../ui/glass.dart';

/// Glass background + transparent Scaffold + AppBar, used by every feature screen.
class GlassPage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;

  const GlassPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(title), actions: actions, bottom: bottom),
        floatingActionButton: floatingActionButton,
        body: body,
      ),
    );
  }
}

const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// Replaces every 0-9 in [s] with Bangla digits.
String bnDigits(String s) =>
    s.replaceAllMapped(RegExp(r'[0-9]'), (m) => _bnDigits[int.parse(m[0]!)]);

/// Small muted footer note.
class FootNote extends StatelessWidget {
  final String text;
  const FootNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.4, color: wh(.55))),
      );
}

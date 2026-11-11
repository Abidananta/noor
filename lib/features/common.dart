import 'package:flutter/material.dart';
import '../i18n.dart';
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

/// Converts 0-9 to the digits of the current app language
/// (Bangla, Arabic, Urdu and Hindi get their own digits; others keep 0-9).
String bnDigits(String s) => localizeDigits(s);

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

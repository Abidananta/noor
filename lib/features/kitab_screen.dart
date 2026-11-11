import 'package:flutter/material.dart';
import '../i18n.dart';
import 'online_kitab_screen.dart';

/// Kitab menu: every book comes straight from the internet (archive.org),
/// nothing has to be uploaded to GitHub.
class KitabScreen extends StatelessWidget {
  const KitabScreen({super.key});

  @override
  Widget build(BuildContext context) => OnlineKitabScreen(title: tr('f_kitab'));
}

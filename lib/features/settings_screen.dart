import 'package:flutter/material.dart';
import '../config.dart';
import '../i18n.dart';
import '../ui/glass.dart';
import 'common.dart';
import 'prayer_times_screen.dart';
import 'settings_pages.dart';
import 'update_page.dart';

/// Settings tab: a clean list. Every row opens its own full page.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        Text(tr('settings'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        Text(tr('st_look'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _Tile(Icons.palette_rounded, tr('st_color'), () => _open(context, const AppearancePage()),
            sub: tr('st_look_sub')),
        _Tile(Icons.language_rounded, tr('language'), () => _open(context, const LanguagePage()),
            sub: currentLangName),
        ValueListenableBuilder<int>(
          valueListenable: cityIndex,
          builder: (_, c, __) => _Tile(
              Icons.location_on_outlined, tr('pf_area'), () => _open(context, const AreaPage()),
              sub: kCities[c].label),
        ),
        const SizedBox(height: 8),
        Text(tr('pf_app'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _Tile(Icons.system_update_rounded, tr('st_update'), () => _open(context, const UpdatePage()),
            sub: tr('st_update_sub')),
        _Tile(Icons.verified_rounded, tr('st_version'), () => _open(context, const VersionPage()),
            sub: bnDigits('v$kAppVersion')),
        _Tile(Icons.info_outline_rounded, tr('pf_about'), () => _open(context, const AboutPage()),
            sub: tr('st_about_sub')),
        _Tile(Icons.mail_outline_rounded, tr('st_contact'), () => _open(context, const ContactPage()),
            sub: tr('st_contact_sub')),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback onTap;
  const _Tile(this.icon, this.label, this.onTap, {this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        blur: 0,
        radius: 18,
        opacity: 0.10,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: kMint),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 16)),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(sub!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: wh(.65))),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: wh(.6)),
          ],
        ),
      ),
    );
  }
}

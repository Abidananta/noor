import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../i18n.dart';
import '../ui/glass.dart';
import 'app_update.dart';
import 'common.dart';

/// Settings tab: app colour, language, update, version, about, contact.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  void _showVersion(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panelColor,
        title: Text(tr('st_version')),
        content: Text(
          bnDigits(trf('st_version_body', {'v': kAppVersion, 'b': kAppBuild})),
          style: const TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('st_ok'))),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Noor',
      applicationVersion: kAppVersion,
      applicationIcon: const Icon(Icons.nightlight_round, size: 40, color: kGold),
      children: [Text(tr('pf_about_body'))],
    );
  }

  Future<void> _contact(BuildContext context) async {
    final uri = Uri.parse('mailto:$kContactEmail?subject=${Uri.encodeComponent('Noor App')}');
    bool ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {}
    if (!ok && context.mounted) {
      await Clipboard.setData(const ClipboardData(text: kContactEmail));
      if (context.mounted) _snack(context, '${tr('st_email_copied')}: $kContactEmail');
    }
  }

  // ---------- update ----------

  Future<String?> _askRepo(BuildContext context, String initial) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panelColor,
        title: Text(tr('st_repo_title')),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'owner/repo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: Text(tr('save'), style: const TextStyle(color: kGold))),
        ],
      ),
    );
  }

  Future<void> _checkUpdate(BuildContext context) async {
    var repo = await savedUpdateRepo();
    if (repo.isEmpty) {
      if (!context.mounted) return;
      final typed = await _askRepo(context, '');
      final n = typed == null ? null : normalizeRepo(typed);
      if (n == null) return;
      await saveUpdateRepo(n);
      repo = n;
    }
    if (!context.mounted) return;

    // simple blocking progress dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: panelColor,
        content: Row(children: [
          const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: 18),
          Expanded(child: Text(tr('st_checking'))),
        ]),
      ),
    );

    UpdateInfo? info;
    Object? error;
    try {
      info = await fetchLatestRelease(repo);
    } catch (e) {
      error = e;
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close progress

    if (error != null || info == null) {
      final change = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: panelColor,
          title: Text(tr('st_update')),
          content: Text('${tr('st_upd_fail')}\n\n$repo'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('st_change_repo'))),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('st_ok'))),
          ],
        ),
      );
      if (change == true && context.mounted) {
        final typed = await _askRepo(context, repo);
        final n = typed == null ? null : normalizeRepo(typed);
        if (n != null) {
          await saveUpdateRepo(n);
          if (context.mounted) _checkUpdate(context);
        }
      }
      return;
    }

    final latest = info;
    if (!isNewerVersion(latest.version, kAppVersion)) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: panelColor,
          title: Text(tr('st_update')),
          content: Text('${tr('st_uptodate')}\n${bnDigits('v$kAppVersion')}'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('st_ok')))],
        ),
      );
      return;
    }

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panelColor,
        title: Text(tr('st_update')),
        content: Text(bnDigits(trf('st_newver', {'v': latest.version}))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('st_later'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('st_download'), style: const TextStyle(color: kGold))),
        ],
      ),
    );
    if (go == true) {
      try {
        await launchUrl(Uri.parse(latest.url), mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) _snack(context, tr('st_upd_fail'));
      }
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        Text(tr('settings'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        Text(tr('st_look'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        GlassCard(
          blur: 0,
          radius: 18,
          opacity: 0.10,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.palette_rounded, color: kMint),
                const SizedBox(width: 12),
                Text(tr('st_color'), style: const TextStyle(fontSize: 16)),
              ]),
              const SizedBox(height: 14),
              ValueListenableBuilder<int>(
                valueListenable: themeIndex,
                builder: (_, sel, __) => Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 12,
                  spacing: 8,
                  children: [
                    for (int i = 0; i < kThemes.length; i++)
                      _ColorDot(theme: kThemes[i], selected: i == sel, onTap: () => setTheme(i)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _Tile(Icons.language_rounded, tr('language'), () => showLanguageSheet(context),
            sub: currentLangName),
        const SizedBox(height: 18),
        Text(tr('pf_app'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _Tile(Icons.system_update_rounded, tr('st_update'), () => _checkUpdate(context),
            sub: bnDigits('v$kAppVersion')),
        _Tile(Icons.verified_rounded, tr('st_version'), () => _showVersion(context),
            sub: bnDigits('v$kAppVersion')),
        _Tile(Icons.info_outline_rounded, tr('pf_about'), () => _showAbout(context)),
        _Tile(Icons.mail_outline_rounded, tr('st_contact'), () => _contact(context),
            sub: kContactEmail),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final NoorTheme theme;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot({required this.theme, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.bg2, theme.bg3],
                ),
                border: Border.all(color: selected ? kGold : wh(.35), width: selected ? 3 : 1.2),
              ),
              child: selected ? const Icon(Icons.check_rounded, color: Colors.white) : null,
            ),
            const SizedBox(height: 5),
            Text(tr('th_${theme.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: wh(selected ? .95 : .7))),
          ],
        ),
      ),
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

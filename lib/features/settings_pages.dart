import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../i18n.dart';
import '../ui/glass.dart';
import 'common.dart';
import 'prayer_times_screen.dart';

/// Pages opened from the Settings list. Each one is a full screen.

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
}

Widget _sectionTitle(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
    );

// ======================================================================
// Appearance
// ======================================================================

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: tr('st_look'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
        children: [
          GlassCard(
            blur: 0,
            radius: 18,
            opacity: 0.10,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.palette_rounded, color: kMint),
                  const SizedBox(width: 12),
                  Text(tr('st_color'), style: const TextStyle(fontSize: 16)),
                ]),
                const SizedBox(height: 16),
                ValueListenableBuilder<int>(
                  valueListenable: themeIndex,
                  builder: (_, sel, __) => Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 14,
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
        ],
      ),
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

// ======================================================================
// Language
// ======================================================================

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: tr('language'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
        children: [
          for (final l in kLangs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                blur: 0,
                radius: 18,
                opacity: l.$1 == appLang.value ? 0.18 : 0.10,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: () => setLang(l.$1),
                child: Row(children: [
                  Expanded(child: Text(l.$2, style: const TextStyle(fontSize: 17))),
                  if (l.$1 == appLang.value) const Icon(Icons.check_circle_rounded, color: kGold),
                ]),
              ),
            ),
          FootNote(tr('st_lang_hint')),
        ],
      ),
    );
  }
}

// ======================================================================
// Area (used for prayer times)
// ======================================================================

class AreaPage extends StatelessWidget {
  const AreaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: tr('pf_area'),
      body: ValueListenableBuilder<int>(
        valueListenable: cityIndex,
        builder: (_, sel, __) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          children: [
            for (int i = 0; i < kCities.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  blur: 0,
                  radius: 18,
                  opacity: i == sel ? 0.18 : 0.10,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  onTap: () => saveCity(i),
                  child: Row(children: [
                    const Icon(Icons.location_on_outlined, color: kMint),
                    const SizedBox(width: 12),
                    Expanded(child: Text(kCities[i].label, style: const TextStyle(fontSize: 17))),
                    if (i == sel) const Icon(Icons.check_circle_rounded, color: kGold),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Version
// ======================================================================

class VersionPage extends StatelessWidget {
  const VersionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: tr('st_version'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        children: [
          const _AppBadge(),
          const SizedBox(height: 22),
          GlassCard(
            blur: 0,
            radius: 18,
            opacity: 0.10,
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _kv(tr('st_version'), bnDigits(kAppVersion)),
              Divider(color: wh(.15), height: 22),
              _kv('Build', bnDigits(kAppBuild)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Row(children: [
        Expanded(child: Text(k, style: TextStyle(fontSize: 15, color: wh(.75)))),
        Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ]);
}

class _AppBadge extends StatelessWidget {
  const _AppBadge();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: wh(.12),
          border: Border.all(color: kGold.withOpacity(.7), width: 2),
        ),
        child: const Icon(Icons.nightlight_round, size: 46, color: kGold),
      ),
      const SizedBox(height: 12),
      const Text('Noor', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: .5)),
      const SizedBox(height: 2),
      Text(tr('ab_tagline'), style: TextStyle(fontSize: 14, color: wh(.7))),
    ]);
  }
}

// ======================================================================
// About
// ======================================================================

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Widget _card(Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GlassCard(
          blur: 0,
          radius: 18,
          opacity: 0.10,
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, child: child),
        ),
      );

  Widget _feature(String key) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, size: 18, color: kMint),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(tr(key), style: const TextStyle(fontSize: 14.5, height: 1.35))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: tr('pf_about'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          const _AppBadge(),
          const SizedBox(height: 8),
          Center(
            child: Text(bnDigits('v$kAppVersion  ·  Build $kAppBuild'),
                style: TextStyle(fontSize: 13, color: wh(.6))),
          ),
          const SizedBox(height: 22),
          _card(Text(tr('ab_desc'), style: const TextStyle(fontSize: 15, height: 1.55))),
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(tr('ab_features')),
              _feature('ab_f1'),
              _feature('ab_f2'),
              _feature('ab_f3'),
              _feature('ab_f4'),
            ],
          )),
          // Developer
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(tr('ab_dev')),
              Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [kGold, kMint]),
                  ),
                  alignment: Alignment.center,
                  child: const Text('A',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF052A21))),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(kDeveloperCredit,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
                ),
              ]),
              const SizedBox(height: 14),
              Text(tr('ab_dev_note'), style: TextStyle(fontSize: 14, height: 1.5, color: wh(.8))),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const ContactPage())),
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: Text(tr('ab_feedback')),
                ),
              ),
            ],
          )),
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(tr('ab_credits')),
              Text(tr('ab_credits_body'), style: TextStyle(fontSize: 14, height: 1.5, color: wh(.8))),
            ],
          )),
          FootNote('© ${DateTime.now().year} $kDeveloperName · ${tr('ab_rights')}'),
        ],
      ),
    );
  }
}

// ======================================================================
// Contact (in-app mail; the admin address is never displayed)
// ======================================================================

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _name = TextEditingController();
  final _reply = TextEditingController();
  final _msg = TextEditingController();
  int _subject = 0;
  bool _sending = false;

  static const _subjectKeys = ['ct_s_general', 'ct_s_bug', 'ct_s_feature', 'ct_s_content'];
  static const _subjectEn = ['General feedback', 'Problem report', 'Feature request', 'Content correction'];

  @override
  void dispose() {
    _name.dispose();
    _reply.dispose();
    _msg.dispose();
    super.dispose();
  }

  bool _validEmail(String s) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);

  Future<bool> _post(String subject, String body) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(Uri.parse(kContactEndpoint));
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final replyTo = _reply.text.trim();
      req.add(utf8.encode(jsonEncode({
        'access_key': kContactAccessKey,
        'subject': subject,
        'from_name': _name.text.trim().isEmpty ? 'Noor App User' : _name.text.trim(),
        if (replyTo.isNotEmpty) 'email': replyTo,
        'message': body,
      })));
      final res = await req.close().timeout(const Duration(seconds: 25));
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        try {
          final j = jsonDecode(text);
          if (j is Map && j['success'] == false) return false;
        } catch (_) {}
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// Used only until [kContactAccessKey] is configured.
  Future<bool> _viaMailApp(String subject, String body) async {
    final uri = Uri(
      scheme: 'mailto',
      path: kContactEmail,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  Future<void> _send() async {
    final msg = _msg.text.trim();
    final reply = _reply.text.trim();
    if (msg.isEmpty) {
      _snack(context, tr('ct_empty'));
      return;
    }
    if (reply.isNotEmpty && !_validEmail(reply)) {
      _snack(context, tr('ct_bad_email'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);

    final subject = 'Noor App - ${_subjectEn[_subject]}';
    final body = '$msg\n\n--\nApp: Noor v$kAppVersion (build $kAppBuild)\nLanguage: ${appLang.value}';

    final ok = kContactAccessKey.isNotEmpty
        ? await _post(subject, body)
        : await _viaMailApp(subject, body);

    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      if (kContactAccessKey.isNotEmpty) {
        _msg.clear();
        _snack(context, tr('ct_sent'));
        Navigator.pop(context);
      }
    } else {
      _snack(context, tr('ct_fail'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: tr('st_contact'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text(tr('ct_intro'), style: TextStyle(fontSize: 14.5, height: 1.5, color: wh(.8))),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: tr('ct_name'), prefixIcon: const Icon(Icons.person_outline_rounded)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reply,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: tr('ct_reply'), prefixIcon: const Icon(Icons.alternate_email_rounded)),
          ),
          const SizedBox(height: 16),
          Text(tr('ct_subject'), style: TextStyle(fontSize: 13, color: wh(.7))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (int i = 0; i < _subjectKeys.length; i++)
              ChoiceChip(
                label: Text(tr(_subjectKeys[i])),
                selected: _subject == i,
                onSelected: (_) => setState(() => _subject = i),
              ),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _msg,
            minLines: 6,
            maxLines: 10,
            maxLength: 2000,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: tr('ct_message'), alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4))
                : const Icon(Icons.send_rounded),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_sending ? tr('ct_sending') : tr('ct_send'), style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

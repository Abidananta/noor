import 'package:flutter/material.dart';
import '../i18n.dart';
import '../ui/glass.dart';
import 'auth_service.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Shown at app start until the person registers or logs in.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _register = true;
  bool _busy = false;
  bool _showPass = false;
  String? _error;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    String? err;
    if (_register && _name.text.trim().isEmpty) {
      err = 'e_name';
    } else if (!_emailRe.hasMatch(email)) {
      err = 'e_email';
    } else if (_pass.text.length < 6) {
      err = 'e_pass';
    } else if (_register && _pass.text != _pass2.text) {
      err = 'e_match';
    }
    if (err != null) {
      setState(() => _error = tr(err!));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = _register
        ? await registerAccount(
            name: _name.text, email: email, phone: _phone.text, password: _pass.text)
        : await loginWithEmail(email, _pass.text);
    // On success the app switches screens and this State is disposed.
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = res == null ? null : tr(res);
    });
  }

  Future<void> _googleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await loginWithGoogle();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = (res == null || res == kGoogleCancelled) ? null : '${tr('e_google')}\n$res';
    });
  }

  void _switchMode() => setState(() {
        _register = !_register;
        _error = null;
      });

  InputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c),
      );

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? type,
    bool obscure = false,
    Widget? suffix,
    TextInputAction action = TextInputAction.next,
    VoidCallback? onDone,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        enabled: !_busy,
        keyboardType: type,
        obscureText: obscure,
        textInputAction: action,
        onSubmitted: onDone == null ? null : (_) => onDone(),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: wh(.08),
          border: _border(wh(.25)),
          enabledBorder: _border(wh(.25)),
          focusedBorder: _border(kGold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eye = IconButton(
      icon: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
      onPressed: () => setState(() => _showPass = !_showPass),
    );

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => showLanguageSheet(context),
                  icon: const Icon(Icons.language_rounded, size: 18, color: kGold),
                  label: Text(currentLangName, style: const TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [kGold.withOpacity(.45), kGold.withOpacity(.12)]),
                    border: Border.all(color: kGold.withOpacity(.6)),
                  ),
                  child: const Icon(Icons.nightlight_round, size: 40, color: kGold),
                ),
              ),
              const SizedBox(height: 16),
              Text(tr('auth_welcome'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(_register ? tr('auth_sub') : tr('auth_sub_login'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.5, color: wh(.75))),
              const SizedBox(height: 22),
              GlassCard(
                blur: 0,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Column(
                  children: [
                    if (_register)
                      _field(_name, tr('auth_name'), Icons.person_outline_rounded),
                    _field(_email, tr('auth_email'), Icons.mail_outline_rounded,
                        type: TextInputType.emailAddress),
                    if (_register)
                      _field(_phone, tr('auth_phone'), Icons.phone_outlined,
                          type: TextInputType.phone),
                    _field(_pass, tr('auth_pass'), Icons.lock_outline_rounded,
                        obscure: !_showPass,
                        suffix: eye,
                        action: _register ? TextInputAction.next : TextInputAction.done,
                        onDone: _register ? null : _submit),
                    if (_register)
                      _field(_pass2, tr('auth_pass2'), Icons.lock_reset_rounded,
                          obscure: !_showPass,
                          action: TextInputAction.done,
                          onDone: _submit),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFF87171), fontSize: 13.5)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: const Color(0xFF052A21),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(_register ? tr('auth_register') : tr('auth_login'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: wh(.25))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(tr('auth_or'), style: TextStyle(color: wh(.7))),
                  ),
                  Expanded(child: Divider(color: wh(.25))),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _busy ? null : _googleLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  side: BorderSide(color: wh(.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration:
                          const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      child: const Text('G',
                          style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.w900,
                              fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Text(tr('auth_google'), style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _busy ? null : _switchMode,
                child: Text(_register ? tr('auth_to_login') : tr('auth_to_reg'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kMint, fontSize: 14.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

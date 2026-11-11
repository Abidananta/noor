import 'package:flutter/material.dart';
import '../features/common.dart';
import '../i18n.dart';
import '../ui/glass.dart';
import 'auth_service.dart';
import 'user_avatar.dart';

/// Lets a registered user change their name and phone number.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;
  String? _error;
  late String _avatar;

  @override
  void initState() {
    super.initState();
    final a = currentAccount.value;
    _name = TextEditingController(text: a?.name ?? '');
    _phone = TextEditingController(text: a?.phone ?? '');
    final saved = a?.avatar ?? '';
    _avatar = kAvatarIds.contains(saved) ? saved : '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = tr('e_name'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await updateProfileInfo(name: _name.text, phone: _phone.text, avatar: _avatar);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('pf_saved')), duration: const Duration(seconds: 1)));
    Navigator.pop(context);
  }

  InputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c),
      );

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: wh(.08),
        border: _border(wh(.25)),
        enabledBorder: _border(wh(.25)),
        focusedBorder: _border(kGold),
      );

  @override
  Widget build(BuildContext context) {
    final a = currentAccount.value;
    return GlassPage(
      title: tr('pf_edit'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Center(child: UserAvatar(radius: 46, fontSize: 36, avatarOverride: _avatar)),
          const SizedBox(height: 14),
          Text(tr('pf_avatar'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: wh(.75))),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              // first choice = no icon (name letter / Google photo)
              _AvatarChoice(
                selected: _avatar.isEmpty,
                onTap: () => setState(() => _avatar = ''),
                child: const Icon(Icons.person_rounded, color: Colors.white70),
              ),
              for (final id in kAvatarIds)
                _AvatarChoice(
                  selected: _avatar == id,
                  onTap: () => setState(() => _avatar = id),
                  child: ClipOval(
                    child: Image.asset(avatarAsset(id), width: 56, height: 56, fit: BoxFit.cover),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _name,
            maxLength: 30,
            textInputAction: TextInputAction.next,
            decoration: _deco(tr('auth_name'), Icons.person_outline_rounded),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: _deco(tr('auth_phone'), Icons.phone_outlined),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: a?.email ?? ''),
            enabled: false,
            decoration: _deco(tr('auth_email'), Icons.mail_outline_rounded)
                .copyWith(helperText: tr('pf_email_fixed')),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFF87171))),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: kGold,
              foregroundColor: const Color(0xFF052A21),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(tr('save'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  const _AvatarChoice({required this.selected, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 62,
        height: 62,
        padding: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: wh(.12),
          border: Border.all(color: selected ? kGold : wh(.25), width: selected ? 2.5 : 1),
        ),
        child: child,
      ),
    );
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/profile_screen.dart' show profileName;

/// A registered user (stored on this phone only).
class Account {
  final String email;
  final String name;
  final String phone;
  final String photo; // Google photo URL (empty for email accounts)
  final String provider; // 'local' | 'google'
  final String avatar; // emoji chosen as profile icon ('' = initial / Google photo)

  const Account({
    required this.email,
    required this.name,
    this.phone = '',
    this.photo = '',
    this.provider = 'local',
    this.avatar = '',
  });
}

/// null = nobody is logged in -> the app shows the register / login screen.
final ValueNotifier<Account?> currentAccount = ValueNotifier<Account?>(null);

/// Returned by [loginWithGoogle] when the person just closed the Google picker.
const String kGoogleCancelled = '__cancelled__';

const _kAccounts = 'accounts_v1';
const _kSession = 'session_email';

final GoogleSignIn _google = GoogleSignIn(scopes: const ['email', 'profile']);

Map<String, Map<String, dynamic>> _readAll(SharedPreferences p) {
  final raw = p.getString(_kAccounts);
  if (raw == null || raw.isEmpty) return {};
  try {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
  } catch (_) {
    return {};
  }
}

Future<void> _writeAll(SharedPreferences p, Map<String, Map<String, dynamic>> all) =>
    p.setString(_kAccounts, jsonEncode(all));

Account _acc(String email, Map<String, dynamic> r) => Account(
      email: email,
      name: (r['name'] as String?) ?? '',
      phone: (r['phone'] as String?) ?? '',
      photo: (r['photo'] as String?) ?? '',
      provider: (r['provider'] as String?) ?? 'local',
      avatar: (r['avatar'] as String?) ?? '',
    );

String _salt() {
  final r = Random.secure();
  return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
}

String _hash(String salt, String password) =>
    sha256.convert(utf8.encode('$salt:$password')).toString();

Future<void> _startSession(SharedPreferences p, Account a) async {
  await p.setString(_kSession, a.email);
  // The rest of the app (home header, avatars) reads profile_name.
  await p.setString('profile_name', a.name);
  profileName.value = a.name;
  currentAccount.value = a;
}

/// Restores the logged-in user at app start.
Future<void> loadAuth() async {
  try {
    final p = await SharedPreferences.getInstance();
    final email = p.getString(_kSession);
    if (email == null) return;
    final r = _readAll(p)[email];
    if (r == null) return;
    final a = _acc(email, r);
    profileName.value = a.name;
    currentAccount.value = a;
  } catch (_) {}
}

/// Returns null on success, otherwise an i18n key describing the problem.
Future<String?> registerAccount({
  required String name,
  required String email,
  String phone = '',
  required String password,
}) async {
  final p = await SharedPreferences.getInstance();
  final all = _readAll(p);
  final key = email.trim().toLowerCase();
  if (all.containsKey(key)) return 'e_exists';
  final salt = _salt();
  all[key] = {
    'name': name.trim(),
    'phone': phone.trim(),
    'photo': '',
    'provider': 'local',
    'salt': salt,
    'hash': _hash(salt, password),
  };
  await _writeAll(p, all);
  await _startSession(p, _acc(key, all[key]!));
  return null;
}

/// Returns null on success, otherwise an i18n key describing the problem.
Future<String?> loginWithEmail(String email, String password) async {
  final p = await SharedPreferences.getInstance();
  final key = email.trim().toLowerCase();
  final r = _readAll(p)[key];
  if (r == null) return 'e_cred';
  final hash = (r['hash'] as String?) ?? '';
  if (hash.isEmpty) return 'e_googleonly';
  if (_hash((r['salt'] as String?) ?? '', password) != hash) return 'e_cred';
  await _startSession(p, _acc(key, r));
  return null;
}

/// Returns null on success, [kGoogleCancelled] if the person backed out,
/// otherwise a short technical message (shown to help with setup problems).
Future<String?> loginWithGoogle() async {
  try {
    final g = await _google.signIn();
    if (g == null) return kGoogleCancelled;
    final p = await SharedPreferences.getInstance();
    final all = _readAll(p);
    final key = g.email.trim().toLowerCase();
    final r = all[key] ?? <String, dynamic>{'phone': '', 'provider': 'google'};
    // Keep a name the person already edited; otherwise use the Google name.
    if (((r['name'] as String?) ?? '').trim().isEmpty) {
      r['name'] = (g.displayName ?? '').trim().isEmpty
          ? key.split('@').first
          : g.displayName!.trim();
    }
    r['photo'] = g.photoUrl ?? (r['photo'] as String?) ?? '';
    all[key] = r;
    await _writeAll(p, all);
    await _startSession(p, _acc(key, r));
    return null;
  } catch (e) {
    final s = e.toString();
    return s.length > 140 ? s.substring(0, 140) : s;
  }
}

/// Saves edited name / phone for the logged-in user.
Future<void> updateProfileInfo({
  required String name,
  required String phone,
  String? avatar, // null = keep as is, '' = back to initial / photo
}) async {
  final a = currentAccount.value;
  if (a == null) return;
  final p = await SharedPreferences.getInstance();
  final all = _readAll(p);
  final r = all[a.email] ?? <String, dynamic>{};
  r['name'] = name.trim();
  r['phone'] = phone.trim();
  if (avatar != null) r['avatar'] = avatar;
  all[a.email] = r;
  await _writeAll(p, all);
  await p.setString('profile_name', name.trim());
  profileName.value = name.trim();
  currentAccount.value = _acc(a.email, r);
}

/// Logs out. The account itself stays on the phone, so logging in again
/// brings the profile back.
Future<void> logoutAccount() async {
  try {
    await _google.signOut();
  } catch (_) {}
  final p = await SharedPreferences.getInstance();
  await p.remove(_kSession);
  await p.remove('profile_name');
  profileName.value = '';
  currentAccount.value = null;
}

/// Used after "delete all data" (preferences were already cleared).
Future<void> resetAuthState() async {
  try {
    await _google.signOut();
  } catch (_) {}
  profileName.value = '';
  currentAccount.value = null;
}

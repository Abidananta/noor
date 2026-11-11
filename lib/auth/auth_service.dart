import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/profile_screen.dart' show profileName;

/// The logged-in user. Login itself is handled by Firebase Authentication;
/// phone number and chosen avatar are kept on this phone (keyed by user id).
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

const _kExtras = 'account_extras_v1'; // { uid: { phone, avatar } }

final GoogleSignIn _google = GoogleSignIn(scopes: const ['email', 'profile']);

FirebaseAuth get _auth => FirebaseAuth.instance;

Future<Map<String, Map<String, dynamic>>> _readExtras() async {
  try {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kExtras);
    if (raw == null || raw.isEmpty) return {};
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
  } catch (_) {
    return {};
  }
}

Future<void> _writeExtras(Map<String, Map<String, dynamic>> all) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_kExtras, jsonEncode(all));
}

/// Saved phone / avatar / name of a user. Looked up by uid first, then by
/// email (so the data is still found if the uid ever differs).
Map<String, dynamic> _extraOf(Map<String, Map<String, dynamic>> all, User u) {
  final byUid = all[u.uid];
  if (byUid != null) return byUid;
  final email = (u.email ?? '').toLowerCase();
  return (email.isNotEmpty ? all['email:$email'] : null) ?? const <String, dynamic>{};
}

void _putExtra(Map<String, Map<String, dynamic>> all, User u, Map<String, dynamic> v) {
  all[u.uid] = v;
  final email = (u.email ?? '').toLowerCase();
  if (email.isNotEmpty) all['email:$email'] = v;
}

Future<Account> _accountOf(User u) async {
  final extras = _extraOf(await _readExtras(), u);
  final email = (u.email ?? '').toLowerCase();
  final saved = ((extras['name'] as String?) ?? '').trim();
  final name = saved.isNotEmpty ? saved : (u.displayName ?? '').trim();
  final isGoogle = u.providerData.any((i) => i.providerId == 'google.com');
  return Account(
    email: email,
    name: name.isEmpty ? email.split('@').first : name,
    phone: (extras['phone'] as String?) ?? '',
    photo: u.photoURL ?? '',
    provider: isGoogle ? 'google' : 'local',
    avatar: (extras['avatar'] as String?) ?? '',
  );
}

Future<void> _startSession(User u) async {
  final a = await _accountOf(u);
  final p = await SharedPreferences.getInstance();
  // The rest of the app (home header, avatars) reads profile_name.
  await p.setString('profile_name', a.name);
  profileName.value = a.name;
  currentAccount.value = a;
}

/// Maps a Firebase error to an i18n key.
String _errKey(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'e_exists';
    case 'invalid-email':
      return 'e_email';
    case 'weak-password':
      return 'e_pass';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-login-credentials':
    case 'user-disabled':
      return 'e_cred';
    case 'network-request-failed':
      return 'e_net';
    default:
      return 'e_fail';
  }
}

/// Restores the logged-in user at app start (Firebase keeps the session).
Future<void> loadAuth() async {
  try {
    var u = _auth.currentUser;
    if (u == null) {
      // The saved session can arrive a moment after start-up.
      try {
        u = await _auth
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    if (u == null) return;
    final a = await _accountOf(u);
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
  try {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final u = cred.user!;
    await u.updateDisplayName(name.trim());
    final extras = await _readExtras();
    _putExtra(extras, u, {
      ...Map<String, dynamic>.from(_extraOf(extras, u)),
      'name': name.trim(),
      'phone': phone.trim(),
    });
    await _writeExtras(extras);
    await u.reload();
    await _startSession(_auth.currentUser ?? u);
    return null;
  } on FirebaseAuthException catch (e) {
    return _errKey(e);
  } catch (_) {
    return 'e_fail';
  }
}

/// Returns null on success, otherwise an i18n key describing the problem.
Future<String?> loginWithEmail(String email, String password) async {
  try {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _startSession(cred.user!);
    return null;
  } on FirebaseAuthException catch (e) {
    return _errKey(e);
  } catch (_) {
    return 'e_fail';
  }
}

/// Returns null on success, [kGoogleCancelled] if the person backed out,
/// otherwise a short technical message (shown to help with setup problems).
Future<String?> loginWithGoogle() async {
  try {
    final g = await _google.signIn();
    if (g == null) return kGoogleCancelled;
    final ga = await g.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: ga.accessToken,
      idToken: ga.idToken,
    );
    final res = await _auth.signInWithCredential(credential);
    await _startSession(res.user!);
    return null;
  } catch (e) {
    final s = e.toString();
    return s.length > 140 ? s.substring(0, 140) : s;
  }
}

/// Saves edited name / phone / avatar for the logged-in user.
/// Everything is written on the phone first, so it is kept even when the
/// internet is slow or off; the Firebase display name is updated afterwards.
Future<void> updateProfileInfo({
  required String name,
  required String phone,
  String? avatar, // null = keep as is, '' = back to initial / photo
}) async {
  final u = _auth.currentUser;
  final old = currentAccount.value;
  if (u == null && old == null) return;
  final cleanName = name.trim();
  final cleanPhone = phone.trim();

  var avatarId = old?.avatar ?? '';
  if (u != null) {
    final extras = await _readExtras();
    final r = Map<String, dynamic>.from(_extraOf(extras, u));
    r['name'] = cleanName;
    r['phone'] = cleanPhone;
    if (avatar != null) r['avatar'] = avatar;
    avatarId = (r['avatar'] as String?) ?? '';
    _putExtra(extras, u, r);
    await _writeExtras(extras);
  } else if (avatar != null) {
    avatarId = avatar;
  }

  final p = await SharedPreferences.getInstance();
  await p.setString('profile_name', cleanName);
  profileName.value = cleanName;
  currentAccount.value = Account(
    email: old?.email ?? (u?.email ?? '').toLowerCase(),
    name: cleanName,
    phone: cleanPhone,
    photo: old?.photo ?? (u?.photoURL ?? ''),
    provider: old?.provider ?? 'local',
    avatar: avatarId,
  );

  // Best effort only - never blocks or loses the local save.
  if (u != null) {
    try {
      await u.updateDisplayName(cleanName).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}

/// Logs out. The account stays in Firebase, so logging in again brings the
/// profile back.
Future<void> logoutAccount() async {
  try {
    await _google.signOut();
  } catch (_) {}
  try {
    await _auth.signOut();
  } catch (_) {}
  final p = await SharedPreferences.getInstance();
  await p.remove('profile_name');
  profileName.value = '';
  currentAccount.value = null;
}

/// Used after "delete all data" (preferences were already cleared).
Future<void> resetAuthState() async {
  try {
    await _google.signOut();
  } catch (_) {}
  try {
    await _auth.signOut();
  } catch (_) {}
  profileName.value = '';
  currentAccount.value = null;
}

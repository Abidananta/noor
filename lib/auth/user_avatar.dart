import 'package:flutter/material.dart';
import '../features/profile_screen.dart' show initialOf;
import 'auth_service.dart';

/// 3D-style human avatars (assets/avatars/av_<id>.png) a user can pick.
const List<String> kAvatarIds = [
  'boy_white',
  'girl_pink',
  'man_beard',
  'woman_teal',
  'grandpa',
  'girl_yellow',
  'man_ghutrah',
  'woman_navy',
  'boy_green',
];

String avatarAsset(String id) => 'assets/avatars/av_$id.png';

/// Round avatar: chosen 3D avatar, else Google photo, else first letter.
/// [avatarOverride] is used for live preview while editing
/// (null = use the account's, '' = no avatar).
class UserAvatar extends StatelessWidget {
  final double radius;
  final double fontSize;
  final String? avatarOverride;
  const UserAvatar({
    super.key,
    required this.radius,
    required this.fontSize,
    this.avatarOverride,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Account?>(
      valueListenable: currentAccount,
      builder: (_, a, __) {
        final id = avatarOverride ?? a?.avatar ?? '';
        if (kAvatarIds.contains(id)) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xFFFFF1D0),
            backgroundImage: AssetImage(avatarAsset(id)),
          );
        }
        final photo = a?.photo ?? '';
        return CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFE91E63),
          foregroundImage: photo.isEmpty ? null : NetworkImage(photo),
          onForegroundImageError: photo.isEmpty ? null : (_, __) {},
          child: Text(
            initialOf(a?.name ?? ''),
            style: TextStyle(
                fontSize: fontSize, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        );
      },
    );
  }
}

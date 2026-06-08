import 'package:flutter/material.dart';

class AvatarPreset {
  const AvatarPreset({
    required this.value,
    required this.color,
    required this.icon,
  });

  final String value;
  final Color color;
  final IconData icon;
}

const appAvatarPresets = <AvatarPreset>[
  AvatarPreset(
    value: 'preset:teal',
    color: Color(0xFF00796B),
    icon: Icons.auto_awesome,
  ),
  AvatarPreset(
    value: 'preset:coral',
    color: Color(0xFFD84315),
    icon: Icons.local_fire_department,
  ),
  AvatarPreset(
    value: 'preset:blue',
    color: Color(0xFF1565C0),
    icon: Icons.bolt,
  ),
  AvatarPreset(
    value: 'preset:green',
    color: Color(0xFF2E7D32),
    icon: Icons.eco,
  ),
  AvatarPreset(
    value: 'preset:violet',
    color: Color(0xFF6A1B9A),
    icon: Icons.nights_stay,
  ),
  AvatarPreset(
    value: 'preset:gold',
    color: Color(0xFFF9A825),
    icon: Icons.wb_sunny,
  ),
];

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.username,
    this.avatarUrl,
    this.radius = 20,
  });

  final String username;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final preset = avatarPresetFor(avatarUrl);
    final imageUrl = avatarUrl != null && !avatarUrl!.startsWith('preset:')
        ? avatarUrl
        : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: preset?.color ?? Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
      child: imageUrl != null
          ? null
          : Icon(preset?.icon ?? Icons.person, size: radius),
    );
  }
}

AvatarPreset? avatarPresetFor(String? value) {
  if (value == null) return null;
  for (final preset in appAvatarPresets) {
    if (preset.value == value) return preset;
  }
  return null;
}

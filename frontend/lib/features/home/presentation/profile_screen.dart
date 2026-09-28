import '../../../core/widgets/app_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/data/auth_repository.dart';
import '../../users/data/user_profile_api_client.dart';
import '../../users/presentation/app_avatar.dart';
import '../../users/presentation/user_identity_view.dart';
import '../../users/data/user_identity_adapters.dart';
import '../../users/data/user_session.dart';
import '../../notifications/notification_host.dart';

final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  ref.watch(activeAccountIdProvider);
  ref.watch(identityRevisionProvider);
  final client = ref.watch(userProfileApiClientProvider);
  return client.getMyProfile();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      ref.read(appAuthStateProvider.notifier).state =
          const AppAuthState.unauthenticated();
      if (mounted) {
        context.go('/auth');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<void> _openEditProfile(UserProfile profile) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _EditProfileDialog(
        profile: profile,
        onChangePassword: _openChangePassword,
      ),
    );

    if (updated == true) {
      ref.invalidate(userProfileProvider);
    }
  }

  Future<void> _openChangePassword() {
    return showDialog<void>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              profileAsync.when(
                data: (profile) => _ProfileHeader(profile: profile),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const Text('Could not load profile.'),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: () => ref.invalidate(userProfileProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    profileAsync.maybeWhen(
                      data: (profile) => ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit Profile'),
                        subtitle: const Text('Username, password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _isLoggingOut
                            ? null
                            : () => _openEditProfile(profile),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const NotificationSettingsTile(),
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode),
                      title: const Text('Dark mode'),
                      value: themeMode == ThemeMode.dark,
                      onChanged: _isLoggingOut
                          ? null
                          : (value) {
                              ref.read(themeModeProvider.notifier).state = value
                                  ? ThemeMode.dark
                                  : ThemeMode.light;
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: FilledButton.tonal(
                  onPressed: _isLoggingOut ? null : _logout,
                  style: FilledButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onErrorContainer,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.errorContainer,
                  ),
                  child: _isLoggingOut
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Log out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: UserIdentityView(
        user: profile.identity,
        layout: UserIdentityLayout.header,
      ),
    );
  }
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({
    required this.profile,
    required this.onChangePassword,
  });

  final UserProfile profile;
  final VoidCallback onChangePassword;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  late final TextEditingController _usernameController;
  late String _avatarUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profile.username);
    _avatarUrl = widget.profile.avatarUrl ?? appAvatarPresets.first.value;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      showAppNotice(context, 'Username is required.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = await ref
          .read(userProfileApiClientProvider)
          .updateMyProfile(username: username, avatarUrl: _avatarUrl);

      if (mounted && ref.read(activeAccountIdProvider) == widget.profile.id) {
        ref.read(userIdentityOverridesProvider.notifier).state = {
          ...ref.read(userIdentityOverridesProvider),
          updated.id: updated.identity,
        };
        ref.read(identityRevisionProvider.notifier).state++;
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        showAppNotice(
          context,
          error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _usernameController,
              enabled: !_isSaving,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 18),
            Text('Avatar', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: appAvatarPresets.map((preset) {
                final selected = preset.value == _avatarUrl;
                return InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _isSaving
                      ? null
                      : () {
                          setState(() => _avatarUrl = preset.value);
                        },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: preset.color,
                        foregroundColor: Colors.white,
                        child: Icon(preset.icon, size: 22),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _isSaving
                    ? null
                    : () {
                        widget.onChangePassword();
                      },
                icon: const Icon(Icons.lock_reset),
                label: const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      showAppNotice(context, 'Current and new password are required.');
      return;
    }

    if (newPassword.length < 6) {
      showAppNotice(context, 'New password must be at least 6 characters.');
      return;
    }

    if (newPassword != confirmPassword) {
      showAppNotice(context, 'New passwords do not match.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );

      if (mounted) {
        Navigator.of(context).pop();
        showAppNotice(context, 'Password changed.');
      }
    } catch (error) {
      if (mounted) {
        showAppNotice(
          context,
          error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _currentPasswordController,
              enabled: !_isSaving,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.password],
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Current password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _newPasswordController,
              enabled: !_isSaving,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'New password',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _confirmPasswordController,
              enabled: !_isSaving,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_scaffold.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _savingProfile = false;
  String? _lastHydratedProfileKey;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(SessionController session) async {
    setState(() => _savingProfile = true);
    try {
      final profile = await session.api.updateProfile(
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      await session.refreshProfile(silentOnFailure: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
      );
      setState(() {
        _displayNameController.text = profile.displayName ?? '';
        _emailController.text = profile.email ?? '';
        _phoneController.text = profile.phone ?? '';
        _lastHydratedProfileKey = _profileKey(profile);
      });
    } on ApiException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword(SessionController session) async {
    final currentController = TextEditingController();
    final nextController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current password'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Current password is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nextController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (value) =>
                      value == null || value.length < 6 ? 'Use at least 6 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm password'),
                  validator: (value) =>
                      value != nextController.text ? 'Passwords do not match' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await session.api.changePassword(
                    currentPassword: currentController.text,
                    newPassword: nextController.text,
                  );
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop(true);
                } on ApiException catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
    currentController.dispose();
    nextController.dispose();
    confirmController.dispose();
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final profile = session.profile;
    _hydrateControllers(profile);

    return AppScaffold(
      title: 'Profile',
      current: AppSection.profile,
      body: profile == null
          ? Center(
              child: FilledButton(
                onPressed: () => session.refreshProfile(),
                child: const Text('Load profile'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: unzaGreen.withOpacity(0.12),
                              child: const Icon(Icons.person_outline, color: unzaGreen, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.displayName ?? profile.username,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(profile.username),
                                  const SizedBox(height: 4),
                                  Text(userRoleToApi(profile.role)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Account created ${DateFormat('dd MMM yyyy').format(profile.createdAt)}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Update profile',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(labelText: 'Display name'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _savingProfile ? null : () => _saveProfile(session),
                          child: _savingProfile
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save profile'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _changePassword(session),
                          child: const Text('Change password'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _hydrateControllers(UserProfile? profile) {
    if (profile == null) return;
    final nextKey = _profileKey(profile);
    if (_lastHydratedProfileKey == nextKey) return;
    _displayNameController.text = profile.displayName ?? '';
    _emailController.text = profile.email ?? '';
    _phoneController.text = profile.phone ?? '';
    _lastHydratedProfileKey = nextKey;
  }

  String _profileKey(UserProfile profile) {
    return [
      profile.id,
      profile.displayName ?? '',
      profile.email ?? '',
      profile.phone ?? '',
      profile.enabled.toString(),
      profile.createdAt.toIso8601String(),
    ].join('|');
  }
}

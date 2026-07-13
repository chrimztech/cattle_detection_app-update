import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_scaffold.dart';
import 'login_page.dart';
import 'session_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _baseUrlController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(
      text: context.read<SessionController>().apiBaseUrl,
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveBaseUrl() async {
    setState(() => _saving = true);
    final session = context.read<SessionController>();
    try {
      await session.updateApiBaseUrl(_baseUrlController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            session.isAuthenticated
                ? 'API base URL updated'
                : 'API base URL updated. Sign in again to continue.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      if (!session.isAuthenticated) {
        _redirectToLogin();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
      if (!session.isAuthenticated) {
        _redirectToLogin();
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await context.read<SessionController>().logout();
    if (!mounted) return;
    _redirectToLogin();
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return AppScaffold(
      title: 'Settings',
      current: AppSection.settings,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Backend connection',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use your backend host here. For Android emulators, `http://10.0.2.2:8080` works. For a physical device, use your laptop LAN IP. In production, match the backend PUBLIC_BASE_URL value.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'API base URL',
                      hintText: 'http://10.0.2.2:8080',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _saveBaseUrl,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save connection'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current session: ${session.session?.username ?? 'No user'}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.redAccent),
              ),
              subtitle: const Text('End the current backend-authenticated mobile session.'),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }
}

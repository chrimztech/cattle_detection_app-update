import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_scaffold.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<AdminUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AdminUser>> _load() {
    return context.read<SessionController>().api.listUsers();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _setRole(AdminUser user, UserRole role) async {
    if (user.role == role) return;
    try {
      await context.read<SessionController>().api.setUserRole(user.id, role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User role updated'), backgroundColor: Colors.green),
      );
      _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _toggleEnabled(AdminUser user) async {
    try {
      await context.read<SessionController>().api.setUserEnabled(user.id, !user.enabled);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(user.enabled ? 'User disabled' : 'User enabled'),
          backgroundColor: Colors.green,
        ),
      );
      _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete user?'),
          content: Text(
            'Delete ${user.username}? This action permanently removes the account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (confirmed != true) return;

    try {
      await context.read<SessionController>().api.deleteUser(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted'), backgroundColor: Colors.green),
      );
      _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final currentUser = session.session;

    if (currentUser?.role != UserRole.admin) {
      return AppScaffold(
        title: 'Admin',
        current: AppSection.admin,
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: Colors.black38),
                SizedBox(height: 12),
                Text(
                  'Only administrators can manage users from this screen.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final signedInUser = currentUser!;

    return AppScaffold(
      title: 'Admin',
      current: AppSection.admin,
      actions: [
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AdminUser>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }

            final users = snapshot.data ?? const <AdminUser>[];
            if (users.isEmpty) {
              return const Center(child: Text('No users found.'));
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: users.map((user) {
                final isCurrentUser = user.id == signedInUser.id;
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: unzaGold.withOpacity(0.18),
                              child: Text(
                                user.username.isEmpty
                                    ? '?'
                                    : user.username.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: unzaBlack,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.username,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Joined ${DateFormat('dd MMM yyyy').format(user.createdAt)}',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: user.enabled
                                    ? unzaGreen.withOpacity(0.12)
                                    : Colors.black.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                user.enabled ? 'Active' : 'Disabled',
                                style: TextStyle(
                                  color: user.enabled ? unzaGreen : Colors.black54,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<UserRole>(
                          initialValue: user.role,
                          decoration: const InputDecoration(labelText: 'Role'),
                          items: UserRole.values
                              .map(
                                (role) => DropdownMenuItem<UserRole>(
                                  value: role,
                                  child: Text(userRoleToApi(role)),
                                ),
                              )
                              .toList(),
                          onChanged: isCurrentUser
                              ? null
                              : (role) {
                                  if (role != null) {
                                    _setRole(user, role);
                                  }
                                },
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: isCurrentUser ? null : () => _toggleEnabled(user),
                              icon: Icon(
                                user.enabled ? Icons.block_outlined : Icons.check_circle_outline,
                              ),
                              label: Text(user.enabled ? 'Disable' : 'Enable'),
                            ),
                            OutlinedButton.icon(
                              onPressed: isCurrentUser ? null : () => _deleteUser(user),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                              ),
                            ),
                            if (isCurrentUser)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'Your own account can’t be changed here.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

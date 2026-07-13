import 'admin_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_scaffold.dart';
import 'cattle_list_page.dart';
import 'cattle_registration_page.dart';
import 'detection/camera_view.dart';
import 'detection_history_page.dart';
import 'models/app_models.dart';
import 'planner_page.dart';
import 'reports_page.dart';
import 'session_controller.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_DashboardBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardBundle> _load() async {
    final session = context.read<SessionController>();
    final profile = session.profile ?? await session.api.getProfile();
    final stats = await session.api.getStats();
    final cattle = await session.api.listCattle(size: 5);
    final tasks = await session.api.listPlannerTasks();
    final detectionHistory = await session.api.listDetectionHistory(size: 5);
    return _DashboardBundle(
      profile: profile,
      stats: stats,
      recentCattle: cattle.content,
      plannerTasks: tasks,
      detections: detectionHistory.content,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      current: AppSection.dashboard,
      actions: [
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_DashboardBundle>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _DashboardError(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeroCard(profile: data.profile),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.12,
                  children: [
                    _StatCard(
                      label: 'Total Cattle',
                      value: '${data.stats.totalCattle}',
                      icon: Icons.pets_outlined,
                      color: unzaGreen,
                    ),
                    _StatCard(
                      label: 'Farms',
                      value: '${data.stats.totalFarms}',
                      icon: Icons.agriculture_outlined,
                      color: unzaGold,
                    ),
                    _StatCard(
                      label: 'Detections',
                      value: '${data.stats.detectionCount}',
                      icon: Icons.camera_alt_outlined,
                      color: unzaRed,
                    ),
                    _StatCard(
                      label: 'Open Tasks',
                      value:
                          '${data.plannerTasks.where((task) => task.status == PlannerStatus.open).length}',
                      icon: Icons.event_note_outlined,
                      color: Colors.indigo,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ActionChip(
                      icon: Icons.app_registration,
                      label: 'Register',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CattleRegistrationPage()),
                        );
                      },
                    ),
                    _ActionChip(
                      icon: Icons.camera_alt_outlined,
                      label: 'Detect',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CameraView()),
                        );
                      },
                    ),
                    _ActionChip(
                      icon: Icons.history,
                      label: 'History',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DetectionHistoryPage()),
                        );
                      },
                    ),
                    _ActionChip(
                      icon: Icons.bar_chart_outlined,
                      label: 'Reports',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ReportsPage()),
                        );
                      },
                    ),
                    if (data.profile.role == UserRole.admin)
                      _ActionChip(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Admin',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminPage()),
                          );
                        },
                      ),
                    _ActionChip(
                      icon: Icons.event_note_outlined,
                      label: 'Planner',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PlannerPage()),
                        );
                      },
                    ),
                    _ActionChip(
                      icon: Icons.pets_outlined,
                      label: 'Registry',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CattleListPage()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Recent Cattle',
                  subtitle: 'Newest backend records in the registry.',
                  trailingLabel: 'Open registry',
                  onTrailingTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CattleListPage()),
                    );
                  },
                  child: Column(
                    children: data.recentCattle.isEmpty
                        ? const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text('No cattle records yet.'),
                            ),
                          ]
                        : data.recentCattle
                            .map(
                              (item) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: unzaGreen.withOpacity(0.12),
                                  child: const Icon(Icons.pets_outlined, color: unzaGreen),
                                ),
                                title: Text(item.cattleId),
                                subtitle: Text('${item.breed} • ${item.owner}'),
                                trailing: Text(DateFormat('dd MMM').format(item.registeredAt)),
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Planner Snapshot',
                  subtitle: 'Upcoming and overdue tasks for this account.',
                  trailingLabel: 'Open planner',
                  onTrailingTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PlannerPage()),
                    );
                  },
                  child: Column(
                    children: data.plannerTasks.isEmpty
                        ? const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text('No planner tasks yet.'),
                            ),
                          ]
                        : data.plannerTasks.take(4).map((task) {
                            final overdue = task.status == PlannerStatus.open &&
                                task.dueDate.isBefore(DateTime.now());
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                task.status == PlannerStatus.done
                                    ? Icons.check_circle
                                    : overdue
                                        ? Icons.warning_amber_rounded
                                        : Icons.schedule,
                                color: task.status == PlannerStatus.done
                                    ? Colors.green
                                    : overdue
                                        ? Colors.orange
                                        : Colors.blueGrey,
                              ),
                              title: Text(task.title),
                              subtitle: Text(
                                '${DateFormat('dd MMM yyyy').format(task.dueDate)} • ${plannerPriorityToApi(task.priority)}',
                              ),
                            );
                          }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Detection Timeline',
                  subtitle: 'Most recent backend detection runs.',
                  trailingLabel: 'Open history',
                  onTrailingTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DetectionHistoryPage()),
                    );
                  },
                  child: Column(
                    children: data.detections.isEmpty
                        ? const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text('No detection history yet.'),
                            ),
                          ]
                        : data.detections.map((item) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: unzaRed.withOpacity(0.12),
                                child: const Icon(Icons.camera_alt_outlined, color: unzaRed),
                              ),
                              title: Text(
                                '${item.detectionCount} detection${item.detectionCount == 1 ? '' : 's'}',
                              ),
                              subtitle: Text(
                                '${item.username} • ${DateFormat('dd MMM, HH:mm').format(item.createdAt)}',
                              ),
                            );
                          }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardBundle {
  final UserProfile profile;
  final AppStats stats;
  final List<CattleRecord> recentCattle;
  final List<PlannerTask> plannerTasks;
  final List<DetectionHistoryItem> detections;

  const _DashboardBundle({
    required this.profile,
    required this.stats,
    required this.recentCattle,
    required this.plannerTasks,
    required this.detections,
  });
}

class _HeroCard extends StatelessWidget {
  final UserProfile profile;

  const _HeroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [unzaGold, unzaGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${profile.displayName ?? profile.username}',
            style: const TextStyle(
              color: unzaBlack,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Role: ${userRoleToApi(profile.role)}',
            style: const TextStyle(
              color: unzaBlack,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'The mobile app is now reading live data from the UNZA cattle backend instead of the old simulated flow.',
            style: TextStyle(color: unzaBlack, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: unzaGreen),
      label: Text(label),
      onPressed: onTap,
      side: const BorderSide(color: Color(0x22009739)),
      backgroundColor: Colors.white,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailingLabel;
  final VoidCallback onTrailingTap;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.trailingLabel,
    required this.onTrailingTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                TextButton(onPressed: onTrailingTap, child: Text(trailingLabel)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DashboardError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text(
                  'Dashboard could not load',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'admin_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cattle_list_page.dart';
import 'cattle_registration_page.dart';
import 'dashboard_page.dart';
import 'detection/camera_view.dart';
import 'detection_history_page.dart';
import 'farm_list_page.dart';
import 'identify_page.dart';
import 'models/app_models.dart';
import 'planner_page.dart';
import 'profile_page.dart';
import 'reports_page.dart';
import 'session_controller.dart';
import 'settings_page.dart';

const Color unzaGold = Color(0xFFFFB000);
const Color unzaGreen = Color(0xFF009739);
const Color unzaRed = Color(0xFFE30613);
const Color unzaBlack = Color(0xFF161616);

enum AppSection {
  dashboard,
  detect,
  identify,
  detections,
  cattle,
  registerCattle,
  farms,
  planner,
  reports,
  admin,
  profile,
  settings,
}

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final AppSection current;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.current,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F3),
      appBar: AppBar(
        backgroundColor: unzaGold,
        foregroundColor: unzaBlack,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: actions,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [unzaGold, unzaGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UNZA Cattle Tracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.profile?.displayName ??
                          session.session?.username ??
                          'Signed out',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.session == null
                          ? 'No active session'
                          : userRoleToApi(session.session!.role),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _DrawerTile(
                      current: current,
                      section: AppSection.dashboard,
                      icon: Icons.dashboard_outlined,
                      label: 'Dashboard',
                      builder: () => const DashboardPage(),
                    ),
                    _DrawerTile(
                      current: current,
                      section: AppSection.detect,
                      icon: Icons.camera_alt_outlined,
                      label: 'Detect Cattle',
                      builder: () => const CameraView(),
                    ),
                    _DrawerTile(
                      current: current,
                      section: AppSection.identify,
                      icon: Icons.search_rounded,
                      label: 'Identify Cattle',
                      builder: () => const IdentifyPage(),
                    ),
                    _DrawerTile(
                      current: current,
                      section: AppSection.detections,
                      icon: Icons.history,
                      label: 'Detection History',
                      builder: () => const DetectionHistoryPage(),
                    ),
                    _DrawerTile(
                      current: current,
                      section: AppSection.cattle,
                      icon: Icons.pets_outlined,
                      label: 'Cattle Registry',
                      builder: () => const CattleListPage(),
                    ),
                    _DrawerTile(
                      current: current,
                      section: AppSection.registerCattle,
                      icon: Icons.app_registration,
                      label: 'Register Cattle',
                      builder: () => const CattleRegistrationPage(),
                    ),
                    _DrawerTile(
                      current: current,
                      section: AppSection.farms,
                      icon: Icons.agriculture_outlined,
                      label: 'Farms',
                      builder: () => const FarmListPage(),
                    ),
                    _DrawerTile(
                      current: current,
                      section: AppSection.planner,
                      icon: Icons.event_note_outlined,
                      label: 'Planner',
                      builder: () => const PlannerPage(),
                    ),
                    _DrawerTile(
                      current: current,
                      section: AppSection.reports,
                      icon: Icons.bar_chart_outlined,
                      label: 'Reports',
                      builder: () => const ReportsPage(),
                    ),
                    if (session.session?.role == UserRole.admin)
                      _DrawerTile(
                        current: current,
                        section: AppSection.admin,
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Admin',
                        builder: () => const AdminPage(),
                      ),
                    _DrawerTile(
                      current: current,
                      section: AppSection.profile,
                      icon: Icons.person_outline,
                      label: 'Profile',
                      builder: () => const ProfilePage(),
                    ),
                    _DrawerTile(
                      current: current,
                      section: AppSection.settings,
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      builder: () => const SettingsPage(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final AppSection current;
  final AppSection section;
  final IconData icon;
  final String label;
  final Widget Function() builder;

  const _DrawerTile({
    required this.current,
    required this.section,
    required this.icon,
    required this.label,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final selected = current == section;
    return ListTile(
      selected: selected,
      selectedTileColor: unzaGreen.withOpacity(0.08),
      leading: Icon(icon, color: selected ? unzaGreen : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? unzaGreen : null,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        if (selected) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => builder()),
        );
      },
    );
  }
}

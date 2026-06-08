// settings_page.dart - MODIFIED FOR SIMULATED LOGOUT

import 'package:flutter/material.dart';
// REMOVED: import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart'; // Import your login page

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  // REMOVED: final FirebaseAuth _auth = FirebaseAuth.instance; 

  // New function for simulated logout
  Future<void> _performSimulatedLogout() async {
    // Simulate network delay for logout process
    await Future.delayed(const Duration(seconds: 1)); 

    // Navigate back to the LoginPage and clear the navigation stack
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully! (Simulated)"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.green.shade800,
        centerTitle: true,
        elevation: 2,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          const Text(
            "Account",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text("Profile"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // Navigate to Profile Page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile navigation not implemented")),
                );
              },
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.lock, color: Colors.orange),
              title: const Text("Change Password"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // Navigate to Change Password Page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Change Password not implemented")),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // App Preferences Section
          const Text(
            "App Preferences",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications, color: Colors.blue),
              title: const Text("Enable Notifications"),
              value: _notificationsEnabled,
              onChanged: (val) {
                setState(() {
                  _notificationsEnabled = val;
                });
              },
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode, color: Colors.deepPurple),
              title: const Text("Dark Mode"),
              value: _darkModeEnabled,
              onChanged: (val) {
                setState(() {
                  _darkModeEnabled = val;
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          // Support Section
          const Text(
            "Support",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.indigo),
              title: const Text("Help & Support"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // Navigate to Support Page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Help & Support not implemented")),
                );
              },
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.teal),
              title: const Text("About App"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // Navigate to About Page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("About App not implemented")),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Logout Button
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              
              // MODIFIED: Replaced Firebase sign out with simulated action
              await _performSimulatedLogout();
            },
          ),
        ],
      ),
    );
  }
}
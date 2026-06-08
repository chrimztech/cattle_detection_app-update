import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'detection/camera_view.dart';
import 'detection/detection_service.dart';
import 'cattle_registration_page.dart';
import 'settings_page.dart';

// UNZA color palette
const Color unzaGold = Color(0xFFFFB000);
const Color unzaGreen = Color(0xFF009739);
const Color unzaRed = Color(0xFFE30613);
const Color unzaBlack = Color(0xFF000000);

class DashboardPage extends StatelessWidget {
  final List<CameraDescription> cameras;
  final DetectionService detectionService;

  const DashboardPage({
    super.key,
    required this.cameras,
    required this.detectionService,
  });

  @override
  Widget build(BuildContext context) {

    // Removed the need for a 'user' object since Firebase Auth is gone.
    const String welcomeName = "UNZA PROJECT";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/logo.png', height: 50),
          ],
        ),
        centerTitle: true,
        backgroundColor: unzaGold,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome section - MODIFIED to use a static name
            Text(
              'WELCOME, $welcomeName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: unzaBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'UNZA AI Cattle Detector',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: unzaBlack,
              ),
            ),
            const SizedBox(height: 16),

            // Hero section with gradient
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [unzaGold, unzaGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/chatgpt_image.png',
                  fit: BoxFit.cover,
                  height: 260,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Feature grid
            SizedBox(
              height: 400,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Watermark logo
                    Center(
                      child: Opacity(
                        opacity: 0.15,
                        child: Image.asset(
                          'assets/logo.png',
                          height: 320,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Grid content
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.0,
                        children: [
                          _buildActionCard(
                            context,
                            color: unzaGreen,
                            icon: Icons.app_registration,
                            title: 'Register Cattle',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CattleRegistrationPage(),
                                ),
                              );
                            },
                          ),
                          _buildActionCard(
                            context,
                            color: unzaRed,
                            icon: Icons.camera_enhance,
                            title: 'Detect Cattle',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CameraView(
                                    cameras: cameras,
                                    detectionService: detectionService,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), unzaGold.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }  
}
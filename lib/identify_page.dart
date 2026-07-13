import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_scaffold.dart';
import 'cattle_detail_page.dart';
import 'session_controller.dart';

class IdentifyPage extends StatefulWidget {
  const IdentifyPage({super.key});

  @override
  State<IdentifyPage> createState() => _IdentifyPageState();
}

class _IdentifyPageState extends State<IdentifyPage> {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  bool _initialized = false;
  bool _identifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No cameras found on this device.');
        return;
      }
      _cameras = cameras;
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initialized = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Camera error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndIdentify() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _identifying) return;
    setState(() => _identifying = true);
    try {
      final file = await ctrl.takePicture();
      final bytes = await file.readAsBytes();
      final api = context.read<SessionController>().api;
      final result = await api.identifyCattle(bytes);
      if (!mounted) return;
      await _showResult(result, bytes);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Identify failed: ${e.message}'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _identifying = false);
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final current = _controller?.description;
    final next = _cameras.firstWhere((c) => c != current, orElse: () => _cameras.first);
    await _controller?.dispose();
    setState(() {
      _controller = null;
      _initialized = false;
    });
    final controller = CameraController(next, ResolutionPreset.high, enableAudio: false);
    await controller.initialize();
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _initialized = true;
    });
  }

  Future<void> _showResult(Map<String, dynamic> result, Uint8List imageBytes) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IdentifyResultSheet(result: result, imageBytes: imageBytes),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: unzaGold,
          foregroundColor: unzaBlack,
          title: const Text('Identify Cattle', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_outlined, size: 64, color: Colors.black38),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _initCamera();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Identify Cattle'),
        actions: [
          if (_cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_outlined),
              onPressed: _switchCamera,
              tooltip: 'Switch camera',
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),

          // viewfinder guide box
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: unzaGold.withOpacity(0.75), width: 2.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  // corner accents
                  for (final (top, left) in [
                    (true, true), (true, false), (false, true), (false, false)
                  ])
                    Positioned(
                      top: top ? -1 : null,
                      bottom: top ? null : -1,
                      left: left ? -1 : null,
                      right: left ? null : -1,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border(
                            top: top ? BorderSide(color: unzaGold, width: 4) : BorderSide.none,
                            bottom: top ? BorderSide.none : BorderSide(color: unzaGold, width: 4),
                            left: left ? BorderSide(color: unzaGold, width: 4) : BorderSide.none,
                            right: left ? BorderSide.none : BorderSide(color: unzaGold, width: 4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // identifying overlay
          if (_identifying)
            const ColoredBox(
              color: Color(0xAA000000),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: unzaGold),
                    SizedBox(height: 16),
                    Text(
                      'Identifying cattle…',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          // bottom controls
          Positioned(
            left: 0, right: 0, bottom: 40,
            child: Column(
              children: [
                Text(
                  'Frame the cattle tag or side profile\nthen tap to identify',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _identifying ? null : _captureAndIdentify,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _identifying ? Colors.white30 : unzaGold,
                      boxShadow: [
                        BoxShadow(
                          color: unzaGold.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: _identifying ? Colors.white54 : unzaBlack,
                      size: 34,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result bottom sheet ──────────────────────────────────────

class _IdentifyResultSheet extends StatelessWidget {
  final Map<String, dynamic> result;
  final Uint8List imageBytes;

  const _IdentifyResultSheet({required this.result, required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final status = result['status'] as String? ?? 'UNKNOWN_OR_UNCERTAIN';
    final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
    final tagNumber = result['tagNumber'] as String?;
    final breed = result['breed'] as String?;
    final gender = result['gender'] as String?;
    final colour = result['colour'] as String?;
    final farm = result['farm'] as String?;
    final matchedCattleId = result['matchedCattleId'] as String?;
    final topMatches = (result['topMatches'] as List<dynamic>?) ?? const [];

    final (statusColor, statusIcon, statusLabel, statusSub) = switch (status) {
      'MATCHED' => (
          unzaGreen,
          Icons.check_circle_rounded,
          'Match Found',
          '${(confidence * 100).toStringAsFixed(1)}% confidence',
        ),
      'REVIEW_REQUIRED' => (
          const Color(0xFFD48C10),
          Icons.help_rounded,
          'Review Required',
          'Possible match — human verification needed',
        ),
      _ => (
          Colors.red.shade700,
          Icons.cancel_rounded,
          'No Match',
          'This cattle is not in the registry',
        ),
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6F2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // drag handle
            Center(
              child: Container(
                width: 38, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.black15, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // captured thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                imageBytes,
                height: 140,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 14),

            // status banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                border: Border.all(color: statusColor.withOpacity(0.35)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusSub,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // matched cattle details
            if (tagNumber != null) ...[
              const SizedBox(height: 18),
              _sectionLabel('Matched Cattle'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _InfoRow('Tag Number', tagNumber, bold: true),
                    if (breed != null) _InfoRow('Breed', breed),
                    if (gender != null) _InfoRow('Gender', _capitalize(gender)),
                    if (colour != null) _InfoRow('Colour', colour),
                    if (farm != null) _InfoRow('Farm', farm),
                  ],
                ),
              ),
              if (matchedCattleId != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: unzaGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('View Full Profile'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CattleDetailPage(cattleId: matchedCattleId),
                      ));
                    },
                  ),
                ),
              ],
            ],

            // top matches
            if (topMatches.isNotEmpty) ...[
              const SizedBox(height: 22),
              _sectionLabel('Top Similarity Matches'),
              const SizedBox(height: 8),
              ...topMatches.take(5).indexed.map((entry) {
                final (index, m) = entry;
                final match = m as Map<String, dynamic>;
                final sim = (match['similarity'] as num?)?.toDouble() ?? 0.0;
                final tag = match['tagNumber'] as String? ?? '—';
                final pct = (sim * 100).toStringAsFixed(1);
                final isTop = index == 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isTop ? unzaGold.withOpacity(0.08) : Colors.white,
                    border: Border.all(
                      color: isTop ? unzaGold.withOpacity(0.4) : Colors.black12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isTop ? unzaGold : Colors.black08,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isTop ? unzaBlack : Colors.black45,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(tag, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isTop ? unzaGold.withOpacity(0.85) : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black45,
          letterSpacing: 0.5,
        ),
      );

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _InfoRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black45)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? unzaBlack : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app_scaffold.dart';
import '../cattle_registration_page.dart';
import '../models/app_models.dart';

class DetectionResultsPage extends StatelessWidget {
  final DetectionResponseData result;
  final Uint8List imageBytes;

  const DetectionResultsPage({
    super.key,
    required this.result,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final detections = result.detections;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Results'),
        backgroundColor: unzaGold,
        foregroundColor: unzaBlack,
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(imageBytes, fit: BoxFit.cover),
                if (result.imageUrl != null)
                  Image.network(
                    result.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.memory(imageBytes, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  detections.isEmpty
                      ? 'No cattle detected'
                      : '${detections.length} detection${detections.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.app_registration, size: 18),
                  label: const Text('Register'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CattleRegistrationPage(initialImages: [imageBytes]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: detections.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_outlined, size: 56, color: Colors.black26),
                        SizedBox(height: 12),
                        Text('No cattle detected in this image.'),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: detections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final d = detections[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: unzaGreen.withOpacity(0.1),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: unzaGreen,
                              ),
                            ),
                          ),
                          title: Text(
                            d.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            'Confidence: ${(d.confidence * 100).toStringAsFixed(1)}%',
                          ),
                          trailing: _ConfidenceBar(value: d.confidence),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double value;

  const _ConfidenceBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value >= 0.8
        ? unzaGreen
        : value >= 0.5
            ? unzaGold
            : unzaRed;
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_scaffold.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class DetectionHistoryPage extends StatefulWidget {
  const DetectionHistoryPage({super.key});

  @override
  State<DetectionHistoryPage> createState() => _DetectionHistoryPageState();
}

class _DetectionHistoryPageState extends State<DetectionHistoryPage> {
  late Future<DetectionHistoryPageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DetectionHistoryPageData> _load() {
    return context.read<SessionController>().api.listDetectionHistory(size: 40);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detection History',
      current: AppSection.detections,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<DetectionHistoryPageData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
            final history = snapshot.data?.content ?? const <DetectionHistoryItem>[];
            if (history.isEmpty) return const Center(child: Text('No detection history yet.'));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: history
                  .map(
                    (item) => Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  item.imageUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 180,
                                    color: Colors.black12,
                                    child: const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              '${item.detectionCount} detection${item.detectionCount == 1 ? '' : 's'}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.username} • ${DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt)}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: item.detections
                                  .map(
                                    (result) => Chip(
                                      label: Text(
                                        '${result.label} ${(result.confidence * 100).toStringAsFixed(0)}%',
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

// detection/results_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../cattle_registration_page.dart';
import 'yolo_parser.dart';
import '../api_service.dart'; // Use the CattleInfo model from here

class DetectionResultsPage extends StatefulWidget {
  final List<DetectionResult> results;
  final Uint8List imageBytes;

  const DetectionResultsPage({
    super.key,
    required this.results,
    required this.imageBytes,
  });

  @override
  State<DetectionResultsPage> createState() => _DetectionResultsPageState();
}

class _DetectionResultsPageState extends State<DetectionResultsPage> {
  late Future<List<CattleInfo?>> _cattleInfosFuture;

  @override
  void initState() {
    super.initState();
    _cattleInfosFuture = _fetchCattleInfos();
  }

  Future<List<CattleInfo?>> _fetchCattleInfos() async {
    List<CattleInfo?> infos = [];

    // Loop through each detection result
    for (var r in widget.results) {
      // r.label can be replaced with ear tag if using OCR later
      CattleInfo? info = await ApiService.getCattleInfo(r.label);
      infos.add(info);
    }

    return infos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detection Results')),
      body: Column(
        children: [
          Image.memory(widget.imageBytes, height: 250, fit: BoxFit.cover),
          Expanded(
            child: FutureBuilder<List<CattleInfo?>>(
              future: _cattleInfosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No detection results'));
                }

                final infos = snapshot.data!;
                return ListView.builder(
                  itemCount: widget.results.length,
                  itemBuilder: (_, index) {
                    final r = widget.results[index];
                    final info = infos[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: ListTile(
                        leading: const Icon(Icons.pets, size: 40),
                        title: Text(info?.name ?? r.label),
                        subtitle: info != null
                            ? Text(
                                'Breed: ${info.breed}\nAge: ${info.age}\nOwner: ${info.owner}',
                              )
                            : Text(
                                'Confidence: ${(r.confidence * 100).toStringAsFixed(2)}%\n'
                                'Box: (${r.x.toStringAsFixed(1)}, ${r.y.toStringAsFixed(1)}, '
                                '${r.width.toStringAsFixed(1)}, ${r.height.toStringAsFixed(1)})',
                              ),
                        trailing: info == null
                            ? ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CattleRegistrationPage(
                                        imagesBytesList: [widget.imageBytes],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Register'),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

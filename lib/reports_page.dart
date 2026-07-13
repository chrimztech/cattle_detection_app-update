import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_scaffold.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Future<AppStats> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<SessionController>().api.getStats();
  }

  Future<void> _refresh() async {
    setState(() => _future = context.read<SessionController>().api.getStats());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reports',
      current: AppSection.reports,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<AppStats>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
            final stats = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Metric(label: 'Cattle', value: '${stats.totalCattle}'),
                    _Metric(label: 'Farms', value: '${stats.totalFarms}'),
                    _Metric(label: 'Health', value: '${stats.totalHealthRecords}'),
                    _Metric(label: 'Weight', value: '${stats.totalWeightRecords}'),
                    _Metric(label: 'Breeding', value: '${stats.totalBreedingRecords}'),
                    _Metric(label: 'Tasks', value: '${stats.totalPlannerTasks}'),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Breed distribution',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        ...stats.byBreed.map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.breed),
                            trailing: Text(
                              '${item.count}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gender split',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        ...stats.byGender.entries.map(
                          (entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(entry.key),
                            trailing: Text(
                              '${entry.value}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

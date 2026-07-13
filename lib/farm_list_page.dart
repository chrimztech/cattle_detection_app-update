import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_scaffold.dart';
import 'farm_detail_page.dart';
import 'farm_form_page.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class FarmListPage extends StatefulWidget {
  const FarmListPage({super.key});

  @override
  State<FarmListPage> createState() => _FarmListPageState();
}

class _FarmListPageState extends State<FarmListPage> {
  late Future<List<FarmRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<FarmRecord>> _load() {
    return context.read<SessionController>().api.listFarms();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Farms',
      current: AppSection.farms,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: unzaGreen,
        foregroundColor: Colors.white,
        onPressed: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const FarmFormPage()),
          );
          if (changed == true) _refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('New farm'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<FarmRecord>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            final farms = snapshot.data ?? const <FarmRecord>[];
            if (farms.isEmpty) {
              return const Center(child: Text('No farms found.'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: farms
                  .map(
                    (farm) => Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: unzaGold.withOpacity(0.16),
                          child: const Icon(Icons.agriculture_outlined, color: unzaBlack),
                        ),
                        title: Text(
                          farm.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${farm.ownerName ?? 'No owner'}\n${farm.address ?? 'No address'}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${farm.cattleCount}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: unzaGreen,
                              ),
                            ),
                            const Text('cattle'),
                          ],
                        ),
                        onTap: () async {
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => FarmDetailPage(farmId: farm.id)),
                          );
                          if (changed == true) _refresh();
                        },
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

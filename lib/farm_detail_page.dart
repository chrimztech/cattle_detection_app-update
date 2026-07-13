import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_scaffold.dart';
import 'cattle_detail_page.dart';
import 'farm_form_page.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class FarmDetailPage extends StatefulWidget {
  final String farmId;

  const FarmDetailPage({super.key, required this.farmId});

  @override
  State<FarmDetailPage> createState() => _FarmDetailPageState();
}

class _FarmDetailPageState extends State<FarmDetailPage> {
  late Future<_FarmBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FarmBundle> _load() async {
    final api = context.read<SessionController>().api;
    final farm = await api.getFarm(widget.farmId);
    final cattle = await api.listFarmCattle(widget.farmId);
    return _FarmBundle(farm: farm, cattle: cattle);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _deleteFarm(FarmRecord farm) async {
    try {
      await context.read<SessionController>().api.deleteFarm(farm.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Farm Details',
      current: AppSection.farms,
      body: FutureBuilder<_FarmBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final data = snapshot.data!;
          final farm = data.farm;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                                  farm.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(farm.address ?? 'No address recorded'),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final changed = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => FarmFormPage(existing: farm),
                                  ),
                                );
                                if (changed == true) _refresh();
                              } else if (value == 'delete') {
                                _deleteFarm(farm);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _FarmChip(label: 'Cattle', value: '${farm.cattleCount}'),
                          if (farm.farmSizeHectares != null)
                            _FarmChip(
                              label: 'Size',
                              value: '${farm.farmSizeHectares!.toStringAsFixed(0)} ha',
                            ),
                          _FarmChip(label: 'Active', value: farm.active ? 'Yes' : 'No'),
                        ],
                      ),
                      if (farm.ownerName != null && farm.ownerName!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Owner: ${farm.ownerName}'),
                      ],
                      if (farm.ownerPhone != null && farm.ownerPhone!.isNotEmpty)
                        Text('Phone: ${farm.ownerPhone}'),
                      if (farm.ownerEmail != null && farm.ownerEmail!.isNotEmpty)
                        Text('Email: ${farm.ownerEmail}'),
                      if (farm.notes != null && farm.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          farm.notes!,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Assigned cattle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ...data.cattle.map(
                (cattle) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: unzaGreen.withOpacity(0.12),
                      child: const Icon(Icons.pets_outlined, color: unzaGreen),
                    ),
                    title: Text(cattle.cattleId),
                    subtitle: Text('${cattle.breed} • ${cattle.owner}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CattleDetailPage(cattleId: cattle.id),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FarmBundle {
  final FarmRecord farm;
  final List<CattleRecord> cattle;

  const _FarmBundle({required this.farm, required this.cattle});
}

class _FarmChip extends StatelessWidget {
  final String label;
  final String value;

  const _FarmChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_scaffold.dart';
import 'breeding_records_page.dart';
import 'cattle_registration_page.dart';
import 'health_records_page.dart';
import 'models/app_models.dart';
import 'session_controller.dart';
import 'weight_records_page.dart';

class CattleDetailPage extends StatefulWidget {
  final String cattleId;

  const CattleDetailPage({super.key, required this.cattleId});

  @override
  State<CattleDetailPage> createState() => _CattleDetailPageState();
}

class _CattleDetailPageState extends State<CattleDetailPage> {
  late Future<_CattleDetailBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CattleDetailBundle> _load() async {
    final api = context.read<SessionController>().api;
    final cattle = await api.getCattle(widget.cattleId);
    final health = await api.listHealth(widget.cattleId);
    final weight = await api.listWeight(widget.cattleId);
    final breeding = await api.listBreeding(widget.cattleId);
    return _CattleDetailBundle(
      cattle: cattle,
      health: health,
      weight: weight,
      breeding: breeding,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _delete(CattleRecord cattle) async {
    try {
      await context.read<SessionController>().api.deleteCattle(cattle.id);
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
      title: 'Cattle Details',
      current: AppSection.cattle,
      body: FutureBuilder<_CattleDetailBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final data = snapshot.data!;
          final cattle = data.cattle;
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
                                  cattle.cattleId,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${cattle.breed} • ${cattle.owner}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final changed = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => CattleRegistrationPage(existing: cattle),
                                  ),
                                );
                                if (changed == true) _refresh();
                              } else if (value == 'delete') {
                                _delete(cattle);
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
                          _InfoChip(label: 'Gender', value: cattle.gender == CattleGender.male ? 'Male' : 'Female'),
                          _InfoChip(label: 'Weight', value: '${cattle.weightKg.toStringAsFixed(1)} kg'),
                          _InfoChip(label: 'Horn Status', value: hornStatusToApi(cattle.hornStatus)),
                          _InfoChip(label: 'DOB', value: DateFormat('dd MMM yyyy').format(cattle.dateOfBirth)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Color: ${cattle.color}'),
                      const SizedBox(height: 6),
                      Text('Farm: ${cattle.farmName ?? cattle.farmLocation ?? 'Not assigned'}'),
                      if (cattle.notes != null && cattle.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          cattle.notes!,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (cattle.images.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Images',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: cattle.images.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  cattle.images[index].url,
                                  width: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 120,
                                    color: Colors.black12,
                                    child: const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _AiStatusCard(cattle: cattle, onRefresh: _refresh),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'Health records',
                subtitle: '${data.health.length} entries logged for this animal.',
                icon: Icons.health_and_safety_outlined,
                onTap: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => HealthRecordsPage(cattle: cattle)),
                  );
                  if (changed == true) _refresh();
                  _refresh();
                },
              ),
              _ActionCard(
                title: 'Weight records',
                subtitle: '${data.weight.length} weight entries recorded.',
                icon: Icons.monitor_weight_outlined,
                onTap: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => WeightRecordsPage(cattle: cattle)),
                  );
                  if (changed == true) _refresh();
                  _refresh();
                },
              ),
              _ActionCard(
                title: 'Breeding records',
                subtitle: '${data.breeding.length} breeding entries recorded.',
                icon: Icons.favorite_border,
                onTap: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => BreedingRecordsPage(cattle: cattle)),
                  );
                  if (changed == true) _refresh();
                  _refresh();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CattleDetailBundle {
  final CattleRecord cattle;
  final List<HealthRecord> health;
  final List<WeightRecord> weight;
  final List<BreedingRecord> breeding;

  const _CattleDetailBundle({
    required this.cattle,
    required this.health,
    required this.weight,
    required this.breeding,
  });
}

class _AiStatusCard extends StatefulWidget {
  final CattleRecord cattle;
  final VoidCallback onRefresh;

  const _AiStatusCard({required this.cattle, required this.onRefresh});

  @override
  State<_AiStatusCard> createState() => _AiStatusCardState();
}

class _AiStatusCardState extends State<_AiStatusCard> {
  AiStatusInfo? _statusInfo;
  bool _loading = false;
  bool _activating = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final api = context.read<SessionController>().api;
      final info = await api.getAiStatus(widget.cattle.id);
      if (mounted) setState(() { _statusInfo = info; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _activate() async {
    setState(() => _activating = true);
    try {
      final api = context.read<SessionController>().api;
      final result = await api.activateAi(widget.cattle.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI activated — ${result.embeddingsCreated} embeddings created'),
          backgroundColor: unzaGreen,
        ),
      );
      _loadStatus();
      widget.onRefresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo?.aiStatus ?? widget.cattle.aiStatus;
    final embeddingCount = _statusInfo?.embeddingCount ?? 0;
    final imageCount = _statusInfo?.imageCount ?? widget.cattle.images.length;
    final canActivate = status == AiStatus.processingImages || status == AiStatus.aiReviewRequired;

    final (label, description, color, icon) = switch (status) {
      AiStatus.aiActive => (
          'AI Active',
          'Visual embeddings ready. This animal can be identified by camera.',
          Colors.green,
          Icons.check_circle_outline,
        ),
      AiStatus.processingImages => (
          'Processing',
          'Images uploaded. Tap Activate AI to build visual embeddings.',
          Colors.amber,
          Icons.hourglass_top_outlined,
        ),
      AiStatus.aiReviewRequired => (
          'Review Required',
          'AI active with limited images. Identification confidence may be lower.',
          Colors.orange,
          Icons.warning_amber_outlined,
        ),
      AiStatus.aiDisabled => (
          'AI Disabled',
          'AI identification is disabled for this animal.',
          Colors.red,
          Icons.block_outlined,
        ),
      _ => (
          'Pending Images',
          'Upload at least 3 photos to enable AI identification.',
          Colors.grey,
          Icons.image_outlined,
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'AI Recognition',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (canActivate)
                  FilledButton.icon(
                    onPressed: _activating ? null : _activate,
                    style: FilledButton.styleFrom(backgroundColor: unzaGreen),
                    icon: _activating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.bolt, size: 18),
                    label: Text(_activating ? 'Activating…' : 'Activate AI'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  border: Border.all(color: color.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                          const SizedBox(height: 2),
                          Text(description, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '$embeddingCount embeddings  ·  $imageCount images',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: unzaGreen.withOpacity(0.12),
          child: Icon(icon, color: unzaGreen),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

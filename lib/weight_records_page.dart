import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_scaffold.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class WeightRecordsPage extends StatefulWidget {
  final CattleRecord cattle;

  const WeightRecordsPage({super.key, required this.cattle});

  @override
  State<WeightRecordsPage> createState() => _WeightRecordsPageState();
}

class _WeightRecordsPageState extends State<WeightRecordsPage> {
  late Future<List<WeightRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<WeightRecord>> _load() {
    return context.read<SessionController>().api.listWeight(widget.cattle.id);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _showAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    var recordedOn = DateTime.now();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Add weight record'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Recorded on'),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(recordedOn)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: recordedOn,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => recordedOn = picked);
                          }
                        },
                      ),
                      TextFormField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Weight (kg)'),
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          return parsed == null || parsed <= 0 ? 'Enter a valid weight' : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await context.read<SessionController>().api.createWeight(
                            widget.cattle.id,
                            {
                              'weightKg': double.parse(weightController.text.trim()),
                              'recordedOn': DateFormat('yyyy-MM-dd').format(recordedOn),
                              'notes': notesController.text.trim(),
                            },
                          );
                      if (!mounted) return;
                      Navigator.of(dialogContext).pop(true);
                    } on ApiException catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    weightController.dispose();
    notesController.dispose();
    if (created == true) _refresh();
  }

  Future<void> _deleteRecord(WeightRecord record) async {
    try {
      await context.read<SessionController>().api.deleteWeight(widget.cattle.id, record.id);
      _refresh();
    } on ApiException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Weight Records',
      current: AppSection.cattle,
      actions: [
        IconButton(onPressed: _showAddDialog, icon: const Icon(Icons.add)),
      ],
      body: FutureBuilder<List<WeightRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final records = snapshot.data ?? const <WeightRecord>[];
          if (records.isEmpty) return const Center(child: Text('No weight records yet.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: records
                .map(
                  (record) => Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text('${record.weightKg.toStringAsFixed(1)} kg'),
                      subtitle: Text(
                        '${DateFormat('dd MMM yyyy').format(record.recordedOn)}'
                        '${record.notes != null && record.notes!.isNotEmpty ? '\n${record.notes}' : ''}',
                      ),
                      isThreeLine: record.notes != null && record.notes!.isNotEmpty,
                      trailing: IconButton(
                        onPressed: () => _deleteRecord(record),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_scaffold.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class HealthRecordsPage extends StatefulWidget {
  final CattleRecord cattle;

  const HealthRecordsPage({super.key, required this.cattle});

  @override
  State<HealthRecordsPage> createState() => _HealthRecordsPageState();
}

class _HealthRecordsPageState extends State<HealthRecordsPage> {
  late Future<List<HealthRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<HealthRecord>> _load() {
    return context.read<SessionController>().api.listHealth(widget.cattle.id);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    var date = DateTime.now();
    var type = RecordType.checkup;
    final descriptionController = TextEditingController();
    final veterinarianController = TextEditingController();
    final notesController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Add health record'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date'),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(date)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => date = picked);
                          }
                        },
                      ),
                      DropdownButtonFormField<RecordType>(
                        value: type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: RecordType.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(recordTypeToApi(item)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialogState(() => type = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: veterinarianController,
                        decoration: const InputDecoration(labelText: 'Veterinarian'),
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
                      await context.read<SessionController>().api.createHealth(
                            widget.cattle.id,
                            {
                              'date': DateFormat('yyyy-MM-dd').format(date),
                              'type': recordTypeToApi(type),
                              'description': descriptionController.text.trim(),
                              'veterinarian': veterinarianController.text.trim(),
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
    descriptionController.dispose();
    veterinarianController.dispose();
    notesController.dispose();
    if (created == true) _refresh();
  }

  Future<void> _deleteRecord(HealthRecord record) async {
    try {
      await context.read<SessionController>().api.deleteHealth(widget.cattle.id, record.id);
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
      title: 'Health Log',
      current: AppSection.cattle,
      actions: [
        IconButton(onPressed: _showCreateDialog, icon: const Icon(Icons.add)),
      ],
      body: FutureBuilder<List<HealthRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final records = snapshot.data ?? const <HealthRecord>[];
          if (records.isEmpty) {
            return const Center(child: Text('No health records yet.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: records
                .map(
                  (record) => Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(record.description),
                      subtitle: Text(
                        '${recordTypeToApi(record.type)} • ${DateFormat('dd MMM yyyy').format(record.date)}'
                        '${record.veterinarian != null && record.veterinarian!.isNotEmpty ? '\n${record.veterinarian}' : ''}',
                      ),
                      isThreeLine: record.veterinarian != null && record.veterinarian!.isNotEmpty,
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

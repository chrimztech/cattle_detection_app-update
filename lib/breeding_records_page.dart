import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_scaffold.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class BreedingRecordsPage extends StatefulWidget {
  final CattleRecord cattle;

  const BreedingRecordsPage({super.key, required this.cattle});

  @override
  State<BreedingRecordsPage> createState() => _BreedingRecordsPageState();
}

class _BreedingRecordsPageState extends State<BreedingRecordsPage> {
  late Future<List<BreedingRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<BreedingRecord>> _load() {
    return context.read<SessionController>().api.listBreeding(widget.cattle.id);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _showEditDialog([BreedingRecord? existing]) async {
    final formKey = GlobalKey<FormState>();
    var breedingDate = existing?.breedingDate ?? DateTime.now();
    var expectedCalving = existing?.expectedCalvingDate;
    var actualCalving = existing?.actualCalvingDate;
    var method = existing?.method ?? BreedingMethod.natural;
    var outcome = existing?.outcome ?? BreedingOutcome.pending;
    final sireIdController = TextEditingController(text: existing?.sireId ?? '');
    final sireBreedController = TextEditingController(text: existing?.sireBreed ?? '');
    final offspringCountController =
        TextEditingController(text: existing?.offspringCount?.toString() ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickDate({
              required DateTime initial,
              required void Function(DateTime) assign,
            }) async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: initial,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 500)),
              );
              if (picked != null) {
                setDialogState(() => assign(picked));
              }
            }

            return AlertDialog(
              title: Text(existing == null ? 'Add breeding record' : 'Edit breeding record'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Breeding date'),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(breedingDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => pickDate(
                          initial: breedingDate,
                          assign: (picked) => breedingDate = picked,
                        ),
                      ),
                      DropdownButtonFormField<BreedingMethod>(
                        value: method,
                        decoration: const InputDecoration(labelText: 'Method'),
                        items: BreedingMethod.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(breedingMethodToApi(item)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialogState(() => method = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<BreedingOutcome>(
                        value: outcome,
                        decoration: const InputDecoration(labelText: 'Outcome'),
                        items: BreedingOutcome.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(breedingOutcomeToApi(item)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialogState(() => outcome = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Expected calving'),
                        subtitle: Text(
                          expectedCalving == null
                              ? 'Not set'
                              : DateFormat('dd MMM yyyy').format(expectedCalving!),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => pickDate(
                          initial: expectedCalving ?? breedingDate,
                          assign: (picked) => expectedCalving = picked,
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Actual calving'),
                        subtitle: Text(
                          actualCalving == null
                              ? 'Not set'
                              : DateFormat('dd MMM yyyy').format(actualCalving!),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => pickDate(
                          initial: actualCalving ?? breedingDate,
                          assign: (picked) => actualCalving = picked,
                        ),
                      ),
                      TextFormField(
                        controller: sireIdController,
                        decoration: const InputDecoration(labelText: 'Sire ID'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: sireBreedController,
                        decoration: const InputDecoration(labelText: 'Sire breed'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: offspringCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Offspring count'),
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
                    final payload = {
                      'breedingDate': DateFormat('yyyy-MM-dd').format(breedingDate),
                      'method': breedingMethodToApi(method),
                      'expectedCalvingDate': expectedCalving == null
                          ? null
                          : DateFormat('yyyy-MM-dd').format(expectedCalving!),
                      'actualCalvingDate': actualCalving == null
                          ? null
                          : DateFormat('yyyy-MM-dd').format(actualCalving!),
                      'sireId': sireIdController.text.trim(),
                      'sireBreed': sireBreedController.text.trim(),
                      'offspringCount': int.tryParse(offspringCountController.text.trim()),
                      'outcome': breedingOutcomeToApi(outcome),
                      'notes': notesController.text.trim(),
                    };
                    try {
                      final api = context.read<SessionController>().api;
                      if (existing == null) {
                        await api.createBreeding(widget.cattle.id, payload);
                      } else {
                        await api.updateBreeding(widget.cattle.id, existing.id, payload);
                      }
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
    sireIdController.dispose();
    sireBreedController.dispose();
    offspringCountController.dispose();
    notesController.dispose();
    if (changed == true) _refresh();
  }

  Future<void> _deleteRecord(BreedingRecord record) async {
    try {
      await context.read<SessionController>().api.deleteBreeding(widget.cattle.id, record.id);
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
      title: 'Breeding Records',
      current: AppSection.cattle,
      actions: [
        IconButton(onPressed: () => _showEditDialog(), icon: const Icon(Icons.add)),
      ],
      body: FutureBuilder<List<BreedingRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final records = snapshot.data ?? const <BreedingRecord>[];
          if (records.isEmpty) return const Center(child: Text('No breeding records yet.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: records
                .map(
                  (record) => Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        '${DateFormat('dd MMM yyyy').format(record.breedingDate)} • ${breedingOutcomeToApi(record.outcome)}',
                      ),
                      subtitle: Text(
                        '${breedingMethodToApi(record.method)}'
                        '${record.expectedCalvingDate != null ? '\nExpected: ${DateFormat('dd MMM yyyy').format(record.expectedCalvingDate!)}' : ''}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditDialog(record);
                          } else if (value == 'delete') {
                            _deleteRecord(record);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
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

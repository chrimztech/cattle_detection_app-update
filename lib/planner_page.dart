import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_scaffold.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  late Future<List<PlannerTask>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PlannerTask>> _load() {
    return context.read<SessionController>().api.listPlannerTasks();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final cattleLabelController = TextEditingController();
    var dueDate = DateTime.now().add(const Duration(days: 7));
    var priority = PlannerPriority.medium;
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Create planner task'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Due date'),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(dueDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: dueDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (picked != null) {
                            setDialogState(() => dueDate = picked);
                          }
                        },
                      ),
                      DropdownButtonFormField<PlannerPriority>(
                        value: priority,
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: PlannerPriority.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(plannerPriorityToApi(item)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialogState(() => priority = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cattleLabelController,
                        decoration: const InputDecoration(labelText: 'Linked cattle label'),
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
                      await context.read<SessionController>().api.createPlannerTask({
                            'title': titleController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
                            'priority': plannerPriorityToApi(priority),
                            'cattleLabel': cattleLabelController.text.trim(),
                            'cattleId': null,
                          });
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
    titleController.dispose();
    descriptionController.dispose();
    cattleLabelController.dispose();
    if (created == true) _refresh();
  }

  Future<void> _toggleStatus(PlannerTask task) async {
    try {
      await context.read<SessionController>().api.setPlannerTaskStatus(
            task.id,
            task.status == PlannerStatus.done ? PlannerStatus.open : PlannerStatus.done,
          );
      _refresh();
    } on ApiException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteTask(PlannerTask task) async {
    try {
      await context.read<SessionController>().api.deletePlannerTask(task.id);
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
      title: 'Planner',
      current: AppSection.planner,
      actions: [
        IconButton(onPressed: _showCreateDialog, icon: const Icon(Icons.add)),
      ],
      body: FutureBuilder<List<PlannerTask>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final tasks = snapshot.data ?? const <PlannerTask>[];
          if (tasks.isEmpty) return const Center(child: Text('No planner tasks yet.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: tasks
                .map(
                  (task) => Card(
                    child: CheckboxListTile(
                      value: task.status == PlannerStatus.done,
                      onChanged: (_) => _toggleStatus(task),
                      title: Text(task.title),
                      subtitle: Text(
                        '${DateFormat('dd MMM yyyy').format(task.dueDate)} • ${plannerPriorityToApi(task.priority)}'
                        '${task.cattleLabel != null && task.cattleLabel!.isNotEmpty ? '\n${task.cattleLabel}' : ''}',
                      ),
                      secondary: IconButton(
                        onPressed: () => _deleteTask(task),
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

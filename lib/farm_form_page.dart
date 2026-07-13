import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_scaffold.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class FarmFormPage extends StatefulWidget {
  final FarmRecord? existing;

  const FarmFormPage({super.key, this.existing});

  @override
  State<FarmFormPage> createState() => _FarmFormPageState();
}

class _FarmFormPageState extends State<FarmFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _sizeController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final farm = widget.existing;
    if (farm != null) {
      _nameController.text = farm.name;
      _ownerNameController.text = farm.ownerName ?? '';
      _ownerPhoneController.text = farm.ownerPhone ?? '';
      _ownerEmailController.text = farm.ownerEmail ?? '';
      _addressController.text = farm.address ?? '';
      _latitudeController.text = farm.latitude?.toString() ?? '';
      _longitudeController.text = farm.longitude?.toString() ?? '';
      _sizeController.text = farm.farmSizeHectares?.toString() ?? '';
      _notesController.text = farm.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _sizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = {
      'name': _nameController.text.trim(),
      'ownerName': _ownerNameController.text.trim(),
      'ownerPhone': _ownerPhoneController.text.trim(),
      'ownerEmail': _ownerEmailController.text.trim(),
      'address': _addressController.text.trim(),
      'latitude': double.tryParse(_latitudeController.text.trim()),
      'longitude': double.tryParse(_longitudeController.text.trim()),
      'farmSizeHectares': double.tryParse(_sizeController.text.trim()),
      'notes': _notesController.text.trim(),
    };
    try {
      final api = context.read<SessionController>().api;
      if (_editing) {
        await api.updateFarm(widget.existing!.id, payload);
      } else {
        await api.createFarm(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _editing ? 'Edit Farm' : 'Create Farm',
      current: AppSection.farms,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Farm name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Farm name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(labelText: 'Owner name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ownerPhoneController,
                      decoration: const InputDecoration(labelText: 'Owner phone'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ownerEmailController,
                      decoration: const InputDecoration(labelText: 'Owner email'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Latitude'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Longitude'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sizeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Farm size (ha)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_editing ? 'Save farm' : 'Create farm'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

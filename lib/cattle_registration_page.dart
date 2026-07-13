import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_scaffold.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class CattleRegistrationPage extends StatefulWidget {
  final CattleRecord? existing;
  final List<Uint8List>? initialImages;

  const CattleRegistrationPage({
    super.key,
    this.existing,
    this.initialImages,
  });

  @override
  State<CattleRegistrationPage> createState() => _CattleRegistrationPageState();
}

class _CattleRegistrationPageState extends State<CattleRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _ownerController = TextEditingController();
  final _cattleIdController = TextEditingController();
  final _colorController = TextEditingController();
  final _weightController = TextEditingController();
  final _breedController = TextEditingController();
  final _farmLocationController = TextEditingController();
  final _notesController = TextEditingController();

  final _picker = ImagePicker();

  DateTime? _dateOfBirth;
  CattleGender _gender = CattleGender.female;
  HornStatus _hornStatus = HornStatus.horned;
  String? _selectedFarmId;
  bool _saving = false;
  List<Uint8List> _selectedImages = [];
  late Future<List<FarmRecord>> _farmsFuture;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _ownerController.text = existing.owner;
      _cattleIdController.text = existing.cattleId;
      _colorController.text = existing.color;
      _weightController.text = existing.weightKg.toStringAsFixed(0);
      _breedController.text = existing.breed;
      _farmLocationController.text = existing.farmLocation ?? '';
      _notesController.text = existing.notes ?? '';
      _dateOfBirth = existing.dateOfBirth;
      _gender = existing.gender;
      _hornStatus = existing.hornStatus;
      _selectedFarmId = existing.farmId;
    } else {
      _cattleIdController.text = 'CATTLE-${DateTime.now().millisecondsSinceEpoch}';
      _dateOfBirth = DateTime.now().subtract(const Duration(days: 365));
    }
    _selectedImages = List.of(widget.initialImages ?? const []);
    _farmsFuture = context.read<SessionController>().api.listFarms();
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _cattleIdController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    _breedController.dispose();
    _farmLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _selectedImages.add(bytes));
  }

  Future<void> _pickMultiple() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    final bytes = await Future.wait(picked.map((file) => file.readAsBytes()));
    setState(() => _selectedImages.addAll(bytes));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = {
        'cattleId': _cattleIdController.text.trim(),
        'owner': _ownerController.text.trim(),
        'dateOfBirth': DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
        'gender': cattleGenderToApi(_gender),
        'color': _colorController.text.trim(),
        'weightKg': double.parse(_weightController.text.trim()),
        'breed': _breedController.text.trim(),
        'hornStatus': hornStatusToApi(_hornStatus),
        'farmLocation': _farmLocationController.text.trim(),
        'notes': _notesController.text.trim(),
        'farmId': _selectedFarmId,
      };
      final api = context.read<SessionController>().api;
      final cattle = _editing
          ? await api.updateCattle(widget.existing!.id, payload)
          : await api.createCattle(payload);
      if (_selectedImages.isNotEmpty) {
        await api.uploadCattleImages(cattle.id, _selectedImages);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editing ? 'Cattle updated' : 'Cattle registered'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Unable to save cattle: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _editing ? 'Edit Cattle' : 'Register Cattle',
      current: AppSection.registerCattle,
      body: FutureBuilder<List<FarmRecord>>(
        future: _farmsFuture,
        builder: (context, snapshot) {
          final farms = snapshot.data ?? const <FarmRecord>[];
          return ListView(
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
                        const Text(
                          'Animal details',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cattleIdController,
                          decoration: const InputDecoration(labelText: 'Cattle ID'),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'Cattle ID is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ownerController,
                          decoration: const InputDecoration(labelText: 'Owner'),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'Owner is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date of birth'),
                            child: Text(
                              _dateOfBirth == null
                                  ? 'Select a date'
                                  : DateFormat('dd MMM yyyy').format(_dateOfBirth!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<CattleGender>(
                          value: _gender,
                          decoration: const InputDecoration(labelText: 'Gender'),
                          items: CattleGender.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value == CattleGender.male ? 'Male' : 'Female'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _gender = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _colorController,
                          decoration: const InputDecoration(labelText: 'Color'),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'Color is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Weight (kg)'),
                          validator: (value) {
                            final parsed = double.tryParse(value ?? '');
                            return parsed == null || parsed <= 0
                                ? 'Enter a valid weight'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _breedController,
                          decoration: const InputDecoration(labelText: 'Breed'),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'Breed is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<HornStatus>(
                          value: _hornStatus,
                          decoration: const InputDecoration(labelText: 'Horn status'),
                          items: HornStatus.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value == HornStatus.horned ? 'Horned' : 'Polled'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _hornStatus = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          value: _selectedFarmId,
                          decoration: const InputDecoration(labelText: 'Farm'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No farm selected'),
                            ),
                            ...farms.map(
                              (farm) => DropdownMenuItem<String?>(
                                value: farm.id,
                                child: Text(farm.name),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _selectedFarmId = value),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _farmLocationController,
                          decoration: const InputDecoration(labelText: 'Farm location'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Notes'),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _saving ? null : () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Camera'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _saving ? null : _pickMultiple,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Gallery'),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 96,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.memory(
                                        _selectedImages[index],
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: _saving
                                            ? null
                                            : () {
                                                setState(() {
                                                  _selectedImages.removeAt(index);
                                                });
                                              },
                                        child: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.black54,
                                          child: Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
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
                              : Text(_editing ? 'Save changes' : 'Register cattle'),
                        ),
                      ],
                    ),
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

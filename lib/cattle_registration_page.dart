import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
// Firebase imports removed to ensure clean separation

/// Data model for cattle
class Cattle {
  final String owner;
  final String id;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? color;
  final double? weight;
  final String? breed;
  final String? hornStatus;
  final List<Uint8List> images;

  Cattle({
    required this.owner,
    required this.id,
    this.dateOfBirth,
    this.gender,
    this.color,
    this.weight,
    this.breed,
    this.hornStatus,
    required this.images,
  });
}

class CattleRegistrationPage extends StatefulWidget {
  final List<Uint8List>? imagesBytesList;

  const CattleRegistrationPage({super.key, this.imagesBytesList});

  @override
  State<CattleRegistrationPage> createState() =>
      _CattleRegistrationPageState();
}

class _CattleRegistrationPageState extends State<CattleRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();

  DateTime? _dob;
  String? _gender;
  String? _hornStatus;
  String? _selectedBreed;

  final ImagePicker _picker = ImagePicker();
  late List<Uint8List> _images;

  final List<String> _predefinedBreeds = [
    'Brahman',
    'Hereford',
    'Angus',
    'Charolais',
    'Holstein',
    'Jersey',
    'Simmental',
    'Other'
  ];

  final List<String> _genders = ['Male', 'Female'];
  final List<String> _hornStatuses = ['Horned', 'Polled'];

  double _uploadProgress = 0.0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _images = widget.imagesBytesList ?? [];
    _generateCattleID();
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _idController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  /// Auto-generate a unique cattle ID
  void _generateCattleID() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = Random().nextInt(999);
    _idController.text = 'CATTLE-$timestamp-$randomNum';
  }

  /// Pick image
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      final compressed = await _compressImage(bytes);
      setState(() {
        _images.add(compressed);
      });
    }
  }

  /// Compress image to reduce size before upload
  Future<Uint8List> _compressImage(Uint8List data, {int quality = 70}) async {
    final img.Image? image = img.decodeImage(data);
    if (image == null) return data;
    final img.Image resized = img.copyResize(image, width: 1024);
    final compressed = img.encodeJpg(resized, quality: quality);
    return Uint8List.fromList(compressed);
  }

  /// Date picker
  Future<void> _pickDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  /// Reset form
  void _resetForm() {
    _formKey.currentState?.reset();
    _ownerController.clear();
    _colorController.clear();
    _weightController.clear();
    _images.clear();
    _breedController.clear();
    _generateCattleID();
    setState(() {
      _dob = null;
      _gender = null;
      _hornStatus = null;
      _selectedBreed = null;
      _uploadProgress = 0.0;
      _isUploading = false;
    });
  }

  // --- REMOVED FIREBASE STORAGE UPLOAD FUNCTION ---
  // The function _uploadImages has been removed.

  /// SIMULATED SAVE FUNCTION (Replaces _saveCattleToFirestore and _uploadImages)
  Future<void> _saveCattleDataLocally(Cattle cattle) async {
    setState(() {
      _isUploading = true;
    });

    // Simulate image processing and "upload" time
    // This is where you would integrate a new API or local database.
    await Future.delayed(const Duration(seconds: 2));

    final docData = {
      'owner': cattle.owner,
      'id': cattle.id,
      'dateOfBirth': cattle.dateOfBirth?.toIso8601String(),
      'gender': cattle.gender,
      'color': cattle.color,
      'weight': cattle.weight,
      'breed': cattle.breed,
      'hornStatus': cattle.hornStatus,
      'image_count': cattle.images.length,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    // Log the data to the console instead of saving to Firestore
    print('Cattle Data Registered (Local Simulation):');
    docData.forEach((key, value) => print('$key: $value'));
    
    // Simulate successful save completion
    setState(() {
      _isUploading = false;
      _uploadProgress = 1.0;
    });
  }

  // --- REMOVED FIREBASE FIRESTORE SAVE FUNCTION ---
  // The function _saveCattleToFirestore has been removed.

  /// Submit form (Modified to call the local simulation)
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please add at least one cattle image"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final String finalBreed =
          _selectedBreed == 'Other' ? _breedController.text : _selectedBreed!;

      final cattleData = Cattle(
        owner: _ownerController.text,
        id: _idController.text,
        dateOfBirth: _dob,
        gender: _gender,
        color: _colorController.text,
        weight: double.tryParse(_weightController.text),
        breed: finalBreed,
        hornStatus: _hornStatus,
        images: _images,
      );

      try {
        // Call the simulated save function
        await _saveCattleDataLocally(cattleData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cattle registered successfully! (Local Save)"),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving cattle: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Section header
  Widget _buildSectionHeader(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.brown.shade700),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
          ),
        ],
      ),
    );
  }

  /// Text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.brown.shade600),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: validator,
    );
  }

  /// Dropdown
  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    IconData? icon,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(e.toString()),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: Colors.brown.shade600) : null,
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: validator,
    );
  }

  /// Image preview
  Widget _buildImagePreview() {
    if (_images.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "No images yet. Add one below.",
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _images[index],
                width: 130,
                height: 130,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _images.removeAt(index)),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(5),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Cattle Registration 🐄"),
        centerTitle: true,
        elevation: 3,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.brown.shade800, Colors.brown.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionHeader("Cattle Information", Icons.info),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _ownerController,
                        label: "Owner Name",
                        icon: Icons.person,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Enter owner name" : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _idController,
                        label: "Cattle ID",
                        icon: Icons.confirmation_number,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Cattle ID required" : null,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown<String>(
                        label: "Gender",
                        value: _gender,
                        items: _genders,
                        onChanged: (v) => setState(() => _gender = v),
                        icon: Icons.male,
                        validator: (v) =>
                            v == null ? "Select gender" : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _colorController,
                        label: "Color",
                        icon: Icons.palette,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _weightController,
                        label: "Weight (kg)",
                        icon: Icons.monitor_weight,
                        type: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown<String>(
                        label: "Horn Status",
                        value: _hornStatus,
                        items: _hornStatuses,
                        onChanged: (v) => setState(() => _hornStatus = v),
                        icon: Icons.adjust,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown<String>(
                        label: "Breed",
                        value: _selectedBreed,
                        items: _predefinedBreeds,
                        onChanged: (v) => setState(() => _selectedBreed = v),
                        icon: Icons.grass,
                      ),
                      if (_selectedBreed == 'Other')
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: _buildTextField(
                              controller: _breedController,
                              label: "Specify Breed",
                              icon: Icons.edit),
                        ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickDateOfBirth,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade400),
                            color: Colors.white,
                          ),
                          child: Text(
                            _dob == null
                                ? "Select Date of Birth"
                                : DateFormat.yMMMd().format(_dob!),
                            style: TextStyle(
                              color: _dob == null
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildSectionHeader("Cattle Images", Icons.image),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      _buildImagePreview(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Camera"),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text("Gallery"),
                          ),
                        ],
                      ),
                      if (_isUploading)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: Colors.grey.shade300,
                            color: Colors.brown.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Colors.brown.shade700,
                ),
                child: Text(
                  _isUploading ? "Uploading..." : "Register Cattle",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
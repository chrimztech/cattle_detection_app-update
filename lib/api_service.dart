// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ApiService {
  static const String baseUrl = 'https://your-backend.com/api'; // Replace with your backend URL

  /// Fetch cattle info by tag or label
  static Future<CattleInfo?> getCattleInfo(String tagOrLabel) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cattle?tag=$tagOrLabel'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null || data.isEmpty) return null;

        // Assuming your API returns a single object
        return CattleInfo(
          id: data['id'].toString(),
          name: data['name'] ?? 'Unknown',
          breed: data['breed'] ?? 'Unknown',
          age: data['age'] ?? 0,
          owner: data['owner'] ?? 'Unknown',
        );
      } else if (response.statusCode == 404) {
        return null; // Not found
      } else {
        throw Exception('Failed to fetch cattle info');
      }
    } catch (e) {
      print('ApiService.getCattleInfo error: $e');
      return null;
    }
  }

  /// Register a new cattle
  static Future<bool> registerCattle({
    required String name,
    required String breed,
    required int age,
    required String owner,
    required Uint8List imageBytes,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/cattle'));

      request.fields['name'] = name;
      request.fields['breed'] = breed;
      request.fields['age'] = age.toString();
      request.fields['owner'] = owner;

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'cattle_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final response = await request.send();

      if (response.statusCode == 201) {
        return true; // Successfully registered
      } else {
        print('Failed to register cattle. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('ApiService.registerCattle error: $e');
      return false;
    }
  }
}

/// Model class for CattleInfo
class CattleInfo {
  final String id;
  final String name;
  final String breed;
  final int age;
  final String owner;

  CattleInfo({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.owner,
  });
}

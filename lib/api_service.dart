import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models/app_models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? body;

  const ApiException(
    this.message, {
    this.statusCode,
    this.body,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;
  final String? token;

  const ApiService({
    required this.baseUrl,
    this.token,
  });

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool jsonBody = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (jsonBody) headers['Content-Type'] = 'application/json';
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _normalizedBaseUrl() {
    return baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  }

  String? _normalizeUrl(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return raw.startsWith('/')
        ? '${_normalizedBaseUrl()}$raw'
        : '${_normalizedBaseUrl()}/$raw';
  }

  dynamic _parseBody(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  String? _extractMessage(dynamic parsed) {
    if (parsed is! Map<String, dynamic>) return null;

    String? fromValue(dynamic value) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is Map) {
        final messages = value.values
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toSet()
            .toList();
        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
      return null;
    }

    return fromValue(parsed['message']) ??
        fromValue(parsed['details']) ??
        fromValue(parsed['error']);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = _uri(path, query);
    late http.Response response;

    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: _headers(jsonBody: false));
        break;
      case 'POST':
        response = await http.post(uri, headers: _headers(), body: jsonEncode(body));
        break;
      case 'PUT':
        response = await http.put(uri, headers: _headers(), body: jsonEncode(body));
        break;
      case 'PATCH':
        response = await http.patch(uri, headers: _headers(), body: jsonEncode(body));
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: _headers(jsonBody: false));
        break;
      default:
        throw const ApiException('Unsupported request method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseBody(response);
    }

    final parsed = _parseBody(response);
    throw ApiException(
      _extractMessage(parsed) ?? 'Request failed with status ${response.statusCode}',
      statusCode: response.statusCode,
      body: parsed,
    );
  }

  Future<List<ImageRef>> uploadCattleImages(
    String cattleId,
    List<Uint8List> images,
  ) async {
    if (images.isEmpty) return const [];
    final request = http.MultipartRequest('POST', _uri('/api/cattle/$cattleId/images'));
    request.headers.addAll(_headers(jsonBody: false));
    for (var i = 0; i < images.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          images[i],
          filename: 'cattle_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        ),
      );
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final parsed = _parseBody(response) as List<dynamic>? ?? const [];
      return parsed
          .map((item) => ImageRef.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    final parsed = _parseBody(response);
    throw ApiException(
      _extractMessage(parsed) ?? 'Image upload failed with status ${response.statusCode}',
      statusCode: response.statusCode,
      body: parsed,
    );
  }

  Future<DetectionResponseData> detectImage(Uint8List bytes) async {
    final request = http.MultipartRequest('POST', _uri('/api/detect'));
    request.headers.addAll(_headers(jsonBody: false));
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'detect_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final payload = Map<String, dynamic>.from(
        (_parseBody(response) as Map<String, dynamic>? ?? const <String, dynamic>{}),
      );
      payload['imageUrl'] = _normalizeUrl(payload['imageUrl']);
      return DetectionResponseData.fromJson(
        payload,
      );
    }
    final parsed = _parseBody(response);
    throw ApiException(
      _extractMessage(parsed) ?? 'Detection failed with status ${response.statusCode}',
      statusCode: response.statusCode,
      body: parsed,
    );
  }

  Future<UserSession> login(String username, String password) async {
    final parsed = await _request('POST', '/api/auth/login', body: {
      'username': username,
      'password': password,
    });
    return UserSession.fromJson(parsed as Map<String, dynamic>);
  }

  Future<UserSession> register(String username, String password) async {
    final parsed = await _request('POST', '/api/auth/register', body: {
      'username': username,
      'password': password,
    });
    return UserSession.fromJson(parsed as Map<String, dynamic>);
  }

  Future<UserProfile> getProfile() async {
    final parsed = await _request('GET', '/api/auth/me');
    return UserProfile.fromJson(parsed as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    String? displayName,
    String? email,
    String? phone,
  }) async {
    final parsed = await _request('PUT', '/api/auth/profile', body: {
      'displayName': displayName ?? '',
      'email': email ?? '',
      'phone': phone ?? '',
    });
    return UserProfile.fromJson(parsed as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _request('PUT', '/api/auth/password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<AppStats> getStats() async {
    final parsed = await _request('GET', '/api/stats');
    return AppStats.fromJson(parsed as Map<String, dynamic>);
  }

  Future<CattlePageData> listCattle({
    String search = '',
    int page = 0,
    int size = 50,
    String breed = '',
    String gender = '',
    String location = '',
  }) async {
    final parsed = await _request('GET', '/api/cattle', query: {
      'search': search,
      'page': '$page',
      'size': '$size',
      'breed': breed,
      'gender': gender,
      'location': location,
    });
    return CattlePageData.fromJson(parsed as Map<String, dynamic>);
  }

  Future<CattleRecord> getCattle(String id) async {
    final parsed = await _request('GET', '/api/cattle/$id');
    return CattleRecord.fromJson(parsed as Map<String, dynamic>);
  }

  Future<CattleRecord> createCattle(Map<String, dynamic> payload) async {
    final parsed = await _request('POST', '/api/cattle', body: payload);
    return CattleRecord.fromJson(parsed as Map<String, dynamic>);
  }

  Future<CattleRecord> updateCattle(String id, Map<String, dynamic> payload) async {
    final parsed = await _request('PUT', '/api/cattle/$id', body: payload);
    return CattleRecord.fromJson(parsed as Map<String, dynamic>);
  }

  Future<void> deleteCattle(String id) async {
    await _request('DELETE', '/api/cattle/$id');
  }

  Future<List<FarmRecord>> listFarms() async {
    final parsed = await _request('GET', '/api/farms');
    return (parsed as List<dynamic>? ?? const [])
        .map((item) => FarmRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<FarmRecord> getFarm(String id) async {
    final parsed = await _request('GET', '/api/farms/$id');
    return FarmRecord.fromJson(parsed as Map<String, dynamic>);
  }

  Future<FarmRecord> createFarm(Map<String, dynamic> payload) async {
    final parsed = await _request('POST', '/api/farms', body: payload);
    return FarmRecord.fromJson(parsed as Map<String, dynamic>);
  }

  Future<FarmRecord> updateFarm(String id, Map<String, dynamic> payload) async {
    final parsed = await _request('PUT', '/api/farms/$id', body: payload);
    return FarmRecord.fromJson(parsed as Map<String, dynamic>);
  }

  Future<void> deleteFarm(String id) async {
    await _request('DELETE', '/api/farms/$id');
  }

  Future<List<CattleRecord>> listFarmCattle(String farmId) async {
    final parsed = await _request('GET', '/api/farms/$farmId/cattle');
    return (parsed as List<dynamic>? ?? const [])
        .map((item) => CattleRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminUser>> listUsers() async {
    final parsed = await _request('GET', '/api/admin/users');
    return (parsed as List<dynamic>? ?? const [])
        .map((item) => AdminUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminUser> setUserRole(String id, UserRole role) async {
    final parsed = await _request('PATCH', '/api/admin/users/$id/role', body: {
      'role': userRoleToApi(role),
    });
    return AdminUser.fromJson(parsed as Map<String, dynamic>);
  }

  Future<AdminUser> setUserEnabled(String id, bool enabled) async {
    final parsed = await _request('PATCH', '/api/admin/users/$id/enabled', body: {
      'enabled': enabled,
    });
    return AdminUser.fromJson(parsed as Map<String, dynamic>);
  }

  Future<void> deleteUser(String id) async {
    await _request('DELETE', '/api/admin/users/$id');
  }

  Future<List<PlannerTask>> listPlannerTasks() async {
    final parsed = await _request('GET', '/api/tasks');
    return (parsed as List<dynamic>? ?? const [])
        .map((item) => PlannerTask.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> countOpenPlannerTasks() async {
    final parsed = await _request('GET', '/api/tasks/count/open');
    return (parsed as Map<String, dynamic>)['count'] as int? ?? 0;
  }

  Future<PlannerTask> createPlannerTask(Map<String, dynamic> payload) async {
    final parsed = await _request('POST', '/api/tasks', body: payload);
    return PlannerTask.fromJson(parsed as Map<String, dynamic>);
  }

  Future<PlannerTask> setPlannerTaskStatus(String id, PlannerStatus status) async {
    final parsed = await _request('PATCH', '/api/tasks/$id/status', body: {
      'status': plannerStatusToApi(status),
    });
    return PlannerTask.fromJson(parsed as Map<String, dynamic>);
  }

  Future<void> deletePlannerTask(String id) async {
    await _request('DELETE', '/api/tasks/$id');
  }

  Future<List<HealthRecord>> listHealth(String cattleId) async {
    final parsed = await _request('GET', '/api/cattle/$cattleId/health');
    return (parsed as List<dynamic>? ?? const [])
        .map((item) => HealthRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<HealthRecord> createHealth(String cattleId, Map<String, dynamic> payload) async {
    final parsed = await _request('POST', '/api/cattle/$cattleId/health', body: payload);
    return HealthRecord.fromJson(parsed as Map<String, dynamic>);
  }

  Future<void> deleteHealth(String cattleId, String recordId) async {
    await _request('DELETE', '/api/cattle/$cattleId/health/$recordId');
  }

  Future<HealthPageData> listAllHealth({String type = '', int page = 0, int size = 100}) async {
    final query = {
      'page': '$page',
      'size': '$size',
      if (type.isNotEmpty) 'type': type,
    };
    final parsed = await _request('GET', '/api/health', query: query);
    return HealthPageData.fromJson(parsed as Map<String, dynamic>);
  }

  Future<List<WeightRecord>> listWeight(String cattleId) async {
    final parsed = await _request('GET', '/api/cattle/$cattleId/weight');
    return (parsed as List<dynamic>? ?? const [])
        .map((item) => WeightRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WeightRecord> createWeight(String cattleId, Map<String, dynamic> payload) async {
    final parsed = await _request('POST', '/api/cattle/$cattleId/weight', body: payload);
    return WeightRecord.fromJson(parsed as Map<String, dynamic>);
  }

  Future<void> deleteWeight(String cattleId, String recordId) async {
    await _request('DELETE', '/api/cattle/$cattleId/weight/$recordId');
  }

  Future<List<BreedingRecord>> listBreeding(String cattleId) async {
    final parsed = await _request('GET', '/api/cattle/$cattleId/breeding');
    return (parsed as List<dynamic>? ?? const [])
        .map((item) => BreedingRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BreedingRecord> createBreeding(String cattleId, Map<String, dynamic> payload) async {
    final parsed = await _request('POST', '/api/cattle/$cattleId/breeding', body: payload);
    return BreedingRecord.fromJson(parsed as Map<String, dynamic>);
  }

  Future<BreedingRecord> updateBreeding(
    String cattleId,
    String recordId,
    Map<String, dynamic> payload,
  ) async {
    final parsed = await _request(
      'PUT',
      '/api/cattle/$cattleId/breeding/$recordId',
      body: payload,
    );
    return BreedingRecord.fromJson(parsed as Map<String, dynamic>);
  }

  Future<void> deleteBreeding(String cattleId, String recordId) async {
    await _request('DELETE', '/api/cattle/$cattleId/breeding/$recordId');
  }

  /// Upload an image to the embedding-based identify endpoint.
  /// Returns the top matched animal or null when uncertain.
  Future<Map<String, dynamic>> identifyCattle(Uint8List bytes) async {
    final request = http.MultipartRequest('POST', _uri('/api/animals/identify'));
    request.headers.addAll(_headers(jsonBody: false));
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'identify_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(
        (_parseBody(response) as Map<String, dynamic>? ?? const <String, dynamic>{}),
      );
    }
    final parsed = _parseBody(response);
    throw ApiException(
      _extractMessage(parsed) ?? 'Identify failed with status ${response.statusCode}',
      statusCode: response.statusCode,
      body: parsed,
    );
  }

  Future<DetectionHistoryPageData> listDetectionHistory({
    int page = 0,
    int size = 30,
  }) async {
    final parsed = await _request('GET', '/api/detect/history', query: {
      'page': '$page',
      'size': '$size',
    });
    final map = parsed as Map<String, dynamic>;
    final normalizedBase = _normalizedBaseUrl();
    return DetectionHistoryPageData(
      content: (map['content'] as List<dynamic>? ?? const [])
          .map(
            (item) => DetectionHistoryItem.fromJson(
              item as Map<String, dynamic>,
              normalizedBase,
            ),
          )
          .toList(),
      totalElements: map['totalElements'] as int? ?? 0,
    );
  }

  Future<AiStatusInfo> getAiStatus(String cattleId) async {
    final parsed = await _request('GET', '/api/animals/$cattleId/ai-status');
    return AiStatusInfo.fromJson(parsed as Map<String, dynamic>);
  }

  Future<ActivateAiResult> activateAi(String cattleId) async {
    final parsed = await _request('POST', '/api/animals/$cattleId/activate-ai');
    return ActivateAiResult.fromJson(parsed as Map<String, dynamic>);
  }
}

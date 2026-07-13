import 'dart:convert';

enum UserRole { admin, user, farmOwner }

enum RecordType { vaccination, treatment, checkup, other }

enum PlannerPriority { low, medium, high }

enum PlannerStatus { open, done }

enum BreedingMethod { natural, artificialInsemination }

enum BreedingOutcome { pending, success, failed, miscarriage }

enum CattleGender { male, female }

enum HornStatus { horned, polled }

UserRole userRoleFromApi(String value) {
  switch (value.toUpperCase()) {
    case 'ADMIN':
      return UserRole.admin;
    case 'FARM_OWNER':
      return UserRole.farmOwner;
    default:
      return UserRole.user;
  }
}

String userRoleToApi(UserRole value) {
  switch (value) {
    case UserRole.admin:
      return 'ADMIN';
    case UserRole.farmOwner:
      return 'FARM_OWNER';
    case UserRole.user:
      return 'USER';
  }
}

RecordType recordTypeFromApi(String value) {
  switch (value.toUpperCase()) {
    case 'VACCINATION':
      return RecordType.vaccination;
    case 'TREATMENT':
      return RecordType.treatment;
    case 'CHECKUP':
      return RecordType.checkup;
    default:
      return RecordType.other;
  }
}

String recordTypeToApi(RecordType value) {
  switch (value) {
    case RecordType.vaccination:
      return 'VACCINATION';
    case RecordType.treatment:
      return 'TREATMENT';
    case RecordType.checkup:
      return 'CHECKUP';
    case RecordType.other:
      return 'OTHER';
  }
}

PlannerPriority plannerPriorityFromApi(String value) {
  switch (value.toUpperCase()) {
    case 'HIGH':
      return PlannerPriority.high;
    case 'LOW':
      return PlannerPriority.low;
    default:
      return PlannerPriority.medium;
  }
}

String plannerPriorityToApi(PlannerPriority value) {
  switch (value) {
    case PlannerPriority.low:
      return 'LOW';
    case PlannerPriority.medium:
      return 'MEDIUM';
    case PlannerPriority.high:
      return 'HIGH';
  }
}

PlannerStatus plannerStatusFromApi(String value) {
  return value.toUpperCase() == 'DONE' ? PlannerStatus.done : PlannerStatus.open;
}

String plannerStatusToApi(PlannerStatus value) {
  return value == PlannerStatus.done ? 'DONE' : 'OPEN';
}

BreedingMethod breedingMethodFromApi(String value) {
  return value.toUpperCase() == 'ARTIFICIAL_INSEMINATION'
      ? BreedingMethod.artificialInsemination
      : BreedingMethod.natural;
}

String breedingMethodToApi(BreedingMethod value) {
  return value == BreedingMethod.artificialInsemination
      ? 'ARTIFICIAL_INSEMINATION'
      : 'NATURAL';
}

BreedingOutcome breedingOutcomeFromApi(String value) {
  switch (value.toUpperCase()) {
    case 'SUCCESS':
      return BreedingOutcome.success;
    case 'FAILED':
      return BreedingOutcome.failed;
    case 'MISCARRIAGE':
      return BreedingOutcome.miscarriage;
    default:
      return BreedingOutcome.pending;
  }
}

String breedingOutcomeToApi(BreedingOutcome value) {
  switch (value) {
    case BreedingOutcome.pending:
      return 'PENDING';
    case BreedingOutcome.success:
      return 'SUCCESS';
    case BreedingOutcome.failed:
      return 'FAILED';
    case BreedingOutcome.miscarriage:
      return 'MISCARRIAGE';
  }
}

enum AiStatus { pendingImages, processingImages, aiActive, aiReviewRequired, aiDisabled }

AiStatus aiStatusFromApi(String value) {
  switch (value.toUpperCase()) {
    case 'AI_ACTIVE':
      return AiStatus.aiActive;
    case 'PROCESSING_IMAGES':
      return AiStatus.processingImages;
    case 'AI_REVIEW_REQUIRED':
      return AiStatus.aiReviewRequired;
    case 'AI_DISABLED':
      return AiStatus.aiDisabled;
    default:
      return AiStatus.pendingImages;
  }
}

CattleGender cattleGenderFromApi(String value) {
  return value.toUpperCase() == 'MALE' ? CattleGender.male : CattleGender.female;
}

String cattleGenderToApi(CattleGender value) {
  return value == CattleGender.male ? 'MALE' : 'FEMALE';
}

HornStatus hornStatusFromApi(String value) {
  return value.toUpperCase() == 'POLLED' ? HornStatus.polled : HornStatus.horned;
}

String hornStatusToApi(HornStatus value) {
  return value == HornStatus.polled ? 'POLLED' : 'HORNED';
}

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double? _doubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

class UserSession {
  final String id;
  final String username;
  final UserRole role;
  final String token;

  const UserSession({
    required this.id,
    required this.username,
    required this.role,
    required this.token,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'].toString(),
      username: json['username']?.toString() ?? '',
      role: userRoleFromApi(json['role']?.toString() ?? 'USER'),
      token: json['token']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'role': userRoleToApi(role),
        'token': token,
      };
}

class UserProfile {
  final String id;
  final String username;
  final UserRole role;
  final String? displayName;
  final String? email;
  final String? phone;
  final bool enabled;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.role,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.enabled,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      username: json['username']?.toString() ?? '',
      role: userRoleFromApi(json['role']?.toString() ?? 'USER'),
      displayName: _stringOrNull(json['displayName']),
      email: _stringOrNull(json['email']),
      phone: _stringOrNull(json['phone']),
      enabled: json['enabled'] == true,
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}

class AdminUser {
  final String id;
  final String username;
  final UserRole role;
  final bool enabled;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    required this.username,
    required this.role,
    required this.enabled,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'].toString(),
      username: json['username']?.toString() ?? '',
      role: userRoleFromApi(json['role']?.toString() ?? 'USER'),
      enabled: json['enabled'] == true,
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}

class AppStats {
  final int totalCattle;
  final int recentRegistrations;
  final int detectionCount;
  final int totalUsers;
  final int totalFarms;
  final int totalHealthRecords;
  final int totalWeightRecords;
  final int totalBreedingRecords;
  final int totalPlannerTasks;
  final List<BreedCount> byBreed;
  final Map<String, int> byGender;

  const AppStats({
    required this.totalCattle,
    required this.recentRegistrations,
    required this.detectionCount,
    required this.totalUsers,
    required this.totalFarms,
    required this.totalHealthRecords,
    required this.totalWeightRecords,
    required this.totalBreedingRecords,
    required this.totalPlannerTasks,
    required this.byBreed,
    required this.byGender,
  });

  factory AppStats.fromJson(Map<String, dynamic> json) {
    final byGenderMap = <String, int>{};
    final rawByGender = json['byGender'];
    if (rawByGender is Map<String, dynamic>) {
      rawByGender.forEach((key, value) {
        byGenderMap[key] = _intOrNull(value) ?? 0;
      });
    }
    return AppStats(
      totalCattle: _intOrNull(json['totalCattle']) ?? 0,
      recentRegistrations: _intOrNull(json['recentRegistrations']) ?? 0,
      detectionCount: _intOrNull(json['detectionCount']) ?? 0,
      totalUsers: _intOrNull(json['totalUsers']) ?? 0,
      totalFarms: _intOrNull(json['totalFarms']) ?? 0,
      totalHealthRecords: _intOrNull(json['totalHealthRecords']) ?? 0,
      totalWeightRecords: _intOrNull(json['totalWeightRecords']) ?? 0,
      totalBreedingRecords: _intOrNull(json['totalBreedingRecords']) ?? 0,
      totalPlannerTasks: _intOrNull(json['totalPlannerTasks']) ?? 0,
      byBreed: (json['byBreed'] as List<dynamic>? ?? [])
          .map((item) => BreedCount.fromJson(item as Map<String, dynamic>))
          .toList(),
      byGender: byGenderMap,
    );
  }
}

class BreedCount {
  final String breed;
  final int count;

  const BreedCount({required this.breed, required this.count});

  factory BreedCount.fromJson(Map<String, dynamic> json) {
    return BreedCount(
      breed: json['breed']?.toString() ?? 'Unknown',
      count: _intOrNull(json['count']) ?? 0,
    );
  }
}

class ImageRef {
  final String id;
  final String url;

  const ImageRef({required this.id, required this.url});

  factory ImageRef.fromJson(Map<String, dynamic> json) {
    return ImageRef(
      id: json['id'].toString(),
      url: json['url']?.toString() ?? '',
    );
  }
}

class CattleRecord {
  final String id;
  final String cattleId;
  final String owner;
  final DateTime dateOfBirth;
  final CattleGender gender;
  final String color;
  final double weightKg;
  final String breed;
  final HornStatus hornStatus;
  final String? farmLocation;
  final String? notes;
  final DateTime registeredAt;
  final String? registeredBy;
  final AiStatus aiStatus;
  final String? farmId;
  final String? farmName;
  final String? farmAddress;
  final String? farmOwnerName;
  final String? farmOwnerPhone;
  final String? farmOwnerEmail;
  final double? farmLatitude;
  final double? farmLongitude;
  final List<ImageRef> images;

  const CattleRecord({
    required this.id,
    required this.cattleId,
    required this.owner,
    required this.dateOfBirth,
    required this.gender,
    required this.color,
    required this.weightKg,
    required this.breed,
    required this.hornStatus,
    required this.farmLocation,
    required this.notes,
    required this.registeredAt,
    required this.registeredBy,
    required this.aiStatus,
    required this.farmId,
    required this.farmName,
    required this.farmAddress,
    required this.farmOwnerName,
    required this.farmOwnerPhone,
    required this.farmOwnerEmail,
    required this.farmLatitude,
    required this.farmLongitude,
    required this.images,
  });

  factory CattleRecord.fromJson(Map<String, dynamic> json) {
    return CattleRecord(
      id: json['id'].toString(),
      cattleId: json['cattleId']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      dateOfBirth: DateTime.parse(json['dateOfBirth'].toString()),
      gender: cattleGenderFromApi(json['gender']?.toString() ?? 'FEMALE'),
      color: json['color']?.toString() ?? '',
      weightKg: _doubleOrNull(json['weightKg']) ?? 0,
      breed: json['breed']?.toString() ?? '',
      hornStatus: hornStatusFromApi(json['hornStatus']?.toString() ?? 'HORNED'),
      farmLocation: _stringOrNull(json['farmLocation']),
      notes: _stringOrNull(json['notes']),
      registeredAt: DateTime.parse(json['registeredAt'].toString()),
      registeredBy: _stringOrNull(json['registeredBy']),
      aiStatus: aiStatusFromApi(json['aiStatus']?.toString() ?? 'PENDING_IMAGES'),
      farmId: _stringOrNull(json['farmId']),
      farmName: _stringOrNull(json['farmName']),
      farmAddress: _stringOrNull(json['farmAddress']),
      farmOwnerName: _stringOrNull(json['farmOwnerName']),
      farmOwnerPhone: _stringOrNull(json['farmOwnerPhone']),
      farmOwnerEmail: _stringOrNull(json['farmOwnerEmail']),
      farmLatitude: _doubleOrNull(json['farmLatitude']),
      farmLongitude: _doubleOrNull(json['farmLongitude']),
      images: (json['images'] as List<dynamic>? ?? [])
          .map((item) => ImageRef.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AiStatusInfo {
  final String cattleId;
  final AiStatus aiStatus;
  final int embeddingCount;
  final int imageCount;

  const AiStatusInfo({
    required this.cattleId,
    required this.aiStatus,
    required this.embeddingCount,
    required this.imageCount,
  });

  factory AiStatusInfo.fromJson(Map<String, dynamic> json) {
    return AiStatusInfo(
      cattleId: json['cattleId'].toString(),
      aiStatus: aiStatusFromApi(json['aiStatus']?.toString() ?? 'PENDING_IMAGES'),
      embeddingCount: _intOrNull(json['embeddingCount']) ?? 0,
      imageCount: _intOrNull(json['imageCount']) ?? 0,
    );
  }
}

class ActivateAiResult {
  final String message;
  final AiStatus aiStatus;
  final int embeddingsCreated;

  const ActivateAiResult({
    required this.message,
    required this.aiStatus,
    required this.embeddingsCreated,
  });

  factory ActivateAiResult.fromJson(Map<String, dynamic> json) {
    return ActivateAiResult(
      message: json['message']?.toString() ?? '',
      aiStatus: aiStatusFromApi(json['aiStatus']?.toString() ?? 'PENDING_IMAGES'),
      embeddingsCreated: _intOrNull(json['embeddingsCreated']) ?? 0,
    );
  }
}

class CattlePageData {
  final List<CattleRecord> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;

  const CattlePageData({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
  });

  factory CattlePageData.fromJson(Map<String, dynamic> json) {
    return CattlePageData(
      content: (json['content'] as List<dynamic>? ?? [])
          .map((item) => CattleRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalElements: _intOrNull(json['totalElements']) ?? 0,
      totalPages: _intOrNull(json['totalPages']) ?? 0,
      number: _intOrNull(json['number']) ?? 0,
      size: _intOrNull(json['size']) ?? 0,
    );
  }
}

class FarmRecord {
  final String id;
  final String name;
  final String? ownerUserId;
  final String? ownerUsername;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? farmSizeHectares;
  final String? notes;
  final bool active;
  final DateTime createdAt;
  final int cattleCount;

  const FarmRecord({
    required this.id,
    required this.name,
    required this.ownerUserId,
    required this.ownerUsername,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.farmSizeHectares,
    required this.notes,
    required this.active,
    required this.createdAt,
    required this.cattleCount,
  });

  factory FarmRecord.fromJson(Map<String, dynamic> json) {
    return FarmRecord(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      ownerUserId: _stringOrNull(json['ownerUserId']),
      ownerUsername: _stringOrNull(json['ownerUsername']),
      ownerName: _stringOrNull(json['ownerName']),
      ownerPhone: _stringOrNull(json['ownerPhone']),
      ownerEmail: _stringOrNull(json['ownerEmail']),
      address: _stringOrNull(json['address']),
      latitude: _doubleOrNull(json['latitude']),
      longitude: _doubleOrNull(json['longitude']),
      farmSizeHectares: _doubleOrNull(json['farmSizeHectares']),
      notes: _stringOrNull(json['notes']),
      active: json['active'] == true,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      cattleCount: _intOrNull(json['cattleCount']) ?? 0,
    );
  }
}

class HealthRecord {
  final String id;
  final String cattleId;
  final String cattleLabel;
  final DateTime date;
  final RecordType type;
  final String description;
  final String? veterinarian;
  final String? notes;
  final DateTime createdAt;

  const HealthRecord({
    required this.id,
    required this.cattleId,
    required this.cattleLabel,
    required this.date,
    required this.type,
    required this.description,
    required this.veterinarian,
    required this.notes,
    required this.createdAt,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'].toString(),
      cattleId: json['cattleId']?.toString() ?? '',
      cattleLabel: json['cattleCattleId']?.toString() ?? '',
      date: DateTime.parse(json['date'].toString()),
      type: recordTypeFromApi(json['type']?.toString() ?? 'OTHER'),
      description: json['description']?.toString() ?? '',
      veterinarian: _stringOrNull(json['veterinarian']),
      notes: _stringOrNull(json['notes']),
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}

class HealthPageData {
  final List<HealthRecord> content;
  final int totalElements;

  const HealthPageData({required this.content, required this.totalElements});

  factory HealthPageData.fromJson(Map<String, dynamic> json) {
    return HealthPageData(
      content: (json['content'] as List<dynamic>? ?? [])
          .map((item) => HealthRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalElements: _intOrNull(json['totalElements']) ?? 0,
    );
  }
}

class WeightRecord {
  final String id;
  final double weightKg;
  final DateTime recordedOn;
  final String? notes;
  final DateTime createdAt;

  const WeightRecord({
    required this.id,
    required this.weightKg,
    required this.recordedOn,
    required this.notes,
    required this.createdAt,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'].toString(),
      weightKg: _doubleOrNull(json['weightKg']) ?? 0,
      recordedOn: DateTime.parse(json['recordedOn'].toString()),
      notes: _stringOrNull(json['notes']),
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}

class BreedingRecord {
  final String id;
  final String cattleId;
  final DateTime breedingDate;
  final BreedingMethod method;
  final DateTime? expectedCalvingDate;
  final DateTime? actualCalvingDate;
  final String? sireId;
  final String? sireBreed;
  final int? offspringCount;
  final CattleGender? offspringGender;
  final BreedingOutcome outcome;
  final String? notes;
  final DateTime createdAt;

  const BreedingRecord({
    required this.id,
    required this.cattleId,
    required this.breedingDate,
    required this.method,
    required this.expectedCalvingDate,
    required this.actualCalvingDate,
    required this.sireId,
    required this.sireBreed,
    required this.offspringCount,
    required this.offspringGender,
    required this.outcome,
    required this.notes,
    required this.createdAt,
  });

  factory BreedingRecord.fromJson(Map<String, dynamic> json) {
    return BreedingRecord(
      id: json['id'].toString(),
      cattleId: json['cattleId']?.toString() ?? '',
      breedingDate: DateTime.parse(json['breedingDate'].toString()),
      method: breedingMethodFromApi(json['method']?.toString() ?? 'NATURAL'),
      expectedCalvingDate: _stringOrNull(json['expectedCalvingDate']) != null
          ? DateTime.parse(json['expectedCalvingDate'].toString())
          : null,
      actualCalvingDate: _stringOrNull(json['actualCalvingDate']) != null
          ? DateTime.parse(json['actualCalvingDate'].toString())
          : null,
      sireId: _stringOrNull(json['sireId']),
      sireBreed: _stringOrNull(json['sireBreed']),
      offspringCount: _intOrNull(json['offspringCount']),
      offspringGender: _stringOrNull(json['offspringGender']) != null
          ? cattleGenderFromApi(json['offspringGender'].toString())
          : null,
      outcome: breedingOutcomeFromApi(json['outcome']?.toString() ?? 'PENDING'),
      notes: _stringOrNull(json['notes']),
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}

class PlannerTask {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime dueDate;
  final PlannerPriority priority;
  final PlannerStatus status;
  final String? cattleId;
  final String? cattleLabel;
  final DateTime createdAt;

  const PlannerTask({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.cattleId,
    required this.cattleLabel,
    required this.createdAt,
  });

  factory PlannerTask.fromJson(Map<String, dynamic> json) {
    return PlannerTask(
      id: json['id'].toString(),
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dueDate: DateTime.parse(json['dueDate'].toString()),
      priority: plannerPriorityFromApi(json['priority']?.toString() ?? 'MEDIUM'),
      status: plannerStatusFromApi(json['status']?.toString() ?? 'OPEN'),
      cattleId: _stringOrNull(json['cattleId']),
      cattleLabel: _stringOrNull(json['cattleLabel']),
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}

class DetectionBox {
  final double x;
  final double y;
  final double width;
  final double height;

  const DetectionBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory DetectionBox.fromJson(Map<String, dynamic> json) {
    return DetectionBox(
      x: _doubleOrNull(json['x']) ?? 0,
      y: _doubleOrNull(json['y']) ?? 0,
      width: _doubleOrNull(json['width']) ?? 0,
      height: _doubleOrNull(json['height']) ?? 0,
    );
  }
}

class DetectionResultModel {
  final String label;
  final double confidence;
  final DetectionBox box;

  const DetectionResultModel({
    required this.label,
    required this.confidence,
    required this.box,
  });

  factory DetectionResultModel.fromJson(Map<String, dynamic> json) {
    return DetectionResultModel(
      label: json['label']?.toString() ?? 'Unknown',
      confidence: _doubleOrNull(json['confidence']) ?? 0,
      box: DetectionBox.fromJson(json['box'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class DetectionResponseData {
  final List<DetectionResultModel> detections;
  final String? imageUrl;

  const DetectionResponseData({
    required this.detections,
    required this.imageUrl,
  });

  factory DetectionResponseData.fromJson(Map<String, dynamic> json) {
    return DetectionResponseData(
      detections: (json['detections'] as List<dynamic>? ?? [])
          .map((item) => DetectionResultModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      imageUrl: _stringOrNull(json['imageUrl']),
    );
  }
}

class DetectionHistoryItem {
  final String id;
  final String username;
  final String? imageUrl;
  final int detectionCount;
  final List<DetectionResultModel> detections;
  final DateTime createdAt;

  const DetectionHistoryItem({
    required this.id,
    required this.username,
    required this.imageUrl,
    required this.detectionCount,
    required this.detections,
    required this.createdAt,
  });

  factory DetectionHistoryItem.fromJson(Map<String, dynamic> json, String baseUrl) {
    final rawImageUrl = _stringOrNull(json['imageUrl']);
    final rawDetectionJson = json['detectionJson']?.toString() ?? '[]';
    List<DetectionResultModel> parsedDetections = const [];
    try {
      final decoded = jsonDecode(rawDetectionJson) as List<dynamic>;
      parsedDetections = decoded
          .map((item) => DetectionResultModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    return DetectionHistoryItem(
      id: json['id'].toString(),
      username: json['username']?.toString() ?? 'unknown',
      imageUrl: rawImageUrl == null
          ? null
          : (rawImageUrl.startsWith('http') ? rawImageUrl : '$baseUrl$rawImageUrl'),
      detectionCount: _intOrNull(json['detectionCount']) ?? 0,
      detections: parsedDetections,
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}

class DetectionHistoryPageData {
  final List<DetectionHistoryItem> content;
  final int totalElements;

  const DetectionHistoryPageData({
    required this.content,
    required this.totalElements,
  });
}

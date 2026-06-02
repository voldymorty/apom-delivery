// To parse this JSON data, do
//
//     final taskModel = taskModelFromJson(jsonString);

import 'dart:convert';

TaskModel taskModelFromJson(String str) => TaskModel.fromJson(json.decode(str));

String taskModelToJson(TaskModel data) => json.encode(data.toJson());

class TaskTypeValue {
  static const String pickup = 'pickup';
  static const String delivery = 'delivery';
  static const List<String> values = [pickup, delivery];
}

class TaskStatusValue {
  static const String assigned = 'assigned';
  static const String accepted = 'accepted';
  static const String inTransit = 'in_transit';
  static const String reached = 'reached';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String failed = 'failed';
  static const List<String> values = [
    assigned,
    accepted,
    inTransit,
    reached,
    completed,
    cancelled,
    failed,
  ];
}

class TaskModel {
  bool success;
  List<Datum> data;
  int total;
  int page;
  int limit;
  int totalPages;

  TaskModel({
    required this.success,
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final items = rawData is List
        ? rawData
            .whereType<Map<String, dynamic>>()
            .map(Datum.fromJson)
            .toList()
        : <Datum>[];

    return TaskModel(
      success: json["success"] == true,
      data: items,
      total: _readInt(json, "total"),
      page: _readInt(json, "page"),
      limit: _readInt(json, "limit"),
      totalPages: _readInt(json, "totalPages"),
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "total": total,
    "page": page,
    "limit": limit,
    "totalPages": totalPages,
  };
}

class Datum {
  int deliveryId;
  String deliveryNumber;
  String deliveryType;
  int farmerId;
  dynamic cropId;
  dynamic orderId;
  dynamic vendorId;
  int deliveryPersonId;
  dynamic assignedBy;
  String pickupAddress;
  String pickupLatitude;
  String pickupLongitude;
  String pickupContactName;
  String pickupContactNumber;
  String deliveryAddress;
  String deliveryLatitude;
  String deliveryLongitude;
  String deliveryContactName;
  String deliveryContactNumber;
  DateTime? scheduledDate;
  String scheduledTimeSlot;
  String status;
  String otpCode;
  dynamic otpVerifiedAt;
  DateTime? acceptedAt;
  dynamic startedAt;
  dynamic reachedAt;
  dynamic completedAt;
  String expectedQuantityKg;
  dynamic actualQuantityKg;
  String deliveryNotes;
  dynamic failureReason;
  dynamic proofPhotoUrl;
  dynamic signatureUrl;
  String estimatedDistanceKm;
  dynamic actualDistanceKm;
  int estimatedTimeMinutes;
  dynamic actualTimeMinutes;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic routeId;
  Farmer farmer;
  dynamic vendor;
  dynamic crop;
  dynamic order;

  Datum({
    required this.deliveryId,
    required this.deliveryNumber,
    required this.deliveryType,
    required this.farmerId,
    required this.cropId,
    required this.orderId,
    required this.vendorId,
    required this.deliveryPersonId,
    required this.assignedBy,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupContactName,
    required this.pickupContactNumber,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.deliveryContactName,
    required this.deliveryContactNumber,
    required this.scheduledDate,
    required this.scheduledTimeSlot,
    required this.status,
    required this.otpCode,
    required this.otpVerifiedAt,
    required this.acceptedAt,
    required this.startedAt,
    required this.reachedAt,
    required this.completedAt,
    required this.expectedQuantityKg,
    required this.actualQuantityKg,
    required this.deliveryNotes,
    required this.failureReason,
    required this.proofPhotoUrl,
    required this.signatureUrl,
    required this.estimatedDistanceKm,
    required this.actualDistanceKm,
    required this.estimatedTimeMinutes,
    required this.actualTimeMinutes,
    required this.createdAt,
    required this.updatedAt,
    required this.routeId,
    required this.farmer,
    required this.vendor,
    required this.crop,
    required this.order,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    deliveryId: _readInt(json, "delivery_id"),
    deliveryNumber: _readString(json, "delivery_number"),
    deliveryType: _readString(json, "delivery_type"),
    farmerId: _readInt(json, "farmer_id"),
    cropId: json["crop_id"],
    orderId: json["order_id"],
    vendorId: json["vendor_id"],
    deliveryPersonId: _readInt(json, "delivery_person_id"),
    assignedBy: json["assigned_by"],
    pickupAddress: _readString(json, "pickup_address"),
    pickupLatitude: _readString(json, "pickup_latitude"),
    pickupLongitude: _readString(json, "pickup_longitude"),
    pickupContactName: _readString(json, "pickup_contact_name"),
    pickupContactNumber: _readString(json, "pickup_contact_number"),
    deliveryAddress: _readString(json, "delivery_address"),
    deliveryLatitude: _readString(json, "delivery_latitude"),
    deliveryLongitude: _readString(json, "delivery_longitude"),
    deliveryContactName: _readString(json, "delivery_contact_name"),
    deliveryContactNumber: _readString(json, "delivery_contact_number"),
    scheduledDate: _readDateTime(json, "scheduled_date"),
    scheduledTimeSlot: _readString(json, "scheduled_time_slot"),
    status: _readString(json, "status"),
    otpCode: _readString(json, "otp_code"),
    otpVerifiedAt: json["otp_verified_at"],
    acceptedAt: _readDateTime(json, "accepted_at"),
    startedAt: json["started_at"],
    reachedAt: json["reached_at"],
    completedAt: json["completed_at"],
    expectedQuantityKg: _readString(json, "expected_quantity_kg"),
    actualQuantityKg: json["actual_quantity_kg"],
    deliveryNotes: _readString(json, "delivery_notes"),
    failureReason: json["failure_reason"],
    proofPhotoUrl: json["proof_photo_url"],
    signatureUrl: json["signature_url"],
    estimatedDistanceKm: _readString(json, "estimated_distance_km"),
    actualDistanceKm: json["actual_distance_km"],
    estimatedTimeMinutes: _readInt(json, "estimated_time_minutes"),
    actualTimeMinutes: json["actual_time_minutes"],
    createdAt: _readDateTime(json, "created_at"),
    updatedAt: _readDateTime(json, "updated_at"),
    routeId: json["route_id"],
    farmer: _readFarmer(json["farmer"]),
    vendor: json["vendor"],
    crop: json["crop"],
    order: json["order"],
  );

  Map<String, dynamic> toJson() => {
    "delivery_id": deliveryId,
    "delivery_number": deliveryNumber,
    "delivery_type": deliveryType,
    "farmer_id": farmerId,
    "crop_id": cropId,
    "order_id": orderId,
    "vendor_id": vendorId,
    "delivery_person_id": deliveryPersonId,
    "assigned_by": assignedBy,
    "pickup_address": pickupAddress,
    "pickup_latitude": pickupLatitude,
    "pickup_longitude": pickupLongitude,
    "pickup_contact_name": pickupContactName,
    "pickup_contact_number": pickupContactNumber,
    "delivery_address": deliveryAddress,
    "delivery_latitude": deliveryLatitude,
    "delivery_longitude": deliveryLongitude,
    "delivery_contact_name": deliveryContactName,
    "delivery_contact_number": deliveryContactNumber,
    "scheduled_date": scheduledDate == null
        ? null
        : "${scheduledDate!.year.toString().padLeft(4, '0')}-"
            "${scheduledDate!.month.toString().padLeft(2, '0')}-"
            "${scheduledDate!.day.toString().padLeft(2, '0')}",
    "scheduled_time_slot": scheduledTimeSlot,
    "status": status,
    "otp_code": otpCode,
    "otp_verified_at": otpVerifiedAt,
    "accepted_at": acceptedAt?.toIso8601String(),
    "started_at": startedAt,
    "reached_at": reachedAt,
    "completed_at": completedAt,
    "expected_quantity_kg": expectedQuantityKg,
    "actual_quantity_kg": actualQuantityKg,
    "delivery_notes": deliveryNotes,
    "failure_reason": failureReason,
    "proof_photo_url": proofPhotoUrl,
    "signature_url": signatureUrl,
    "estimated_distance_km": estimatedDistanceKm,
    "actual_distance_km": actualDistanceKm,
    "estimated_time_minutes": estimatedTimeMinutes,
    "actual_time_minutes": actualTimeMinutes,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "route_id": routeId,
    "farmer": farmer.toJson(),
    "vendor": vendor,
    "crop": crop,
    "order": order,
  };
}

class Farmer {
  String fullName;
  String locationAddress;
  dynamic user;

  Farmer({
    required this.fullName,
    required this.locationAddress,
    required this.user,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
    fullName: _readString(json, "full_name"),
    locationAddress: _readString(json, "location_address"),
    user: json["user"],
  );

  factory Farmer.empty() => Farmer(
    fullName: '',
    locationAddress: '',
    user: null,
  );

  Map<String, dynamic> toJson() => {
    "full_name": fullName,
    "location_address": locationAddress,
    "user": user,
  };
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value == null ? '' : value.toString();
}

DateTime? _readDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

Farmer _readFarmer(dynamic data) {
  if (data is Map<String, dynamic>) {
    return Farmer.fromJson(data);
  }
  return Farmer.empty();
}

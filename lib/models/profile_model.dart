// To parse this JSON data, do
//
//     final profileModel = profileModelFromJson(jsonString);

import 'dart:convert';

ProfileModel profileModelFromJson(String str) =>
    ProfileModel.fromJson(json.decode(str));

String profileModelToJson(ProfileModel data) => json.encode(data.toJson());

class ProfileModel {
    bool success;
    Data data;

    ProfileModel({
        required this.success,
        required this.data,
    });

    factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        success: _readBool(json, "success"),
        data: Data.fromJson(
          json["data"] is Map<String, dynamic>
              ? json["data"] as Map<String, dynamic>
              : const <String, dynamic>{},
        ),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": data.toJson(),
    };
}

class Data {
    int deliveryPersonId;
    int userId;
    String fullName;
    dynamic profilePhotoUrl;
    String vehicleType;
    String vehicleNumber;
    String licenseNumber;
    DateTime licenseExpiryDate;
    bool isAvailable;
    dynamic currentLatitude;
    dynamic currentLongitude;
    dynamic lastLocationUpdate;
    int totalDeliveries;
    int completedDeliveries;
    String rating;
    DateTime createdAt;
    DateTime updatedAt;
    User user;

    Data({
        required this.deliveryPersonId,
        required this.userId,
        required this.fullName,
        required this.profilePhotoUrl,
        required this.vehicleType,
        required this.vehicleNumber,
        required this.licenseNumber,
        required this.licenseExpiryDate,
        required this.isAvailable,
        required this.currentLatitude,
        required this.currentLongitude,
        required this.lastLocationUpdate,
        required this.totalDeliveries,
        required this.completedDeliveries,
        required this.rating,
        required this.createdAt,
        required this.updatedAt,
        required this.user,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        deliveryPersonId: _readInt(json, "delivery_person_id"),
        userId: _readInt(json, "user_id"),
        fullName: _readString(json, "full_name"),
        profilePhotoUrl: json["profile_photo_url"],
        vehicleType: _readString(json, "vehicle_type"),
        vehicleNumber: _readString(json, "vehicle_number"),
        licenseNumber: _readString(json, "license_number"),
        licenseExpiryDate: _readDate(json, "license_expiry_date"),
        isAvailable: _readBool(json, "is_available"),
        currentLatitude: json["current_latitude"],
        currentLongitude: json["current_longitude"],
        lastLocationUpdate: json["last_location_update"],
        totalDeliveries: _readInt(json, "total_deliveries"),
        completedDeliveries: _readInt(json, "completed_deliveries"),
        rating: _readString(json, "rating"),
        createdAt: _readDate(json, "created_at"),
        updatedAt: _readDate(json, "updated_at"),
        user: User.fromJson(
          json["user"] is Map<String, dynamic>
              ? json["user"] as Map<String, dynamic>
              : const <String, dynamic>{},
        ),
    );

    Map<String, dynamic> toJson() => {
        "delivery_person_id": deliveryPersonId,
        "user_id": userId,
        "full_name": fullName,
        "profile_photo_url": profilePhotoUrl,
        "vehicle_type": vehicleType,
        "vehicle_number": vehicleNumber,
        "license_number": licenseNumber,
        "license_expiry_date":
            "${licenseExpiryDate.year.toString().padLeft(4, '0')}-${licenseExpiryDate.month.toString().padLeft(2, '0')}-${licenseExpiryDate.day.toString().padLeft(2, '0')}",
        "is_available": isAvailable,
        "current_latitude": currentLatitude,
        "current_longitude": currentLongitude,
        "last_location_update": lastLocationUpdate,
        "total_deliveries": totalDeliveries,
        "completed_deliveries": completedDeliveries,
        "rating": rating,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "user": user.toJson(),
    };
}

class User {
    String mobileNumber;
    dynamic email;
    bool isActive;

    User({
        required this.mobileNumber,
        required this.email,
        required this.isActive,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        mobileNumber: _readString(json, "mobile_number"),
        email: json["email"],
        isActive: _readBool(json, "is_active"),
    );

    Map<String, dynamic> toJson() => {
        "mobile_number": mobileNumber,
        "email": email,
        "is_active": isActive,
    };
}

String _readString(Map<String, dynamic> json, String key, {String fallback = ''}) {
  final value = json[key];
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

int _readInt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

bool _readBool(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return fallback;
}

DateTime _readDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

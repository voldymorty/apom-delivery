// To parse this JSON data, do
//
//     final historyModel = historyModelFromJson(jsonString);

import 'dart:convert';

HistoryModel historyModelFromJson(String str) => HistoryModel.fromJson(json.decode(str));

String historyModelToJson(HistoryModel data) => json.encode(data.toJson());

class HistoryModel {
    bool success;
    List<Datum> data;
    int total;
    int page;
    int limit;
    int totalPages;
    Summary summary;

    HistoryModel({
        required this.success,
        required this.data,
        required this.total,
        required this.page,
        required this.limit,
        required this.totalPages,
        required this.summary,
    });

    factory HistoryModel.fromJson(Map<String, dynamic> json) => HistoryModel(
        success: json["success"] == true,
        data: _readList(json["data"], (data) => Datum.fromJson(data)),
        total: _readInt(json, "total"),
        page: _readInt(json, "page"),
        limit: _readInt(json, "limit"),
        totalPages: _readInt(json, "totalPages"),
        summary: _readSummary(json["summary"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "total": total,
        "page": page,
        "limit": limit,
        "totalPages": totalPages,
        "summary": summary.toJson(),
    };
}

class Datum {
    int deliveryId;
    String deliveryNumber;
    String deliveryType;
    int? farmerId;
    int? cropId;
    int? orderId;
    int? vendorId;
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
    DateTime? otpVerifiedAt;
    DateTime? acceptedAt;
    DateTime? startedAt;
    DateTime? reachedAt;
    DateTime? completedAt;
    String expectedQuantityKg;
    String? actualQuantityKg;
    String? deliveryNotes;
    String? failureReason;
    String proofPhotoUrl;
    dynamic signatureUrl;
    String estimatedDistanceKm;
    String? actualDistanceKm;
    int estimatedTimeMinutes;
    int? actualTimeMinutes;
    DateTime? createdAt;
    DateTime? updatedAt;
    dynamic routeId;
    Farmer? farmer;
    Vendor? vendor;
    Crop? crop;
    Order? order;

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
        farmerId: _readIntNullable(json["farmer_id"]),
        cropId: _readIntNullable(json["crop_id"]),
        orderId: _readIntNullable(json["order_id"]),
        vendorId: _readIntNullable(json["vendor_id"]),
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
        otpVerifiedAt: _readDateTime(json, "otp_verified_at"),
        acceptedAt: _readDateTime(json, "accepted_at"),
        startedAt: _readDateTime(json, "started_at"),
        reachedAt: _readDateTime(json, "reached_at"),
        completedAt: _readDateTime(json, "completed_at"),
        expectedQuantityKg: _readString(json, "expected_quantity_kg"),
        actualQuantityKg: _readStringNullable(json["actual_quantity_kg"]),
        deliveryNotes: _readStringNullable(json["delivery_notes"]),
        failureReason: _readStringNullable(json["failure_reason"]),
        proofPhotoUrl: _readString(json, "proof_photo_url"),
        signatureUrl: json["signature_url"],
        estimatedDistanceKm: _readString(json, "estimated_distance_km"),
        actualDistanceKm: _readStringNullable(json["actual_distance_km"]),
        estimatedTimeMinutes: _readInt(json, "estimated_time_minutes"),
        actualTimeMinutes: _readIntNullable(json["actual_time_minutes"]),
        createdAt: _readDateTime(json, "created_at"),
        updatedAt: _readDateTime(json, "updated_at"),
        routeId: json["route_id"],
        farmer: _readFarmer(json["farmer"]),
        vendor: _readVendor(json["vendor"]),
        crop: _readCrop(json["crop"]),
        order: _readOrder(json["order"]),
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
        "scheduled_date": _formatDate(scheduledDate),
        "scheduled_time_slot": scheduledTimeSlot,
        "status": status,
        "otp_code": otpCode,
        "otp_verified_at": otpVerifiedAt?.toIso8601String(),
        "accepted_at": acceptedAt?.toIso8601String(),
        "started_at": startedAt?.toIso8601String(),
        "reached_at": reachedAt?.toIso8601String(),
        "completed_at": completedAt?.toIso8601String(),
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
        "farmer": farmer?.toJson(),
        "vendor": vendor?.toJson(),
        "crop": crop?.toJson(),
        "order": order?.toJson(),
    };
}

class Crop {
    int cropId;
    int farmerId;
    dynamic partitionId;
    int productId;
    String quantityKg;
    String grade;
    String expectedPricePerKg;
    DateTime? harvestDate;
    bool isReady;
    String cropPhotoUrl;
    String status;
    dynamic remarks;
    DateTime? createdAt;
    DateTime? updatedAt;
    Product product;

    Crop({
        required this.cropId,
        required this.farmerId,
        required this.partitionId,
        required this.productId,
        required this.quantityKg,
        required this.grade,
        required this.expectedPricePerKg,
        required this.harvestDate,
        required this.isReady,
        required this.cropPhotoUrl,
        required this.status,
        required this.remarks,
        required this.createdAt,
        required this.updatedAt,
        required this.product,
    });

    factory Crop.fromJson(Map<String, dynamic> json) => Crop(
        cropId: _readInt(json, "crop_id"),
        farmerId: _readInt(json, "farmer_id"),
        partitionId: json["partition_id"],
        productId: _readInt(json, "product_id"),
        quantityKg: _readString(json, "quantity_kg"),
        grade: _readString(json, "grade"),
        expectedPricePerKg: _readString(json, "expected_price_per_kg"),
        harvestDate: _readDateTime(json, "harvest_date"),
        isReady: _readBool(json, "is_ready"),
        cropPhotoUrl: _readString(json, "crop_photo_url"),
        status: _readString(json, "status"),
        remarks: json["remarks"],
        createdAt: _readDateTime(json, "created_at"),
        updatedAt: _readDateTime(json, "updated_at"),
        product: _readProduct(json["product"]),
    );

    Map<String, dynamic> toJson() => {
        "crop_id": cropId,
        "farmer_id": farmerId,
        "partition_id": partitionId,
        "product_id": productId,
        "quantity_kg": quantityKg,
        "grade": grade,
        "expected_price_per_kg": expectedPricePerKg,
        "harvest_date": _formatDate(harvestDate),
        "is_ready": isReady,
        "crop_photo_url": cropPhotoUrl,
        "status": status,
        "remarks": remarks,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "product": product.toJson(),
    };
}

class Product {
    String productName;

    Product({
        required this.productName,
    });

    factory Product.fromJson(Map<String, dynamic> json) => Product(
        productName: _readString(json, "product_name"),
    );

    Map<String, dynamic> toJson() => {
        "product_name": productName,
    };
}

class Farmer {
    String fullName;
    dynamic user;

    Farmer({
        required this.fullName,
        required this.user,
    });

    factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
        fullName: _readString(json, "full_name"),
        user: json["user"],
    );

    Map<String, dynamic> toJson() => {
        "full_name": fullName,
        "user": user,
    };
}

class Order {
    String orderNumber;
    String orderStatus;

    Order({
        required this.orderNumber,
        required this.orderStatus,
    });

    factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderNumber: _readString(json, "order_number"),
        orderStatus: _readString(json, "order_status"),
    );

    Map<String, dynamic> toJson() => {
        "order_number": orderNumber,
        "order_status": orderStatus,
    };
}

class Vendor {
    String shopName;
    String ownerName;
    dynamic user;

    Vendor({
        required this.shopName,
        required this.ownerName,
        required this.user,
    });

    factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
        shopName: _readString(json, "shop_name"),
        ownerName: _readString(json, "owner_name"),
        user: json["user"],
    );

    Map<String, dynamic> toJson() => {
        "shop_name": shopName,
        "owner_name": ownerName,
        "user": user,
    };
}

class Summary {
    int totalAssigned;
    int totalCompleted;
    int totalFailed;
    int totalCancelled;
    String rating;

    Summary({
        required this.totalAssigned,
        required this.totalCompleted,
        required this.totalFailed,
        required this.totalCancelled,
        required this.rating,
    });

    factory Summary.empty() => Summary(
        totalAssigned: 0,
        totalCompleted: 0,
        totalFailed: 0,
        totalCancelled: 0,
        rating: '',
    );

    factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        totalAssigned: _readInt(json, "total_assigned"),
        totalCompleted: _readInt(json, "total_completed"),
        totalFailed: _readInt(json, "total_failed"),
        totalCancelled: _readInt(json, "total_cancelled"),
        rating: _readString(json, "rating"),
    );

    Map<String, dynamic> toJson() => {
        "total_assigned": totalAssigned,
        "total_completed": totalCompleted,
        "total_failed": totalFailed,
        "total_cancelled": totalCancelled,
        "rating": rating,
    };
}

List<T> _readList<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) builder,
) {
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map(builder)
        .toList();
  }
  return <T>[];
}

Summary _readSummary(dynamic data) {
  if (data is Map<String, dynamic>) {
    return Summary.fromJson(data);
  }
  return Summary.empty();
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _readIntNullable(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value == null ? '' : value.toString();
}

String? _readStringNullable(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

bool _readBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

DateTime? _readDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  return "${date.year.toString().padLeft(4, '0')}-"
      "${date.month.toString().padLeft(2, '0')}-"
      "${date.day.toString().padLeft(2, '0')}";
}

Farmer? _readFarmer(dynamic data) {
  if (data is Map<String, dynamic>) {
    return Farmer.fromJson(data);
  }
  return null;
}

Vendor? _readVendor(dynamic data) {
  if (data is Map<String, dynamic>) {
    return Vendor.fromJson(data);
  }
  return null;
}

Crop? _readCrop(dynamic data) {
  if (data is Map<String, dynamic>) {
    return Crop.fromJson(data);
  }
  return null;
}

Order? _readOrder(dynamic data) {
  if (data is Map<String, dynamic>) {
    return Order.fromJson(data);
  }
  return null;
}

Product _readProduct(dynamic data) {
  if (data is Map<String, dynamic>) {
    return Product.fromJson(data);
  }
  return Product(productName: '');
}

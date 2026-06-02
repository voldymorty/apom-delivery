// To parse this JSON data, do
//
//     final taskDetailModel = taskDetailModelFromJson(jsonString);

import 'dart:convert';

TaskDetailModel taskDetailModelFromJson(String str) =>
    TaskDetailModel.fromJson(json.decode(str));

String taskDetailModelToJson(TaskDetailModel data) =>
    json.encode(data.toJson());

class TaskDetailModel {
  final bool success;
  final Data data;

  TaskDetailModel({
    required this.success,
    required this.data,
  });

  factory TaskDetailModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return TaskDetailModel(
      success: json['success'] == true,
      data:
          rawData is Map<String, dynamic> ? Data.fromJson(rawData) : Data.empty(),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'data': data.toJson(),
      };
}

class Data {
  final int deliveryId;
  final String deliveryNumber;
  final String deliveryType;
  final int farmerId;
  final int cropId;
  final dynamic orderId;
  final dynamic vendorId;
  final int deliveryPersonId;
  final dynamic assignedBy;
  final String pickupAddress;
  final String pickupLatitude;
  final String pickupLongitude;
  final String pickupContactName;
  final String pickupContactNumber;
  final String deliveryAddress;
  final String deliveryLatitude;
  final String deliveryLongitude;
  final String deliveryContactName;
  final String deliveryContactNumber;
  final DateTime? scheduledDate;
  final String scheduledTimeSlot;
  final String status;
  final String otpCode;
  final DateTime? otpVerifiedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? reachedAt;
  final DateTime? completedAt;
  final String expectedQuantityKg;
  final dynamic actualQuantityKg;
  final dynamic procurementAmount;
  final dynamic procurementPricePerKg;
  final String procurementStatus;
  final dynamic wastageQuantityKg;
  final dynamic acceptedQuantityKg;
  final dynamic finalProcurementAmount;
  final String deliveryNotes;
  final dynamic failureReason;
  final String proofPhotoUrl;
  final String signatureUrl;
  final String estimatedDistanceKm;
  final dynamic actualDistanceKm;
  final int estimatedTimeMinutes;
  final dynamic actualTimeMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final dynamic routeId;
  final Farmer farmer;
  final dynamic vendor;
  final Crop crop;
  final dynamic order;
  final List<StatusHistory> statusHistory;

  Data({
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
    required this.procurementAmount,
    required this.procurementPricePerKg,
    required this.procurementStatus,
    required this.wastageQuantityKg,
    required this.acceptedQuantityKg,
    required this.finalProcurementAmount,
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
    required this.statusHistory,
  });

  String get displayId {
    final trimmed = deliveryNumber.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return deliveryId > 0 ? deliveryId.toString() : '';
  }

  String get pickupTitle {
    final farmerName = farmer.fullName.trim();
    if (farmerName.isNotEmpty) return farmerName;
    final contactName = pickupContactName.trim();
    if (contactName.isNotEmpty) return contactName;
    return 'Pickup Location';
  }

  String get deliveryTitle {
    final contactName = deliveryContactName.trim();
    if (contactName.isNotEmpty) return contactName;
    final addressName = deliveryAddress.trim();
    if (addressName.isNotEmpty) return addressName;
    return 'Delivery Location';
  }

  factory Data.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['status_history'];
    final historyItems = historyRaw is List
        ? historyRaw
            .whereType<Map<String, dynamic>>()
            .map(StatusHistory.fromJson)
            .toList()
        : <StatusHistory>[];

    return Data(
      deliveryId: _readInt(json, 'delivery_id'),
      deliveryNumber: _readString(json, 'delivery_number'),
      deliveryType: _readString(json, 'delivery_type'),
      farmerId: _readInt(json, 'farmer_id'),
      cropId: _readInt(json, 'crop_id'),
      orderId: json['order_id'],
      vendorId: json['vendor_id'],
      deliveryPersonId: _readInt(json, 'delivery_person_id'),
      assignedBy: json['assigned_by'],
      pickupAddress: _readString(json, 'pickup_address'),
      pickupLatitude: _readString(json, 'pickup_latitude'),
      pickupLongitude: _readString(json, 'pickup_longitude'),
      pickupContactName: _readString(json, 'pickup_contact_name'),
      pickupContactNumber: _readString(json, 'pickup_contact_number'),
      deliveryAddress: _readString(json, 'delivery_address'),
      deliveryLatitude: _readString(json, 'delivery_latitude'),
      deliveryLongitude: _readString(json, 'delivery_longitude'),
      deliveryContactName: _readString(json, 'delivery_contact_name'),
      deliveryContactNumber: _readString(json, 'delivery_contact_number'),
      scheduledDate: _readDateTime(json, 'scheduled_date'),
      scheduledTimeSlot: _readString(json, 'scheduled_time_slot'),
      status: _readString(json, 'status'),
      otpCode: _readString(json, 'otp_code'),
      otpVerifiedAt: _readDateTime(json, 'otp_verified_at'),
      acceptedAt: _readDateTime(json, 'accepted_at'),
      startedAt: _readDateTime(json, 'started_at'),
      reachedAt: _readDateTime(json, 'reached_at'),
      completedAt: _readDateTime(json, 'completed_at'),
      expectedQuantityKg: _readString(json, 'expected_quantity_kg'),
      actualQuantityKg: json['actual_quantity_kg'],
      procurementAmount: json['procurement_amount'],
      procurementPricePerKg: json['procurement_price_per_kg'],
      procurementStatus: _readString(json, 'procurement_status'),
      wastageQuantityKg: json['wastage_quantity_kg'],
      acceptedQuantityKg: json['accepted_quantity_kg'],
      finalProcurementAmount: json['final_procurement_amount'],
      deliveryNotes: _readString(json, 'delivery_notes'),
      failureReason: json['failure_reason'],
      proofPhotoUrl: _readString(json, 'proof_photo_url'),
      signatureUrl: _readString(json, 'signature_url'),
      estimatedDistanceKm: _readString(json, 'estimated_distance_km'),
      actualDistanceKm: json['actual_distance_km'],
      estimatedTimeMinutes: _readInt(json, 'estimated_time_minutes'),
      actualTimeMinutes: json['actual_time_minutes'],
      createdAt: _readDateTime(json, 'created_at'),
      updatedAt: _readDateTime(json, 'updated_at'),
      routeId: json['route_id'],
      farmer: _readFarmer(json['farmer']),
      vendor: json['vendor'],
      crop: _readCrop(json['crop']),
      order: json['order'],
      statusHistory: historyItems,
    );
  }

  factory Data.empty() => Data(
        deliveryId: 0,
        deliveryNumber: '',
        deliveryType: '',
        farmerId: 0,
        cropId: 0,
        orderId: null,
        vendorId: null,
        deliveryPersonId: 0,
        assignedBy: null,
        pickupAddress: '',
        pickupLatitude: '',
        pickupLongitude: '',
        pickupContactName: '',
        pickupContactNumber: '',
        deliveryAddress: '',
        deliveryLatitude: '',
        deliveryLongitude: '',
        deliveryContactName: '',
        deliveryContactNumber: '',
        scheduledDate: null,
        scheduledTimeSlot: '',
        status: '',
        otpCode: '',
        otpVerifiedAt: null,
        acceptedAt: null,
        startedAt: null,
        reachedAt: null,
        completedAt: null,
        expectedQuantityKg: '',
        actualQuantityKg: null,
        procurementAmount: null,
        procurementPricePerKg: null,
        procurementStatus: '',
        wastageQuantityKg: null,
        acceptedQuantityKg: null,
        finalProcurementAmount: null,
        deliveryNotes: '',
        failureReason: null,
        proofPhotoUrl: '',
        signatureUrl: '',
        estimatedDistanceKm: '',
        actualDistanceKm: null,
        estimatedTimeMinutes: 0,
        actualTimeMinutes: null,
        createdAt: null,
        updatedAt: null,
        routeId: null,
        farmer: Farmer.empty(),
        vendor: null,
        crop: Crop.empty(),
        order: null,
        statusHistory: const [],
      );

  Map<String, dynamic> toJson() => {
        'delivery_id': deliveryId,
        'delivery_number': deliveryNumber,
        'delivery_type': deliveryType,
        'farmer_id': farmerId,
        'crop_id': cropId,
        'order_id': orderId,
        'vendor_id': vendorId,
        'delivery_person_id': deliveryPersonId,
        'assigned_by': assignedBy,
        'pickup_address': pickupAddress,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'pickup_contact_name': pickupContactName,
        'pickup_contact_number': pickupContactNumber,
        'delivery_address': deliveryAddress,
        'delivery_latitude': deliveryLatitude,
        'delivery_longitude': deliveryLongitude,
        'delivery_contact_name': deliveryContactName,
        'delivery_contact_number': deliveryContactNumber,
        'scheduled_date': _formatDate(scheduledDate),
        'scheduled_time_slot': scheduledTimeSlot,
        'status': status,
        'otp_code': otpCode,
        'otp_verified_at': otpVerifiedAt?.toIso8601String(),
        'accepted_at': acceptedAt?.toIso8601String(),
        'started_at': startedAt?.toIso8601String(),
        'reached_at': reachedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'expected_quantity_kg': expectedQuantityKg,
        'actual_quantity_kg': actualQuantityKg,
        'procurement_amount': procurementAmount,
        'procurement_price_per_kg': procurementPricePerKg,
        'procurement_status': procurementStatus,
        'wastage_quantity_kg': wastageQuantityKg,
        'accepted_quantity_kg': acceptedQuantityKg,
        'final_procurement_amount': finalProcurementAmount,
        'delivery_notes': deliveryNotes,
        'failure_reason': failureReason,
        'proof_photo_url': proofPhotoUrl,
        'signature_url': signatureUrl,
        'estimated_distance_km': estimatedDistanceKm,
        'actual_distance_km': actualDistanceKm,
        'estimated_time_minutes': estimatedTimeMinutes,
        'actual_time_minutes': actualTimeMinutes,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'route_id': routeId,
        'farmer': farmer.toJson(),
        'vendor': vendor,
        'crop': crop.toJson(),
        'order': order,
        'status_history':
            List<dynamic>.from(statusHistory.map((x) => x.toJson())),
      };
}

class Crop {
  final int cropId;
  final int farmerId;
  final dynamic partitionId;
  final int productId;
  final String quantityKg;
  final String grade;
  final String expectedPricePerKg;
  final DateTime? harvestDate;
  final bool isReady;
  final String cropPhotoUrl;
  final String status;
  final dynamic remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Product product;

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
        cropId: _readInt(json, 'crop_id'),
        farmerId: _readInt(json, 'farmer_id'),
        partitionId: json['partition_id'],
        productId: _readInt(json, 'product_id'),
        quantityKg: _readString(json, 'quantity_kg'),
        grade: _readString(json, 'grade'),
        expectedPricePerKg: _readString(json, 'expected_price_per_kg'),
        harvestDate: _readDateTime(json, 'harvest_date'),
        isReady: _readBool(json, 'is_ready'),
        cropPhotoUrl: _readString(json, 'crop_photo_url'),
        status: _readString(json, 'status'),
        remarks: json['remarks'],
        createdAt: _readDateTime(json, 'created_at'),
        updatedAt: _readDateTime(json, 'updated_at'),
        product: _readProduct(json['product']),
      );

  factory Crop.empty() => Crop(
        cropId: 0,
        farmerId: 0,
        partitionId: null,
        productId: 0,
        quantityKg: '',
        grade: '',
        expectedPricePerKg: '',
        harvestDate: null,
        isReady: false,
        cropPhotoUrl: '',
        status: '',
        remarks: null,
        createdAt: null,
        updatedAt: null,
        product: Product.empty(),
      );

  Map<String, dynamic> toJson() => {
        'crop_id': cropId,
        'farmer_id': farmerId,
        'partition_id': partitionId,
        'product_id': productId,
        'quantity_kg': quantityKg,
        'grade': grade,
        'expected_price_per_kg': expectedPricePerKg,
        'harvest_date': _formatDate(harvestDate),
        'is_ready': isReady,
        'crop_photo_url': cropPhotoUrl,
        'status': status,
        'remarks': remarks,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'product': product.toJson(),
      };
}

class Product {
  final int productId;
  final int categoryId;
  final String productName;
  final String productCode;
  final dynamic description;
  final String unit;
  final dynamic imageUrl;
  final bool isSeasonal;
  final int seasonStartMonth;
  final int seasonEndMonth;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.productId,
    required this.categoryId,
    required this.productName,
    required this.productCode,
    required this.description,
    required this.unit,
    required this.imageUrl,
    required this.isSeasonal,
    required this.seasonStartMonth,
    required this.seasonEndMonth,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        productId: _readInt(json, 'product_id'),
        categoryId: _readInt(json, 'category_id'),
        productName: _readString(json, 'product_name'),
        productCode: _readString(json, 'product_code'),
        description: json['description'],
        unit: _readString(json, 'unit'),
        imageUrl: json['image_url'],
        isSeasonal: _readBool(json, 'is_seasonal'),
        seasonStartMonth: _readInt(json, 'season_start_month'),
        seasonEndMonth: _readInt(json, 'season_end_month'),
        isActive: _readBool(json, 'is_active'),
        createdAt: _readDateTime(json, 'created_at'),
        updatedAt: _readDateTime(json, 'updated_at'),
      );

  factory Product.empty() => Product(
        productId: 0,
        categoryId: 0,
        productName: '',
        productCode: '',
        description: null,
        unit: '',
        imageUrl: null,
        isSeasonal: false,
        seasonStartMonth: 0,
        seasonEndMonth: 0,
        isActive: false,
        createdAt: null,
        updatedAt: null,
      );

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'category_id': categoryId,
        'product_name': productName,
        'product_code': productCode,
        'description': description,
        'unit': unit,
        'image_url': imageUrl,
        'is_seasonal': isSeasonal,
        'season_start_month': seasonStartMonth,
        'season_end_month': seasonEndMonth,
        'is_active': isActive,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

class Farmer {
  final int farmerId;
  final int userId;
  final String fullName;
  final dynamic aadharNumber;
  final String farmName;
  final String locationAddress;
  final int stateId;
  final int districtId;
  final int cityId;
  final String pincode;
  final String latitude;
  final String longitude;
  final String totalLand;
  final String landUnit;
  final String allocatedLand;
  final String availableLand;
  final String profilePhotoUrl;
  final String landPhotoUrl;
  final int totalSupplies;
  final String totalEarnings;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final dynamic user;

  Farmer({
    required this.farmerId,
    required this.userId,
    required this.fullName,
    required this.aadharNumber,
    required this.farmName,
    required this.locationAddress,
    required this.stateId,
    required this.districtId,
    required this.cityId,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.totalLand,
    required this.landUnit,
    required this.allocatedLand,
    required this.availableLand,
    required this.profilePhotoUrl,
    required this.landPhotoUrl,
    required this.totalSupplies,
    required this.totalEarnings,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
        farmerId: _readInt(json, 'farmer_id'),
        userId: _readInt(json, 'user_id'),
        fullName: _readString(json, 'full_name'),
        aadharNumber: json['aadhar_number'],
        farmName: _readString(json, 'farm_name'),
        locationAddress: _readString(json, 'location_address'),
        stateId: _readInt(json, 'state_id'),
        districtId: _readInt(json, 'district_id'),
        cityId: _readInt(json, 'city_id'),
        pincode: _readString(json, 'pincode'),
        latitude: _readString(json, 'latitude'),
        longitude: _readString(json, 'longitude'),
        totalLand: _readString(json, 'total_land'),
        landUnit: _readString(json, 'land_unit'),
        allocatedLand: _readString(json, 'allocated_land'),
        availableLand: _readString(json, 'available_land'),
        profilePhotoUrl: _readString(json, 'profile_photo_url'),
        landPhotoUrl: _readString(json, 'land_photo_url'),
        totalSupplies: _readInt(json, 'total_supplies'),
        totalEarnings: _readString(json, 'total_earnings'),
        createdAt: _readDateTime(json, 'created_at'),
        updatedAt: _readDateTime(json, 'updated_at'),
        user: json['user'],
      );

  factory Farmer.empty() => Farmer(
        farmerId: 0,
        userId: 0,
        fullName: '',
        aadharNumber: null,
        farmName: '',
        locationAddress: '',
        stateId: 0,
        districtId: 0,
        cityId: 0,
        pincode: '',
        latitude: '',
        longitude: '',
        totalLand: '',
        landUnit: '',
        allocatedLand: '',
        availableLand: '',
        profilePhotoUrl: '',
        landPhotoUrl: '',
        totalSupplies: 0,
        totalEarnings: '',
        createdAt: null,
        updatedAt: null,
        user: null,
      );

  Map<String, dynamic> toJson() => {
        'farmer_id': farmerId,
        'user_id': userId,
        'full_name': fullName,
        'aadhar_number': aadharNumber,
        'farm_name': farmName,
        'location_address': locationAddress,
        'state_id': stateId,
        'district_id': districtId,
        'city_id': cityId,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        'total_land': totalLand,
        'land_unit': landUnit,
        'allocated_land': allocatedLand,
        'available_land': availableLand,
        'profile_photo_url': profilePhotoUrl,
        'land_photo_url': landPhotoUrl,
        'total_supplies': totalSupplies,
        'total_earnings': totalEarnings,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'user': user,
      };
}

class StatusHistory {
  final int historyId;
  final int deliveryId;
  final String oldStatus;
  final String newStatus;
  final dynamic changedBy;
  final dynamic latitude;
  final dynamic longitude;
  final dynamic remarks;
  final dynamic photoUrl;
  final DateTime? createdAt;

  StatusHistory({
    required this.historyId,
    required this.deliveryId,
    required this.oldStatus,
    required this.newStatus,
    required this.changedBy,
    required this.latitude,
    required this.longitude,
    required this.remarks,
    required this.photoUrl,
    required this.createdAt,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) => StatusHistory(
        historyId: _readInt(json, 'history_id'),
        deliveryId: _readInt(json, 'delivery_id'),
        oldStatus: _readString(json, 'old_status'),
        newStatus: _readString(json, 'new_status'),
        changedBy: json['changed_by'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        remarks: json['remarks'],
        photoUrl: json['photo_url'],
        createdAt: _readDateTime(json, 'created_at'),
      );

  Map<String, dynamic> toJson() => {
        'history_id': historyId,
        'delivery_id': deliveryId,
        'old_status': oldStatus,
        'new_status': newStatus,
        'changed_by': changedBy,
        'latitude': latitude,
        'longitude': longitude,
        'remarks': remarks,
        'photo_url': photoUrl,
        'created_at': createdAt?.toIso8601String(),
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

Farmer _readFarmer(dynamic data) {
  if (data is Map<String, dynamic>) {
    return Farmer.fromJson(data);
  }
  return Farmer.empty();
}

Crop _readCrop(dynamic data) {
  if (data is Map<String, dynamic>) {
    return Crop.fromJson(data);
  }
  return Crop.empty();
}

Product _readProduct(dynamic data) {
  if (data is Map<String, dynamic>) {
    return Product.fromJson(data);
  }
  return Product.empty();
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  return "${date.year.toString().padLeft(4, '0')}-"
      "${date.month.toString().padLeft(2, '0')}-"
      "${date.day.toString().padLeft(2, '0')}";
}

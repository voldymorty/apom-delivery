import 'dart:convert';
import 'dart:io';

import 'package:delivery/config/api_config.dart';
import 'package:delivery/global/image_compress.dart';
import 'package:delivery/models/task_detail_model.dart';
import 'package:delivery/utils/auth_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class TaskDetailRepository {
  Future<TaskDetailModel> fetchTaskDetail({
    required String taskId,
  }) async {
    final url = ApiConfig.getTaskDetailUrl(taskId: taskId);
    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load task detail (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid task detail response format');
    }

    return TaskDetailModel.fromJson(decoded);
  }

  Future<ProofPhotoUploadResponse> uploadProofPhoto({
    required String taskId,
    required File imageFile,
    double? latitude,
    double? longitude,
  }) async {
    final trimmedId = taskId.trim();
    if (trimmedId.isEmpty) {
      throw Exception('Missing task id');
    }
    final url = ApiConfig.getTaskPostnUrl(taskId: trimmedId);
    final token = await AuthClient.getAuthToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }

    final File? compressedFile =
        await ImageCompressHelper.compressAndConvertToPng(imageFile);
    if (compressedFile == null) {
      throw Exception('Unable to process image. Please try again.');
    }
    final File uploadFile = compressedFile;

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';

    if (latitude != null) {
      request.fields['latitude'] = latitude.toString();
    }
    if (longitude != null) {
      request.fields['longitude'] = longitude.toString();
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'proof_photo',
        uploadFile.path,
        filename: p.basename(uploadFile.path),
        contentType: MediaType('image', 'png'),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to upload proof photo (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid proof photo response format');
    }

    final result = ProofPhotoUploadResponse.fromJson(decoded);
    if (!result.success) {
      final message = result.message.trim();
      throw Exception(message.isNotEmpty ? message : 'Proof upload failed');
    }
    return result;
  }

  Future<bool> sendOtpSms({
    required String mobileNumber,
    required String otp,
  }) async {
    final normalizedMobile = mobileNumber.trim();
    final normalizedOtp = otp.trim();
    if (normalizedMobile.isEmpty || normalizedOtp.isEmpty) {
      return false;
    }

    const smsToken = "87c13d427e12b47a9f6535878483d96a";
    const credit = "2";
    const sender = "STSCBE";
    final messageText =
        "OTP for your Sai Techno Solutions Login Verification is $normalizedOtp. Do Not Share this with anyone. - Sai Techno Solutions";
    final encodedMessage = Uri.encodeComponent(messageText);
    final smsUrl =
        "http://sms.saitechnosolutions.net/sendsms/?token=$smsToken&credit=$credit&sender=$sender&message=$encodedMessage&number=$normalizedMobile";

    final response = await http.get(Uri.parse(smsUrl));
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<VerifyOtpResponse> verifyTaskOtp({
    required String taskId,
    required String otp,
    String? deliveryType,
    double? actualQuantityKg,
    double? procurementAmount,
  }) async {
    final trimmedId = taskId.trim();
    if (trimmedId.isEmpty) {
      throw Exception('Missing task id');
    }
    final trimmedOtp = otp.trim();
    if (trimmedOtp.isEmpty) {
      throw Exception('OTP is required');
    }

    final url = ApiConfig.getTaskVerifyOtpUrl(taskId: trimmedId);
    final body = <String, dynamic>{'otp_code': trimmedOtp};
    if (actualQuantityKg != null && actualQuantityKg > 0) {
      body['actual_quantity_kg'] = actualQuantityKg;
    }
    if (procurementAmount != null && procurementAmount > 0) {
      body['procurement_amount'] = procurementAmount;
    }
    final response = await AuthClient.patchWithAuth(url, body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to verify OTP (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid verify OTP response format');
    }

    final result = VerifyOtpResponse.fromJson(decoded);
    if (!result.success) {
      final message = result.message.trim();
      throw Exception(message.isNotEmpty ? message : 'OTP verification failed');
    }

    return result;
  }

  Future<UpdateStatusResponse> updateTaskStatus({
    required String taskId,
    required String status,
    String? deliveryType,
  }) async {
    final trimmedId = taskId.trim();
    if (trimmedId.isEmpty) {
      throw Exception('Missing task id');
    }
    final trimmedStatus = status.trim();

    if (trimmedStatus.isEmpty) {
      throw Exception('Status is required');
    }

    final url = ApiConfig.getTaskStatusUrl(taskId: trimmedId);
    final response = await AuthClient.patchWithAuth(
      url,
      {'status': trimmedStatus},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to update status (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid status response format');
    }

    final result = UpdateStatusResponse.fromJson(decoded);
    if (!result.success) {
      final message = result.message.trim();
      throw Exception(message.isNotEmpty ? message : 'Status update failed');
    }
    return result;
  }
}

class TaskDetailController
    extends StateNotifier<AsyncValue<TaskDetailModel>> {
  TaskDetailController(this._repository, {required this.taskId})
      : super(const AsyncValue.loading()) {
    fetch();
  }

  final TaskDetailRepository _repository;
  final String taskId;

  Future<TaskDetailModel?> fetch() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.fetchTaskDetail(taskId: taskId);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<ProofPhotoUploadResponse> uploadProofPhoto({
    required File imageFile,
    double? latitude,
    double? longitude,
  }) {
    return _repository.uploadProofPhoto(
      taskId: taskId,
      imageFile: imageFile,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<bool> sendOtpSms({
    required String mobileNumber,
    required String otp,
  }) {
    return _repository.sendOtpSms(
      mobileNumber: mobileNumber,
      otp: otp,
    );
  }

  Future<VerifyOtpResponse> verifyTaskOtp({
    required String otp,
    double? actualQuantityKg,
    double? procurementAmount,
  }) async {
    final deliveryType = state.valueOrNull?.data.deliveryType;
    final result = await _repository.verifyTaskOtp(
      taskId: taskId,
      otp: otp,
      deliveryType: deliveryType,
      actualQuantityKg: actualQuantityKg,
      procurementAmount: procurementAmount,
    );
    await fetch();
    return result;
  }

  Future<UpdateStatusResponse> updateTaskStatus({
    required String status,
  }) {
    final deliveryType = state.valueOrNull?.data.deliveryType;
    return _repository.updateTaskStatus(
      taskId: taskId,
      status: status,
      deliveryType: deliveryType,
    );
  }
}

final taskDetailRepositoryProvider = Provider<TaskDetailRepository>(
  (ref) => TaskDetailRepository(),
);

final taskDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<TaskDetailController, AsyncValue<TaskDetailModel>, String>(
  (ref, taskId) =>
      TaskDetailController(ref.watch(taskDetailRepositoryProvider), taskId: taskId),
);

class ProofPhotoUploadResponse {
  final bool success;
  final String message;
  final String proofPhotoUrl;
  final String otpCode;
  final String deliveryType;

  const ProofPhotoUploadResponse({
    required this.success,
    required this.message,
    required this.proofPhotoUrl,
    required this.otpCode,
    required this.deliveryType,
  });

  factory ProofPhotoUploadResponse.fromJson(Map<String, dynamic> json) {
    return ProofPhotoUploadResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      proofPhotoUrl: json['proof_photo_url']?.toString() ?? '',
      otpCode: json['otp_code']?.toString() ?? '',
      deliveryType: json['delivery_type']?.toString() ?? '',
    );
  }
}

class VerifyOtpResponse {
  final bool success;
  final String message;

  const VerifyOtpResponse({
    required this.success,
    required this.message,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}

class UpdateStatusResponse {
  final bool success;
  final String message;

  const UpdateStatusResponse({
    required this.success,
    required this.message,
  });

  factory UpdateStatusResponse.fromJson(Map<String, dynamic> json) {
    return UpdateStatusResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}

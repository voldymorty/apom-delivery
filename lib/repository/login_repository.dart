import 'dart:convert';

import 'package:delivery/config/api_config.dart';
import 'package:delivery/utils/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class LoginResponse {
  final bool success;
  final String? token;
  final Map<String, dynamic> user;
  final Map<String, dynamic> deliveryProfile;
  final String? message;

  const LoginResponse({
    required this.success,
    required this.token,
    required this.user,
    required this.deliveryProfile,
    required this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true,
      token: json['token'] as String?,
      user: (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      deliveryProfile:
          (json['delivery_profile'] as Map?)?.cast<String, dynamic>() ??
              const {},
      message: json['message']?.toString(),
    );
  }
}

class LoginException implements Exception {
  final String message;

  const LoginException(this.message);

  @override
  String toString() => message;
}

class LoginRepository {
  Future<LoginResponse> login({
    required String mobile,
    required String password,
  }) async {
    final url = ApiConfig.getAuthLoginUrl();
    final response = await http.post(
      Uri.parse(url),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile_number': mobile, 'password': password}),
    );

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          data['message']?.toString() ??
          'Login failed (${response.statusCode})';
      throw LoginException(message);
    }

    final result = LoginResponse.fromJson(data);

    if (result.success && (result.token?.isNotEmpty ?? false)) {
      await TokenStorage.saveToken(accessToken: result.token!);
    }

    return result;
  }
}

class LoginController extends StateNotifier<AsyncValue<LoginResponse?>> {
  LoginController(this._repository) : super(const AsyncValue.data(null));

  final LoginRepository _repository;

  Future<LoginResponse?> login({
    required String mobile,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.login(
        mobile: mobile,
        password: password,
      );
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final loginRepositoryProvider = Provider<LoginRepository>(
  (ref) => LoginRepository(),
);

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<LoginResponse?>>(
      (ref) => LoginController(ref.watch(loginRepositoryProvider)),
    );

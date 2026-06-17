import 'dart:convert';

import 'package:delivery/config/api_config.dart';
import 'package:delivery/models/profile_model.dart';
import 'package:delivery/utils/auth_client.dart';
import 'package:delivery/utils/token_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileRepository {
  Future<ProfileModel> fetchProfile() async {
    final url = ApiConfig.getProfileUrl();
    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load profile (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid profile response format');
    }

    return ProfileModel.fromJson(decoded);
  }

  Future<void> logout() async {
    final url = ApiConfig.getLogoutUrl();
    try {
      await AuthClient.postWithAuth(url, {});
    } catch (e) {
      if (kDebugMode) {
        print('Error during API logout: $e');
      }
    } finally {
      await TokenStorage.clearToken();
    }
  }
}

class ProfileController extends StateNotifier<AsyncValue<ProfileModel>> {
  ProfileController(this._repository) : super(const AsyncValue.loading()) {
    fetch();
  }

  final ProfileRepository _repository;

  Future<ProfileModel?> fetch() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.fetchProfile();
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

final profileControllerProvider =
    StateNotifierProvider.autoDispose<ProfileController, AsyncValue<ProfileModel>>(
      (ref) => ProfileController(ref.watch(profileRepositoryProvider)),
    );

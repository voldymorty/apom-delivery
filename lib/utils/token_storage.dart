import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken({
    required String accessToken,
  }) async {
    try {
      await _storage.write(key: 'accessToken', value: accessToken);

      if (kDebugMode) {
        print('Access token: $accessToken');
        print('Access token saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving token: $e');
      }
      rethrow;
    }
  }

  static Future<String?> getToken() async {
    try {
      final accessToken = await _storage.read(key: 'accessToken');

      if (kDebugMode) {
        print('Access token retrieved: $accessToken');
      }

      return accessToken;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting token: $e');
      }
      return null;
    }
  }

  static Future<void> clearToken() async {
    try {
      await _storage.delete(key: 'accessToken');

      if (kDebugMode) {
        print('Token cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing token: $e');
      }
    }
  }

  static Future<bool> hasValidToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating token: $e');
      }
      return false;
    }
  }
}
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppStorage {
  static const _storage = FlutterSecureStorage();
  static const _onboardingSeenKey = 'onboarding_seen';
  static const _profileCompleteKey = 'profile_complete';
  static const _lastMobileKey = 'last_mobile';

  static Future<void> setOnboardingSeen(bool seen) async {
    await _storage.write(key: _onboardingSeenKey, value: seen ? "1" : "0");
  }

  static Future<bool> hasSeenOnboarding() async {
    final value = await _storage.read(key: _onboardingSeenKey);
    return value == "1" || value?.toLowerCase() == "true";
  }

  static Future<void> setProfileComplete(bool complete) async {
    await _storage.write(key: _profileCompleteKey, value: complete ? "1" : "0");
  }

  static Future<bool?> getProfileComplete() async {
    final value = await _storage.read(key: _profileCompleteKey);
    if (value == null) return null;
    return value == "1" || value.toLowerCase() == "true";
  }

  static Future<void> setLastMobile(String mobile) async {
    await _storage.write(key: _lastMobileKey, value: mobile);
  }

  static Future<String?> getLastMobile() async {
    return await _storage.read(key: _lastMobileKey);
  }

  static Future<void> clearProfileCache() async {
    await _storage.delete(key: _profileCompleteKey);
    await _storage.delete(key: _lastMobileKey);
  }
}

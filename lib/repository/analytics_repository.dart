import 'dart:convert';

import 'package:delivery/config/api_config.dart';
import 'package:delivery/models/analytics_graph_model.dart';
import 'package:delivery/models/dashboard_model.dart';
import 'package:delivery/utils/auth_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsRepository {
  Future<DashboardModel> fetchDashboard() async {
    final url = ApiConfig.getDashboardUrl();
    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load dashboard summary (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid dashboard response format');
    }

    return DashboardModel.fromJson(decoded);
  }

  Future<AnalyticsModel> fetchWeeklyPerformance() async {
    final url = ApiConfig.getWeeklyPerformanceUrl();
    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load weekly performance (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid weekly performance response format');
    }

    return AnalyticsModel.fromJson(decoded);
  }
}

class AnalyticsController extends StateNotifier<AsyncValue<DashboardModel>> {
  AnalyticsController(this._repository) : super(const AsyncValue.loading()) {
    fetch();
  }

  final AnalyticsRepository _repository;

  Future<DashboardModel?> fetch() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.fetchDashboard();
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

class WeeklyPerformanceController extends StateNotifier<AsyncValue<AnalyticsModel>> {
  WeeklyPerformanceController(this._repository)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  final AnalyticsRepository _repository;

  Future<AnalyticsModel?> fetch() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.fetchWeeklyPerformance();
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(),
);

final analyticsControllerProvider =
    StateNotifierProvider.autoDispose<AnalyticsController, AsyncValue<DashboardModel>>(
  (ref) => AnalyticsController(ref.watch(analyticsRepositoryProvider)),
);

final weeklyPerformanceControllerProvider = StateNotifierProvider.autoDispose<
    WeeklyPerformanceController, AsyncValue<AnalyticsModel>>(
  (ref) => WeeklyPerformanceController(ref.watch(analyticsRepositoryProvider)),
);

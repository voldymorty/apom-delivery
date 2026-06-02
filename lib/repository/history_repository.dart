import 'dart:convert';

import 'package:delivery/config/api_config.dart';
import 'package:delivery/models/history_model.dart';
import 'package:delivery/utils/auth_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryRepository {
  Future<HistoryModel> fetchHistory() async {
    final url = ApiConfig.getHistoryUrl();
    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load history (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid history response format');
    }

    return HistoryModel.fromJson(decoded);
  }
}

class HistoryController extends StateNotifier<AsyncValue<HistoryModel>> {
  HistoryController(this._repository) : super(const AsyncValue.loading()) {
    fetch();
  }

  final HistoryRepository _repository;

  Future<HistoryModel?> fetch() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.fetchHistory();
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(),
);

final historyControllerProvider =
    StateNotifierProvider.autoDispose<HistoryController, AsyncValue<HistoryModel>>(
      (ref) => HistoryController(ref.watch(historyRepositoryProvider)),
    );

import 'dart:convert';

import 'package:delivery/config/api_config.dart';
import 'package:delivery/models/history_model.dart';
import 'package:delivery/utils/auth_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Filter model ─────────────────────────────────────────────────────────────

class HistoryFilter {
  final String? type;   // 'pickup' | 'delivery' | null (all)
  final String? status; // see statuses below | null (all)
  final String? date;   // 'yyyy-MM-dd' | null
  final int page;
  final int limit;

  const HistoryFilter({
    this.type,
    this.status,
    this.date,
    this.page = 1,
    this.limit = 20,
  });

  HistoryFilter copyWith({
    Object? type = _sentinel,
    Object? status = _sentinel,
    Object? date = _sentinel,
    int? page,
    int? limit,
  }) {
    return HistoryFilter(
      type:   type   == _sentinel ? this.type   : type   as String?,
      status: status == _sentinel ? this.status : status as String?,
      date:   date   == _sentinel ? this.date   : date   as String?,
      page:   page   ?? this.page,
      limit:  limit  ?? this.limit,
    );
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'page':  page.toString(),
      'limit': limit.toString(),
    };
    if (type   != null) params['type']   = type!;
    if (status != null) params['status'] = status!;
    if (date   != null) params['date']   = date!;
    return params;
  }

  static const _sentinel = Object();
}

// ─── Repository ───────────────────────────────────────────────────────────────

class HistoryRepository {
  Future<HistoryModel> fetchHistory([HistoryFilter? filter]) async {
    final baseUrl = ApiConfig.getHistoryUrl();
    final params  = (filter ?? const HistoryFilter()).toQueryParams();

    final uri = Uri.parse(baseUrl).replace(
      queryParameters: params,
    );

    final response = await AuthClient.getWithAuth(uri.toString());

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

// ─── Controller ───────────────────────────────────────────────────────────────

class HistoryController
    extends StateNotifier<AsyncValue<HistoryModel>> {
  HistoryController(this._repository) : super(const AsyncValue.loading()) {
    fetch();
  }

  final HistoryRepository _repository;
  HistoryFilter _filter = const HistoryFilter(status: 'completed');

  HistoryFilter get currentFilter => _filter;

  Future<HistoryModel?> fetch([HistoryFilter? filter]) async {
    if (filter != null) _filter = filter;
    state = const AsyncValue.loading();
    try {
      final result = await _repository.fetchHistory(_filter);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> applyFilter(HistoryFilter filter) => fetch(filter);
}

// ─── Providers ────────────────────────────────────────────────────────────────

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(),
);

final historyControllerProvider = StateNotifierProvider.autoDispose<
    HistoryController, AsyncValue<HistoryModel>>(
  (ref) => HistoryController(ref.watch(historyRepositoryProvider)),
);
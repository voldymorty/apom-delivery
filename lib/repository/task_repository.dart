import 'dart:convert';

import 'package:delivery/config/api_config.dart';
import 'package:delivery/models/task_modeld.dart';
import 'package:delivery/utils/auth_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskRepository {
  Future<TaskModel> fetchTasks({
    required String type,
    String? status,
    DateTime? date,
    int page = 1,
    int limit = 20,
  }) async {
    final dateString = date != null
        ? '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}'
        : null;

    final url = ApiConfig.getTaskUrl(
      type: type,
      status: status,
      date: dateString,
      page: page,
      limit: limit,
    );

    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load tasks (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid tasks response format');
    }

    return TaskModel.fromJson(decoded);
  }
}

class TaskController extends StateNotifier<AsyncValue<TaskModel>> {
  TaskController(this._repository) : super(const AsyncValue.loading());

  final TaskRepository _repository;

  Future<TaskModel?> fetchForTab({
    required int activeTab,
    DateTime? date,
    int page = 1,
    int limit = 20,
  }) async {
    state = const AsyncValue.loading();
    try {
      final type =
          activeTab == 1 ? TaskTypeValue.pickup : TaskTypeValue.delivery;
      const visibleStatuses = [
        TaskStatusValue.assigned,
        TaskStatusValue.accepted,
        TaskStatusValue.inTransit,
        TaskStatusValue.reached,
      ];

      final results = await Future.wait(
        visibleStatuses.map(
          (status) => _repository.fetchTasks(
            type: type,
            status: status,
            date: date,
            page: page,
            limit: limit,
          ),
        ),
      );

      final merged = _mergeTaskModels(results);
      state = AsyncValue.data(merged);
      return merged;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  TaskModel _mergeTaskModels(List<TaskModel> models) {
    final items = <Datum>[];
    final seenIds = <int>{};

    for (final model in models) {
      for (final task in model.data) {
        if (seenIds.add(task.deliveryId)) {
          items.add(task);
        }
      }
    }

    items.sort(_compareTaskPriority);

    return TaskModel(
      success: true,
      data: items,
      total: items.length,
      page: 1,
      limit: items.length,
      totalPages: 1,
    );
  }

  int _compareTaskPriority(Datum a, Datum b) {
    final priority = <String, int>{
      TaskStatusValue.reached: 0,
      TaskStatusValue.inTransit: 1,
      TaskStatusValue.accepted: 2,
      TaskStatusValue.assigned: 3,
      TaskStatusValue.completed: 4,
      TaskStatusValue.failed: 5,
      TaskStatusValue.cancelled: 6,
    };

    final aStatus = a.status.trim().toLowerCase();
    final bStatus = b.status.trim().toLowerCase();
    final aRank = priority[aStatus] ?? 99;
    final bRank = priority[bStatus] ?? 99;
    if (aRank != bRank) return aRank.compareTo(bRank);

    return a.deliveryId.compareTo(b.deliveryId);
  }
}

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(),
);

final taskControllerProvider =
    StateNotifierProvider<TaskController, AsyncValue<TaskModel>>(
      (ref) => TaskController(ref.watch(taskRepositoryProvider)),
    );

final taskRefreshTriggerProvider = Provider<DateTime>((ref) => DateTime.now());

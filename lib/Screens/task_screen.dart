import 'package:delivery/Screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:delivery/widgets/custom_app_bar.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:delivery/Screens/pickup_details_screen.dart';
import 'package:delivery/Screens/delivery_details_screen.dart';
import 'package:delivery/widgets/pickup_card.dart';
import 'package:delivery/widgets/delivery_card.dart';
import 'package:delivery/models/task_modeld.dart';
import 'package:delivery/repository/task_repository.dart';
import 'package:delivery/repository/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  int _activeTab = 1;
  int _pickupCount = 0;
  int _deliveryCount = 0;
  late final ProviderSubscription<DateTime> _refreshSub;

  @override
  void initState() {
    super.initState();
    _refreshSub = ref.listenManual<DateTime>(
      taskRefreshTriggerProvider,
      (_, __) {
        _loadTasksForTab(_activeTab);
      },
    );
    Future.microtask(
      () => _loadTasksForTab(_activeTab),
    );
  }

  @override
  void dispose() {
    _refreshSub.close();
    super.dispose();
  }

  Future<void> _loadTasksForTab(int tab) async {
    final result = await ref.read(taskControllerProvider.notifier).fetchForTab(
      activeTab: tab,
    );
    if (!mounted || result == null) return;
    setState(() {
      if (tab == 1) {
        _pickupCount = result.total;
      } else {
        _deliveryCount = result.total;
      }
    });
  }

  void _onTabChange(int index) {
    setState(() {
      _activeTab = index;
    });
    _loadTasksForTab(index);
  }

  String _formatCount(int count) => count.toString().padLeft(2, '0');

  String _formatStatus(String status) {
    if (status.trim().isEmpty) return 'UNKNOWN';
    return status.replaceAll('_', ' ').toUpperCase();
  }

  

  String _formatTimeLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final upper = trimmed.toUpperCase();
    if (upper.startsWith('SCHEDULED')) {
      return trimmed.substring('SCHEDULED'.length).trimLeft();
    }
    return trimmed;
  }

  Widget _buildTaskList(AsyncValue<TaskModel> tasksAsync) {
    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(error),
      data: (data) {
        final tasks = data.data;
        if (tasks.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildTaskCard(task);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(Datum task) {
    final type = task.deliveryType.toLowerCase().trim().isNotEmpty
        ? task.deliveryType.toLowerCase().trim()
        : (_activeTab == 1 ? TaskTypeValue.pickup : TaskTypeValue.delivery);

    final id = task.deliveryNumber.trim().isNotEmpty
        ? task.deliveryNumber.trim()
        : task.deliveryId.toString();
    final statusLabel = _formatStatus(task.status);
    final statusColor = _statusColor(task.status);
    final schedule = _formatSchedule(task);
    final timeLabel = _formatTimeLabel(schedule);

    final pickupTitle =
        task.farmer.fullName.trim().isNotEmpty
            ? task.farmer.fullName.trim()
            : (task.pickupContactName.trim().isNotEmpty
                ? task.pickupContactName.trim()
                : 'Pickup Location');
    final deliveryTitle =
        task.deliveryContactName.trim().isNotEmpty
            ? task.deliveryContactName.trim()
            : (task.farmer.fullName.trim().isNotEmpty
                ? task.farmer.fullName.trim()
                : 'Delivery Location');

    final pickupSubtitle = task.pickupAddress.trim().isNotEmpty
        ? task.pickupAddress.trim()
        : '-';
    final deliverySubtitle = task.deliveryAddress.trim().isNotEmpty
        ? task.deliveryAddress.trim()
        : '-';

    final expectedWeight = _formatWeight(task.expectedQuantityKg);
    final loadDetails = _formatLoadDetails(task);

    final title = type == TaskTypeValue.pickup ? pickupTitle : deliveryTitle;
    final subtitle =
        type == TaskTypeValue.pickup ? pickupSubtitle : deliverySubtitle;

    final detailId = task.deliveryId.toString();
    if (type == TaskTypeValue.pickup) {
      final weight = expectedWeight.isNotEmpty ? expectedWeight : '-';
      final pickupLoadDetails = loadDetails.isNotEmpty ? loadDetails : '-';

      return PickupCard(
        id: id,
        status: statusLabel,
        statusColor: statusColor,
        time: timeLabel,
        title: title,
        subtitle: subtitle,
        loadDetails: pickupLoadDetails,
        weight: weight,
        primaryActionLabel: 'View Details',
        onPrimaryAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PickupDetailsScreen(taskId: detailId),
            ),
          );
        },
      );
    }

    return DeliveryCard(
      id: id,
      status: statusLabel,
      statusColor: statusColor,
      time: timeLabel,
      title: title,
      subtitle: subtitle,
      loadDetails: loadDetails.isNotEmpty ? loadDetails : null,
      priority: null,
      primaryActionLabel: 'View Details',
      onPrimaryAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryDetailsScreen(taskId: detailId),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No tasks found',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load tasks',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                _loadTasksForTab(_activeTab);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deliveryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSchedule(Datum task) {
    final date = task.scheduledDate;
    final slot = task.scheduledTimeSlot.trim();

    final dateLabel = date == null
        ? ''
        : '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';

    if (dateLabel.isEmpty && slot.isEmpty) return '';
    if (dateLabel.isNotEmpty && slot.isNotEmpty) {
      return '$dateLabel - $slot';
    }
    return dateLabel.isNotEmpty ? dateLabel : slot;
  }

  String _formatWeight(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return '';
    if (normalized.toLowerCase().contains('kg')) return normalized;
    return '$normalized kg';
  }

  String _formatLoadDetails(Datum task) {
    final weight = _formatWeight(task.expectedQuantityKg);
    if (weight.isNotEmpty) return weight;
    final notes = task.deliveryNotes.trim();
    if (notes.isNotEmpty) return notes;
    return '';
  }

  Color _statusColor(String status) {
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case TaskStatusValue.accepted:
        return AppColors.deliveryColor;
      case TaskStatusValue.assigned:
        return AppColors.warning;
      case TaskStatusValue.inTransit:
        return Colors.blueAccent;
      case TaskStatusValue.reached:
        return AppColors.vendorColor;
      case TaskStatusValue.completed:
        return AppColors.success;
      case TaskStatusValue.cancelled:
      case TaskStatusValue.failed:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profileData = profileState.valueOrNull?.data;

    String _profileImageUrl(dynamic value) {
      if (value == null) {
        return '';
      }
      if (value is String) {
        return value.trim();
      }
      return value.toString().trim();
    }

    String _initialsForName(String name) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty || parts.first.isEmpty) {
        return '?';
      }
      if (parts.length == 1) {
        return parts.first.substring(0, 1).toUpperCase();
      }
      final first = parts.first.substring(0, 1);
      final last = parts.last.substring(0, 1);
      return '$first$last'.toUpperCase();
    }

    final imageUrl = _profileImageUrl(profileData?.profilePhotoUrl);
    final initials = _initialsForName(profileData?.fullName ?? '');
    final displayName = profileData?.fullName.split(' ').first ?? "User";

    final tasksAsync = ref.watch(taskControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomAppBar(
            backgroundColor: AppColors.deliveryColor,
            leading: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  )
                : null,
          ),
            title: displayName,
            titleFontSize: 22,
            actions: [
              CustomAppBar.buildActionButton(
                Icons.history_sharp,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tab Filters
          _buildFilterTabs(),
          const SizedBox(height: 24),

          // Search Protocol
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
                decoration: InputDecoration(
                  hintText: 'SEARCH PROTOCOL',
                  hintStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    letterSpacing: 1.2,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryGreen.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Today's Schedule Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                Text(
                  "TODAY'S SCHEDULE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Divider(height: 1, thickness: 1)),
              ],
            ),
          ),

          // Task List
          Expanded(child: _buildTaskList(tasksAsync)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(1, 'PICKUPS', _formatCount(_pickupCount)),
          _buildTabItem(2, 'DELIVERIES', _formatCount(_deliveryCount)),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, String count) {
    bool isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChange(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppColors.deliveryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: AppColors.deliveryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

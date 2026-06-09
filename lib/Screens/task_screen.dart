import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery/Screens/history_screen.dart';
import 'package:delivery/Screens/pickup_details_screen.dart';
import 'package:delivery/Screens/delivery_details_screen.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:delivery/models/task_modeld.dart';
import 'package:delivery/repository/task_repository.dart';
import 'package:delivery/repository/profile_repository.dart';
import 'package:delivery/widgets/pickup_card.dart';
import 'package:delivery/widgets/delivery_card.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen>
    with SingleTickerProviderStateMixin {
  int _activeTab = 1;
  int _pickupCount = 0;
  int _deliveryCount = 0;
  late final ProviderSubscription<DateTime> _refreshSub;
  late final AnimationController _headerAnimCtrl;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();

    _headerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnimCtrl,
      curve: Curves.easeOut,
    );
    _headerAnimCtrl.forward();

    _refreshSub = ref.listenManual<DateTime>(
      taskRefreshTriggerProvider,
      (_, __) => _loadTasksForTab(_activeTab),
    );

    Future.microtask(() => _loadTasksForTab(_activeTab));
  }

  @override
  void dispose() {
    _refreshSub.close();
    _headerAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTasksForTab(int tab) async {
    final result = await ref
        .read(taskControllerProvider.notifier)
        .fetchForTab(activeTab: tab);
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
    if (_activeTab == index) return;
    setState(() => _activeTab = index);
    _loadTasksForTab(index);
  }

  // ─── Formatters ────────────────────────────────────────────────────────────

  String _padCount(int count) => count.toString().padLeft(2, '0');

  String _formatStatus(String status) {
    if (status.trim().isEmpty) return 'UNKNOWN';
    return status.replaceAll('_', ' ').toUpperCase();
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
      return '$dateLabel · $slot';
    }
    return dateLabel.isNotEmpty ? dateLabel : slot;
  }

  String _formatWeight(String raw) {
    final n = raw.trim();
    if (n.isEmpty) return '';
    if (n.toLowerCase().contains('kg')) return n;
    return '$n kg';
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case TaskStatusValue.accepted:
        return AppColors.deliveryColor;
      case TaskStatusValue.assigned:
        return const Color(0xFFE65100);
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

  // ── Dynamic field helpers ──────────────────────────
  String _cropName(dynamic crop) =>
      (crop is Map) ? (crop['product']?['product_name']?.toString() ?? '') : '';

  String _cropGrade(dynamic crop) =>
      (crop is Map) ? (crop['grade']?.toString() ?? '') : '';

  String _cropPrice(dynamic crop) =>
      (crop is Map) ? (crop['expected_price_per_kg']?.toString() ?? '') : '';

  String _vendorShop(dynamic vendor) =>
      (vendor is Map) ? (vendor['shop_name']?.toString() ?? '') : '';

  String _orderNumber(dynamic order) =>
      (order is Map) ? (order['order_number']?.toString() ?? '') : '';

  String _orderStatus(dynamic order) =>
      (order is Map) ? (order['order_status']?.toString() ?? '') : '';

  String _cropHarvestDate(dynamic crop) {
    if (crop is! Map) return '';
    final raw = crop['harvest_date'];
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')} ${_monthAbbr(dt.month)}';
  }

  String _farmerMobile(dynamic farmer) {
    // farmer is a typed Farmer object — user field is dynamic
    if (farmer == null) return '';
    final user = (farmer as dynamic).user;
    if (user is Map) return user['mobile_number']?.toString() ?? '';
    return '';
  }

  String _vendorMobile(dynamic vendor) {
    if (vendor is! Map) return '';
    final user = vendor['user'];
    if (user is Map) return user['mobile_number']?.toString() ?? '';
    return '';
  }

  // ─── Card builder ──────────────────────────────────────────────────────────

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
    final weight = _formatWeight(task.expectedQuantityKg);
    final detailId = task.deliveryId.toString();

    if (type == TaskTypeValue.pickup) {
      // Resolve farmer name
      final farmerName = task.farmer.fullName.trim().isNotEmpty
          ? task.farmer.fullName.trim()
          : task.pickupContactName.trim().isNotEmpty
              ? task.pickupContactName.trim()
              : 'Pickup Location';

      // Resolve crop info — crop is dynamic, use safe helpers
      final cropName = _cropName(task.crop);
      final cropGrade = _cropGrade(task.crop);
      final pricePerKg = _cropPrice(task.crop);
      final harvestDate = _cropHarvestDate(task.crop);

      final contactNumber = _farmerMobile(task.farmer).isNotEmpty
          ? _farmerMobile(task.farmer)
          : task.pickupContactNumber.trim();

      return PickupCard(
        id: id,
        status: statusLabel,
        statusColor: statusColor,
        time: schedule,
        title: farmerName,
        subtitle: task.pickupAddress.trim().isNotEmpty
            ? task.pickupAddress.trim()
            : '-',
        loadDetails: weight.isNotEmpty ? weight : '-',
        weight: weight.isNotEmpty ? weight : '-',
        cropName: cropName.isNotEmpty ? cropName : null,
        cropGrade: cropGrade.isNotEmpty ? cropGrade : null,
        pricePerKg: pricePerKg.isNotEmpty ? pricePerKg : null,
        harvestDate: harvestDate.isNotEmpty ? harvestDate : null,
        contactNumber: contactNumber.isNotEmpty ? contactNumber : null,
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

    // ── Delivery card ─────────────────────────────────────────────────────
    final vendorName = _vendorShop(task.vendor);
    final productSummary = _cropName(task.crop);
    final orderNumber = _orderNumber(task.order);
    final orderStatus = _orderStatus(task.order);
    final deliveryTitle = task.deliveryContactName.trim().isNotEmpty
        ? task.deliveryContactName.trim()
        : vendorName.isNotEmpty
            ? vendorName
            : 'Delivery Location';

    final contactNumber = task.deliveryContactNumber.trim().isNotEmpty
        ? task.deliveryContactNumber.trim()
        : _vendorMobile(task.vendor);

    return DeliveryCard(
      id: id,
      status: statusLabel,
      statusColor: statusColor,
      time: schedule,
      title: deliveryTitle,
      subtitle: task.deliveryAddress.trim().isNotEmpty
          ? task.deliveryAddress.trim()
          : '-',
      loadDetails: weight.isNotEmpty ? weight : null,
      shopName: vendorName.isNotEmpty ? vendorName : null,
      productSummary: productSummary.isNotEmpty ? productSummary : null,
      orderNumber: orderNumber.isNotEmpty ? orderNumber : null,
      orderStatus: orderStatus.isNotEmpty ? orderStatus : null,
      contactNumber: contactNumber.isNotEmpty ? contactNumber : null,
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

  String _monthAbbr(int m) => const [
        '',
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec',
      ][m];

  // ─── Task list ─────────────────────────────────────────────────────────────

  Widget _buildTaskList(AsyncValue<TaskModel> tasksAsync) {
    return RefreshIndicator(
      color: AppColors.deliveryColor,
      onRefresh: () async => _loadTasksForTab(_activeTab),
      child: tasksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.deliveryColor,
            strokeWidth: 2.5,
          ),
        ),
        error: (error, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: 400, child: _buildErrorState(error)),
        ),
        data: (data) {
          if (data.data.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(height: 400, child: _buildEmptyState()),
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: data.data.length,
            itemBuilder: (_, i) => _buildTaskCard(data.data[i]),
          );
        },
      ),
    );
  }

  // ─── Empty / error ─────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.deliveryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 26,
              color: AppColors.deliveryColor.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => _loadTasksForTab(_activeTab),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.deliveryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profileData = profileState.valueOrNull?.data;
    final tasksAsync = ref.watch(taskControllerProvider);

    final rawName = profileData?.fullName ?? '';
    final displayName = rawName.trim().split(RegExp(r'\s+')).first;
    final initials = _initials(rawName);
    final imageUrl = _safeUrl(profileData?.profilePhotoUrl);

    final today = DateTime.now();
    final dateLabel =
        '${today.day.toString().padLeft(2, '0')} ${_monthAbbr(today.month)}'
        ' ${today.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0F8),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          FadeTransition(
            opacity: _headerFade,
            child: _buildHeader(
              initials: initials,
              imageUrl: imageUrl,
              displayName: displayName.isNotEmpty ? displayName : 'User',
              dateLabel: dateLabel,
            ),
          ),

          const SizedBox(height: 16),

          // ── Tabs ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTabs(),
          ),

          const SizedBox(height: 14),

          // ── Search ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearch(),
          ),

          const SizedBox(height: 16),

          // ── Section label ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Text(
                  "TODAY'S SCHEDULE",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB09EC4),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE2D9EE),
                  ),
                ),
              ],
            ),
          ),

          // ── Task list ─────────────────────────────────────────────────────
          Expanded(child: _buildTaskList(tasksAsync)),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader({
    required String initials,
    required String imageUrl,
    required String displayName,
    required String dateLabel,
  }) {
    return Container(
      color: AppColors.deliveryColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row — avatar + name + history
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'DELIVERY PARTNER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // History button
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistoryScreen(),
                      ),
                    ),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Stat pills row
              Row(
                children: [
                  _StatPill(
                    label: 'PICKUPS',
                    value: _padCount(_pickupCount),
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    label: 'DELIVERIES',
                    value: _padCount(_deliveryCount),
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    label: 'TODAY',
                    value: dateLabel,
                    valueFontSize: 13,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tabs ──────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deliveryColor.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          _TabItem(
            index: 1,
            label: 'PICKUPS',
            count: _padCount(_pickupCount),
            isActive: _activeTab == 1,
            onTap: _onTabChange,
          ),
          _TabItem(
            index: 2,
            label: 'DELIVERIES',
            count: _padCount(_deliveryCount),
            isActive: _activeTab == 2,
            onTap: _onTabChange,
          ),
        ],
      ),
    );
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.deliveryColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A0A2E),
        ),
        decoration: InputDecoration(
          hintText: 'SEARCH PROTOCOL',
          hintStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFD4C4E8),
            letterSpacing: 1.2,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.deliveryColor.withValues(alpha: 0.35),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _safeUrl(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }
}

// ─── Stat Pill ────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final double valueFontSize;

  const _StatPill({
    required this.label,
    required this.value,
    this.valueFontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.55),
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Item ─────────────────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  final int index;
  final String label;
  final String count;
  final bool isActive;
  final ValueChanged<int> onTap;

  const _TabItem({
    required this.index,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isActive ? AppColors.deliveryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.deliveryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
              color: isActive ? Colors.white : const Color(0xFF9A7AB5),
            ),
          ),
        ),
      ),
    );
  }
}
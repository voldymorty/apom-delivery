import 'package:delivery/global/colortheme.dart';
import 'package:delivery/models/history_model.dart';
import 'package:delivery/repository/history_repository.dart';
import 'package:delivery/Screens/delivery_details_screen.dart';
import 'package:delivery/Screens/pickup_details_screen.dart';
import 'package:delivery/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final List<String> _filters = ['All', 'Pickups', 'Deliveries'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChange);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChange);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChange() {
    final next = _searchController.text;
    if (next == _searchQuery) {
      return;
    }
    setState(() => _searchQuery = next);
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_sharp,
                  color: AppColors.primaryGreen,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: 'JOB HISTORY',
              subtitle: 'COMPLETED PROTOCOLS',
              centerTitle: true,
            ),
            Expanded(
              child: historyState.when(
                loading: _buildLoading,
                error: (error, _) => _buildError(error),
                data: (history) => _buildContent(history),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Unable to load history',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(historyControllerProvider.notifier).fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(HistoryModel history) {
    return RefreshIndicator(
      onRefresh: () => ref.read(historyControllerProvider.notifier).fetch(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildFilterChips(),
            const SizedBox(height: 30),
            _buildHistoryList(history.data),
            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          icon: Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          hintText: 'Search Task ID or Merchant...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.4),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children:
          _filters.map((filter) {
            bool isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.deliveryColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.deliveryColor
                              : Colors.black.withOpacity(0.05),
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: AppColors.deliveryColor.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                            : null,
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildHistoryList(List<Datum> items) {
    final filteredItems =
        items.where((item) {
          final status = item.status.trim().toLowerCase();
          if (!status.contains('complete')) {
            return false;
          }
          if (!_matchesSearch(item)) {
            return false;
          }
          if (_selectedFilter == 'All') {
            return true;
          }
          final type = _normalizeType(item.deliveryType);
          if (_selectedFilter == 'Pickups') {
            return type == 'Pickup';
          }
          if (_selectedFilter == 'Deliveries') {
            return type == 'Delivery';
          }
          return true;
        }).toList();

    // Sort by last delivered (completedAt) descending
    filteredItems.sort((a, b) {
      final dateA = a.completedAt ?? a.updatedAt ?? a.createdAt ?? DateTime(1970);
      final dateB = b.completedAt ?? b.updatedAt ?? b.createdAt ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: filteredItems.map((item) => _buildHistoryCard(item)).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 40,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No history found',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Datum item) {
    final type = _normalizeType(item.deliveryType);
    final isPickup = type == 'Pickup';
    Color themeColor =
        isPickup ? AppColors.primaryGreen : AppColors.deliveryColor;
    final id = _displayId(item);
    final title = _displayTitle(item, isPickup);
    final client = _displayClient(item, isPickup);
    final amount = _displayAmount(item);
    final dateText = _displayDate(item);
    final timeText = _displayTime(item);
    final status = _displayStatus(item);
    final statusColor = _statusColor(item);

    return InkWell(
      onTap: () {
        final taskId = item.deliveryId.toString();
        if (isPickup) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PickupDetailsScreen(taskId: taskId),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryDetailsScreen(taskId: taskId),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Column(
          children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPickup
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: themeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: themeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'ID: #$id',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      client,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.black.withOpacity(0.05), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                dateText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  bool _matchesSearch(Datum item) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    final buffer = StringBuffer()
      ..write(item.deliveryNumber)
      ..write(' ')
      ..write(item.deliveryId)
      ..write(' ')
      ..write(item.pickupContactName)
      ..write(' ')
      ..write(item.deliveryContactName)
      ..write(' ')
      ..write(item.pickupAddress)
      ..write(' ')
      ..write(item.deliveryAddress)
      ..write(' ');

    final farmerName = _safeTrim(item.farmer?.fullName);
    final vendorShop = _safeTrim(item.vendor?.shopName);
    final vendorOwner = _safeTrim(item.vendor?.ownerName);
    final productName = _safeTrim(item.crop?.product.productName);
    final orderNumber = _safeTrim(item.order?.orderNumber);

    buffer
      ..write(farmerName)
      ..write(' ')
      ..write(vendorShop)
      ..write(' ')
      ..write(vendorOwner)
      ..write(' ')
      ..write(productName)
      ..write(' ')
      ..write(orderNumber);

    return buffer.toString().toLowerCase().contains(query);
  }

  String _normalizeType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'pickup' || normalized == 'pickups') {
      return 'Pickup';
    }
    if (normalized == 'delivery' || normalized == 'deliveries') {
      return 'Delivery';
    }
    return normalized.isNotEmpty ? normalized.toUpperCase() : 'Unknown';
  }

  String _displayId(Datum item) {
    final trimmed = item.deliveryNumber.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return item.deliveryId.toString();
  }

  String _displayTitle(Datum item, bool isPickup) {
    final product = _safeTrim(item.crop?.product.productName);
    if (product.isNotEmpty) {
      return product;
    }
    if (isPickup) {
      final name = item.pickupContactName.trim();
      return name.isNotEmpty ? name : 'Pickup Location';
    }
    final name = item.deliveryContactName.trim();
    return name.isNotEmpty ? name : 'Delivery Location';
  }

  String _displayClient(Datum item, bool isPickup) {
    if (isPickup) {
      final farmer = _safeTrim(item.farmer?.fullName);
      if (farmer.isNotEmpty) {
        return farmer;
      }
      final pickupName = item.pickupContactName.trim();
      return pickupName.isNotEmpty ? pickupName : 'Pickup Client';
    }
    final vendorShop = _safeTrim(item.vendor?.shopName);
    if (vendorShop.isNotEmpty) {
      return vendorShop;
    }
    final vendorOwner = _safeTrim(item.vendor?.ownerName);
    if (vendorOwner.isNotEmpty) {
      return vendorOwner;
    }
    final deliveryName = item.deliveryContactName.trim();
    return deliveryName.isNotEmpty ? deliveryName : 'Delivery Client';
  }

  String _displayAmount(Datum item) {
    final actual = _safeTrim(item.actualQuantityKg?.toString());
    final expected = item.expectedQuantityKg.trim();
    final raw = actual.isNotEmpty ? actual : expected;
    if (raw.isEmpty) {
      return '-';
    }
    if (raw.toLowerCase().contains('kg')) {
      return raw.toUpperCase();
    }
    return '$raw KG';
  }

  String _displayDate(Datum item) {
    final date = item.completedAt ?? item.scheduledDate ?? item.createdAt;
    if (date == null) {
      return '-';
    }
    return _formatDate(date);
  }

  String _displayTime(Datum item) {
    final slot = item.scheduledTimeSlot.trim();
    if (slot.isNotEmpty) {
      return slot;
    }
    final time = item.completedAt ?? item.scheduledDate ?? item.createdAt;
    if (time == null) {
      return '-';
    }
    return _formatTime(time);
  }

  String _displayStatus(Datum item) {
    final status = item.status.trim();
    if (status.isEmpty) {
      return 'UNKNOWN';
    }
    return status.toUpperCase();
  }

  Color _statusColor(Datum item) {
    final status = item.status.trim().toLowerCase();
    if (status.contains('complete')) {
      return AppColors.success;
    }
    if (status.contains('fail')) {
      return AppColors.error;
    }
    if (status.contains('cancel')) {
      return AppColors.warning;
    }
    return AppColors.textSecondary;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[(date.month - 1).clamp(0, 11)];
    return '$month ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _safeTrim(String? value) {
    return value?.trim() ?? '';
  }
}

import 'package:delivery/global/colortheme.dart';
import 'package:delivery/models/history_model.dart';
import 'package:delivery/repository/history_repository.dart';
import 'package:delivery/Screens/delivery_details_screen.dart';
import 'package:delivery/Screens/pickup_details_screen.dart';
import 'package:delivery/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Status constants ─────────────────────────────────────────────────────────

const _kAllStatuses = [
  'completed',
  'assigned',
  'accepted',
  'in_transit',
  'reached',
  'failed',
  'cancelled',
];

const _kStatusLabels = {
  'completed':  'Completed',
  'assigned':   'Assigned',
  'accepted':   'Accepted',
  'in_transit': 'In Transit',
  'reached':    'Reached',
  'failed':     'Failed',
  'cancelled':  'Cancelled',
};

// ─── Screen ───────────────────────────────────────────────────────────────────

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Local-only filter state (drives API call via controller)
  String? _selectedType;   // null = all, 'pickup', 'delivery'
  String? _selectedStatus; // null = all, or one of _kAllStatuses
  String  _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final next = _searchController.text;
    if (next != _searchQuery) setState(() => _searchQuery = next);
  }

  void _applyApiFilter() {
    final filter = HistoryFilter(
      type:   _selectedType,
      status: _selectedStatus,
    );
    ref.read(historyControllerProvider.notifier).applyFilter(filter);
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.deliveryColor,
            AppColors.deliveryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          CustomAppBar(
            backgroundColor: Colors.transparent,
            title: 'Task History',
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: historyState.when(
              loading: _buildLoading,
              error:   (e, _) => _buildError(e),
              data:    _buildContent,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.deliveryColor,
      ),
    );
  }

  // ─── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load history',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.read(historyControllerProvider.notifier).fetch(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deliveryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Try again',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(HistoryModel history) {
    final filtered = _applyLocalSearch(history.data);

    return RefreshIndicator(
      onRefresh: () => ref.read(historyControllerProvider.notifier).fetch(),
      color: AppColors.deliveryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  _buildSearchAndFilter(),
                  const SizedBox(height: 16),
                  _buildTypeToggle(),
                  const SizedBox(height: 20),
                  _buildSummaryRow(history.data),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmpty(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildCard(filtered[i]),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Search + filter row ────────────────────────────────────────────────────

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary.withOpacity(0.5),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary.withOpacity(0.5),
                          size: 18,
                        ),
                      )
                    : null,
                hintText: 'Search ID, farmer, vendor…',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withOpacity(0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              cursorColor: AppColors.deliveryColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildFilterButton(),
      ],
    );
  }

  Widget _buildFilterButton() {
    final hasFilter = _selectedStatus != null;
    return GestureDetector(
      onTap: _showFilterSheet,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: hasFilter ? AppColors.deliveryColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFilter ? AppColors.deliveryColor : AppColors.divider,
          ),
        ),
        child: Icon(
          Icons.tune_rounded,
          size: 20,
          color: hasFilter ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  // ─── Type toggle (All / Pickup / Delivery) ──────────────────────────────────

  Widget _buildTypeToggle() {
    const types = [
      (label: 'All',       value: null,       icon: Icons.grid_view_rounded),
      (label: 'Pickups',   value: 'pickup',   icon: Icons.arrow_upward_rounded),
      (label: 'Deliveries',value: 'delivery', icon: Icons.arrow_downward_rounded),
    ];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: types.map((t) {
          final selected = _selectedType == t.value;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedType = t.value);
                _applyApiFilter();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.deliveryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t.icon,
                      size: 15,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Summary row ────────────────────────────────────────────────────────────

  Widget _buildSummaryRow(List<Datum> all) {
    int countType(String type) => all
        .where((d) => _normalizeType(d.deliveryType) == type)
        .length;

    final total     = all.length;
    final pickups   = countType('Pickup');
    final deliveries= countType('Delivery');

    return Row(
      children: [
        _buildStatChip(
          label: 'Total',
          value: total.toString(),
          color: AppColors.deliveryColor,
        ),
        const SizedBox(width: 10),
        _buildStatChip(
          label: 'Pickups',
          value: pickups.toString(),
          color: AppColors.primaryGreen,
        ),
        const SizedBox(width: 10),
        _buildStatChip(
          label: 'Deliveries',
          value: deliveries.toString(),
          color: AppColors.deliveryColor.withOpacity(0.7),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color.withOpacity(0.7),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 44,
              color: AppColors.textSecondary.withOpacity(0.25),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'No jobs found',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedStatus != null ||
                _selectedType != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _clearAllFilters,
                child: Text(
                  'Clear filters',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deliveryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _selectedType   = null;
      _selectedStatus = null;
      _searchQuery    = '';
    });
    _applyApiFilter();
  }

  // ─── Card ───────────────────────────────────────────────────────────────────

  Widget _buildCard(Datum item) {
    final isPickup   = _normalizeType(item.deliveryType) == 'Pickup';
    final accentColor= isPickup ? AppColors.primaryGreen : AppColors.vendorColor;
    final title      = _displayTitle(item, isPickup);
    final client     = _displayClient(item, isPickup);
    final quantity   = _displayQuantity(item);
    final amount     = _displayAmount(item);
    final dateText   = _displayDate(item);
    final timeSlot   = item.scheduledTimeSlot.trim();
    final statusText = _displayStatus(item);
    final statusColor= _statusColor(item);
    final id         = _displayId(item);

    return GestureDetector(
      onTap: () {
        final taskId = item.deliveryId.toString();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isPickup
                ? PickupDetailsScreen(taskId: taskId)
                : DeliveryDetailsScreen(taskId: taskId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Accent bar
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft:    Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: type badge + status + id
                        Row(
                          children: [
                            _TypeBadge(
                              label: isPickup ? 'PICKUP' : 'DELIVERY',
                              color: accentColor,
                            ),
                            const SizedBox(width: 6),
                            _StatusBadge(
                              label: statusText,
                              color: statusColor,
                            ),
                            const Spacer(),
                            Text(
                              id,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary.withOpacity(0.4),
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppColors.textSecondary.withOpacity(0.35),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Row 2: title + quantity
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    client,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary
                                          .withOpacity(0.65),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  quantity,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: accentColor,
                                  ),
                                ),
                                if (amount.isNotEmpty)
                                  Text(
                                    amount,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Divider(
                          color: AppColors.divider,
                          height: 1,
                        ),
                        const SizedBox(height: 10),

                        // Row 3: date + time
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              dateText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary.withOpacity(0.6),
                              ),
                            ),
                            if (timeSlot.isNotEmpty) ...[
                              const SizedBox(width: 14),
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                timeSlot,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      AppColors.textSecondary.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Filter bottom sheet ────────────────────────────────────────────────────

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        selectedStatus: _selectedStatus,
        onApply: (status) {
          setState(() => _selectedStatus = status);
          _applyApiFilter();
        },
        onClear: () {
          setState(() => _selectedStatus = null);
          _applyApiFilter();
        },
      ),
    );
  }

  // ─── Filtering & search ─────────────────────────────────────────────────────

  List<Datum> _applyLocalSearch(List<Datum> items) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return List.from(items)
      ..sort(_sortByDate);

    final result = items
        .where((item) => _matchesSearch(item, query))
        .toList()
      ..sort(_sortByDate);
    return result;
  }

  int _sortByDate(Datum a, Datum b) {
    final dateA =
        a.completedAt ?? a.updatedAt ?? a.createdAt ?? DateTime(1970);
    final dateB =
        b.completedAt ?? b.updatedAt ?? b.createdAt ?? DateTime(1970);
    return dateB.compareTo(dateA);
  }

  bool _matchesSearch(Datum item, String query) {
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
      ..write(' ')
      ..write(item.farmer?.fullName ?? '')
      ..write(' ')
      ..write(item.vendor?.shopName ?? '')
      ..write(' ')
      ..write(item.vendor?.ownerName ?? '')
      ..write(' ')
      ..write(item.crop?.product.productName ?? '')
      ..write(' ')
      ..write(item.order?.orderNumber ?? '');
    return buffer.toString().toLowerCase().contains(query);
  }

  // ─── Display helpers ────────────────────────────────────────────────────────

  String _normalizeType(String value) {
    final v = value.trim().toLowerCase();
    if (v == 'pickup')   return 'Pickup';
    if (v == 'delivery') return 'Delivery';
    return value;
  }

  String _displayId(Datum item) {
    final t = item.deliveryNumber.trim();
    return t.isNotEmpty ? t : '#${item.deliveryId}';
  }

  String _displayTitle(Datum item, bool isPickup) {
    final raw = item.crop?.product.productName.trim() ?? '';
    if (raw.isNotEmpty) {
      final cleaned =
          raw.replaceAll(RegExp(r'\s*\(\d+(?:\.\d+)?kg\)', caseSensitive: false), '').trim();
      if (cleaned.isNotEmpty) {
        return cleaned[0].toUpperCase() + cleaned.substring(1);
      }
    }
    if (isPickup) {
      final n = item.pickupContactName.trim();
      return n.isNotEmpty ? n : 'Pickup';
    }
    final n = item.deliveryContactName.trim();
    return n.isNotEmpty ? n : 'Delivery';
  }

  String _displayClient(Datum item, bool isPickup) {
    if (isPickup) {
      final n = item.farmer?.fullName.trim() ?? '';
      if (n.isNotEmpty) return n;
      return item.pickupContactName.trim().isNotEmpty
          ? item.pickupContactName.trim()
          : '—';
    }
    final shop = item.vendor?.shopName.trim() ?? '';
    if (shop.isNotEmpty) return shop;
    final owner = item.vendor?.ownerName.trim() ?? '';
    if (owner.isNotEmpty) return owner;
    return item.deliveryContactName.trim().isNotEmpty
        ? item.deliveryContactName.trim()
        : '—';
  }

  String _displayQuantity(Datum item) {
    final actual   = item.actualQuantityKg?.trim() ?? '';
    final expected = item.expectedQuantityKg.trim();
    final raw      = actual.isNotEmpty ? actual : expected;
    if (raw.isEmpty) return '—';
    final num = double.tryParse(raw);
    if (num != null) {
      final s = num == num.truncateToDouble()
          ? num.toInt().toString()
          : raw;
      return '$s KG';
    }
    return raw.toUpperCase();
  }

  String _displayAmount(Datum item) {
    final raw = item.toJson();
    final finalAmt = raw['final_procurement_amount']?.toString() ?? '';
    final procAmt  = raw['procurement_amount']?.toString() ?? '';
    final src      = finalAmt.isNotEmpty ? finalAmt : procAmt;
    if (src.isEmpty) return '';
    final num = double.tryParse(src);
    if (num == null) return '';
    return '₹${num.toStringAsFixed(0)}';
  }

  String _displayDate(Datum item) {
    final d = item.completedAt ?? item.scheduledDate ?? item.createdAt;
    if (d == null) return '—';
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _displayStatus(Datum item) {
    final s = item.status.trim();
    return _kStatusLabels[s.toLowerCase()] ?? s.toUpperCase();
  }

  Color _statusColor(Datum item) {
    switch (item.status.trim().toLowerCase()) {
      case 'completed':  return AppColors.success;
      case 'failed':     return AppColors.error;
      case 'cancelled':  return AppColors.warning;
      case 'in_transit': return AppColors.deliveryColor;
      case 'reached':    return AppColors.primaryGreen;
      default:           return AppColors.textSecondary;
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─── Filter bottom sheet ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final String? selectedStatus;
  final void Function(String? status) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.selectedStatus,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                const Text(
                  'Filter by status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_status != null)
                  GestureDetector(
                    onTap: () {
                      setState(() => _status = null);
                      widget.onClear();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deliveryColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kAllStatuses.map((s) {
                final selected = _status == s;
                final label    = _kStatusLabels[s] ?? s;
                return GestureDetector(
                  onTap: () => setState(() => _status = selected ? null : s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.deliveryColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.deliveryColor
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_status);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deliveryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

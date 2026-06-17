// notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:delivery/models/notification_model.dart';
import 'package:delivery/Screens/pickup_details_screen.dart';
import 'package:delivery/Screens/delivery_details_screen.dart';
import 'package:delivery/repository/notification_repository.dart';
import 'package:delivery/widgets/custom_app_bar.dart';
import 'package:delivery/widgets/custom_snackbar.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _limit = 20;

  // ─── Delivery blue palette ──────────────────────────────────────────────────
  static const Color _brandBlue = Color(0xFF2563EB);
  static const Color _brandBlueDim = Color(0xFFEFF6FF);
  static const Color _brandBlueBorder = Color(0xFFBFDBFE);
  static const Color _pageBackground = Color(0xFFF0F4FF);
  static const Color _cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadInitialNotifications();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Data loading (unchanged) ───────────────────────────────────────────────

  Future<void> _loadInitialNotifications() async {
    setState(() {
      _isLoading = true;
      _notifications.clear();
      _page = 1;
      _hasMore = true;
    });
    try {
      final model = await ref
          .read(notificationRepositoryProvider)
          .getNotifications(page: _page, limit: _limit);
      setState(() {
        _notifications.addAll(model.data.notifications);
        _isLoading = false;
        final p = model.data.pagination;
        _hasMore =
            p != null ? _page < p.totalPages : model.data.notifications.length >= _limit;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) CustomSnackBar.error(context, 'Failed to load notifications: $e');
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final nextPage = _page + 1;
      final model = await ref
          .read(notificationRepositoryProvider)
          .getNotifications(page: nextPage, limit: _limit);
      setState(() {
        _notifications.addAll(model.data.notifications);
        _page = nextPage;
        _isLoading = false;
        final p = model.data.pagination;
        _hasMore =
            p != null ? _page < p.totalPages : model.data.notifications.length >= _limit;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) CustomSnackBar.error(context, 'Failed to load more: $e');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  Future<void> _markAsRead(NotificationItem notification, int index) async {
    if (notification.isRead) return;
    setState(() {
      _notifications[index] =
          notification.copyWith(isRead: true, readAt: DateTime.now());
    });
    try {
      await ref
          .read(notificationRepositoryProvider)
          .markAsRead(notification.notificationId);
      ref.invalidate(unreadCountProvider);
    } catch (_) {
      setState(() => _notifications[index] = notification);
    }
  }

  Future<void> _markAllAsRead() async {
    final hasUnread = _notifications.any((n) => !n.isRead);
    if (!hasUnread) {
      CustomSnackBar.info(context, 'No unread notifications');
      return;
    }
    try {
      setState(() {
        for (int i = 0; i < _notifications.length; i++) {
          if (!_notifications[i].isRead) {
            _notifications[i] =
                _notifications[i].copyWith(isRead: true, readAt: DateTime.now());
          }
        }
      });
      await ref.read(notificationRepositoryProvider).markAllAsRead();
      ref.invalidate(unreadCountProvider);
      CustomSnackBar.success(context, 'All notifications marked as read');
    } catch (e) {
      _loadInitialNotifications();
      CustomSnackBar.error(context, 'Failed to mark all as read: $e');
    }
  }

  void _handleNotificationTap(NotificationItem notification, int index) {
    _markAsRead(notification, index);
    final refType = notification.referenceType?.toLowerCase() ?? '';
    final refId = notification.referenceId;
    if (refId == null) return;
    final taskId = refId.toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => refType.contains('delivery')
            ? DeliveryDetailsScreen(taskId: taskId)
            : PickupDetailsScreen(taskId: taskId),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'alert':
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  ({Color bg, Color fg, String label}) _typeStyle(String type) {
    switch (type.toLowerCase()) {
      case 'delivery':
        return (
          bg: const Color(0xFFEFF6FF),
          fg: const Color(0xFF1D4ED8),
          label: 'Delivery',
        );
      case 'alert':
        return (
          bg: const Color(0xFFFFF7ED),
          fg: const Color(0xFFC2410C),
          label: 'Alert',
        );
      case 'order':
        return (
          bg: const Color(0xFFF0FDF4),
          fg: const Color(0xFF15803D),
          label: 'Order',
        );
      default:
        return (
          bg: const Color(0xFFF5F3FF),
          fg: const Color(0xFF6D28D9),
          label: 'Pickup',
        );
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final todayItems = _notifications.where((n) => _isToday(n.createdAt)).toList();
    final earlierItems = _notifications.where((n) => !_isToday(n.createdAt)).toList();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadInitialNotifications,
              color: _brandBlue,
              child: _notifications.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : _buildBody(todayItems, earlierItems),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: AppColors.deliveryColor,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),                
              ],
            ),
          ),
          GestureDetector(
            onTap: _markAllAsRead,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.done_all_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Mark all read',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    List<NotificationItem> todayItems,
    List<NotificationItem> earlierItems,
  ) {
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // ─── Unread count banner ────────────────────────────────────────
        if (_unreadCount > 0) ...[
          _buildUnreadBanner(),
          const SizedBox(height: 18),
        ],

        // ─── Today section ──────────────────────────────────────────────
        if (todayItems.isNotEmpty) ...[
          _buildSectionLabel('Today'),
          const SizedBox(height: 10),
          ...todayItems.asMap().entries.map((e) {
            final globalIdx = _notifications.indexOf(e.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildNotifCard(e.value, globalIdx),
            );
          }),
          const SizedBox(height: 8),
        ],

        // ─── Earlier section ────────────────────────────────────────────
        if (earlierItems.isNotEmpty) ...[
          _buildSectionLabel('Earlier'),
          const SizedBox(height: 10),
          ...earlierItems.asMap().entries.map((e) {
            final globalIdx = _notifications.indexOf(e.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildNotifCard(e.value, globalIdx),
            );
          }),
        ],

        // ─── Loading indicator ──────────────────────────────────────────
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_brandBlue),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUnreadBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _brandBlueBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Text(
            '$_unreadCount',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: _brandBlue,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: _brandBlueBorder,
            margin: const EdgeInsets.symmetric(horizontal: 14),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'unread notifications',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                Text(
                  'Tap each to mark as read',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.notifications_active_outlined,
              color: _brandBlue, size: 22),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B7280),
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildNotifCard(NotificationItem item, int index) {
    final isUnread = !item.isRead;
    final style = _typeStyle(item.type);

    return GestureDetector(
      onTap: () => _handleNotificationTap(item, index),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? _brandBlueBorder : const Color(0xFFE5E7EB),
            width: 0.5,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent rail
              if (isUnread)
                Container(
                  width: 3,
                  decoration: const BoxDecoration(
                    color: _brandBlue,
                    borderRadius:
                        BorderRadius.horizontal(left: Radius.circular(14)),
                  ),
                ),

              // Card content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isUnread ? 14 : 14,
                    14,
                    14,
                    14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: style.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_iconForType(item.type),
                            color: style.fg, size: 20),
                      ),
                      const SizedBox(width: 12),

                      // Text body
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isUnread
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isUnread
                                          ? const Color(0xFF111827)
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatRelativeTime(item.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: isUnread
                                    ? const Color(0xFF374151)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Type pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: style.bg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                style.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: style.fg,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Unread dot
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _brandBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _brandBlueBorder, width: 0.5),
                ),
                child: Icon(
                  Icons.notifications_none_outlined,
                  size: 56,
                  color: _brandBlue.withOpacity(0.35),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'All caught up',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'New task updates will appear here.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
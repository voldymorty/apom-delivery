import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:delivery/widgets/custom_snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery/models/task_detail_model.dart';
import 'package:delivery/repository/task_detail_repository.dart';
import 'package:delivery/repository/task_repository.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Status pipeline
// ─────────────────────────────────────────────────────────────────────────────
const _statusOrder = [
  'assigned',
  'accepted',
  'in_transit',
  'reached',
  'completed',
];

int _statusIndex(String status) {
  final s = status.trim().toLowerCase();
  final idx = _statusOrder.indexOf(s);
  return idx == -1 ? 0 : idx;
}

// ─────────────────────────────────────────────────────────────────────────────
// Vendor helper — parses vendor dynamic field from Data
// ─────────────────────────────────────────────────────────────────────────────
class _Vendor {
  final String shopName;
  final String ownerName;
  final String vendorPhotoUrl;
  final String shopPhotoUrl;
  final String primaryAddress;
  final String latitude;
  final String longitude;
  final String businessType;
  final String gstNumber;
  final int totalOrders;
  final String mobile;

  const _Vendor({
    required this.shopName,
    required this.ownerName,
    required this.vendorPhotoUrl,
    required this.shopPhotoUrl,
    required this.primaryAddress,
    required this.latitude,
    required this.longitude,
    required this.businessType,
    required this.gstNumber,
    required this.totalOrders,
    required this.mobile,
  });

  factory _Vendor.fromMap(Map<String, dynamic> m) {
    String _s(String k) => m[k]?.toString() ?? '';
    int _i(String k) {
      final v = m[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final user = m['user'];
    final mobile = user is Map ? (user['mobile_number']?.toString() ?? '') : '';

    return _Vendor(
      shopName: _s('shop_name'),
      ownerName: _s('owner_name'),
      vendorPhotoUrl: _s('vendor_photo_url'),
      shopPhotoUrl: _s('shop_photo_url'),
      primaryAddress: _s('primary_address'),
      latitude: _s('latitude'),
      longitude: _s('longitude'),
      businessType: _s('business_type'),
      gstNumber: _s('gst_number'),
      totalOrders: _i('total_orders'),
      mobile: mobile,
    );
  }

  static _Vendor? tryParse(dynamic raw) {
    if (raw is Map<String, dynamic>) return _Vendor.fromMap(raw);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order helper — parses order dynamic field from Data
// ─────────────────────────────────────────────────────────────────────────────
class _Order {
  final String orderNumber;
  final String subtotal;
  final String taxAmount;
  final String taxPercentage;
  final String deliveryCharges;
  final String finalAmount;
  final String paymentStatus;
  final String orderStatus;
  final DateTime? expectedDeliveryDate;
  final String specialInstructions;

  const _Order({
    required this.orderNumber,
    required this.subtotal,
    required this.taxAmount,
    required this.taxPercentage,
    required this.deliveryCharges,
    required this.finalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    required this.expectedDeliveryDate,
    required this.specialInstructions,
  });

  factory _Order.fromMap(Map<String, dynamic> m) {
    String _s(String k) => m[k]?.toString() ?? '';
    DateTime? _dt(String k) {
      final v = m[k];
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return _Order(
      orderNumber: _s('order_number'),
      subtotal: _s('subtotal_amount'),
      taxAmount: _s('tax_amount'),
      taxPercentage: _s('tax_percentage'),
      deliveryCharges: _s('delivery_charges'),
      finalAmount: _s('final_amount'),
      paymentStatus: _s('payment_status'),
      orderStatus: _s('order_status'),
      expectedDeliveryDate: _dt('expected_delivery_date'),
      specialInstructions: _s('special_instructions'),
    );
  }

  static _Order? tryParse(dynamic raw) {
    if (raw is Map<String, dynamic>) return _Order.fromMap(raw);
    return null;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Screen
// ═════════════════════════════════════════════════════════════════════════════
class DeliveryDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;
  const DeliveryDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<DeliveryDetailsScreen> createState() =>
      _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends ConsumerState<DeliveryDetailsScreen>
    with TickerProviderStateMixin {
  // ── Proof / OTP state ─────────────────────────────────────────────────────
  bool _isProofTaken = false;
  String? _capturedImagePath;
  bool _isOtpVerified = false;
  bool _isSubmittingProof = false;
  bool _isVerifyingOtp = false;
  String _expectedOtp = '';

  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(4, (_) => FocusNode());

  Timer? _resendTimer;
  final ValueNotifier<int> _resendCountdown = ValueNotifier<int>(0);

  // ── Location ───────────────────────────────────────────────────────────────
  String? _verifiedLocationLabel;
  bool _isFetchingLocation = false;

  // ── Camera ────────────────────────────────────────────────────────────────
  final ImagePicker _picker = ImagePicker();

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _fadeCtrl.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final n in _focusNodes) n.dispose();
    _resendCountdown.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Timers
  // ─────────────────────────────────────────────────────────────────────────
  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendCountdown.value = 30;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown.value == 0) {
        t.cancel();
      } else {
        _resendCountdown.value--;
      }
    });
  }

  void _reloadDetail() =>
      ref.read(taskDetailControllerProvider(widget.taskId).notifier).fetch();

  // ─────────────────────────────────────────────────────────────────────────
  // GPS → Google Maps  (vendor lat/lng → delivery address fallback)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _openInGoogleMaps(Data data) async {
    final vendor = _Vendor.tryParse(data.vendor);
    final lat = vendor?.latitude.trim() ?? '';
    final lng = vendor?.longitude.trim() ?? '';

    if (lat.isNotEmpty && lng.isNotEmpty) {
      // Native geo intent (Android – opens Google Maps)
      final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
      // Web driving directions fallback
      final webUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Address-based fallback
    final address = data.deliveryAddress.trim().isNotEmpty
        ? data.deliveryAddress.trim()
        : (vendor?.primaryAddress.trim() ?? '');
    if (address.isNotEmpty) {
      final encoded = Uri.encodeComponent(address);
      final uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encoded');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (mounted) CustomSnackBar.error(context, 'Could not open Google Maps.');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Phone call
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _callContact(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) CustomSnackBar.error(context, 'Could not launch dialler.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Location label for proof photo
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _loadCurrentLocation() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);
    try {
      final svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final label = _formatPlacemark(marks);
      if (mounted) {
        setState(() {
          _verifiedLocationLabel = label.isNotEmpty
              ? label
              : '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  String _formatPlacemark(List<Placemark> marks) {
    if (marks.isEmpty) return '';
    final p = marks.first;
    return [p.street, p.subLocality, p.locality, p.administrativeArea]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(', ');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Camera
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _startCapture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (photo != null) {
        setState(() {
          _capturedImagePath = photo.path;
          _isProofTaken = true;
        });
        _loadCurrentLocation();
        if (mounted) CustomSnackBar.success(context, 'Proof photo captured!');
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Camera error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Proof submit + OTP
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _submitProofAndShowOtp(Data data) async {
    if (_isSubmittingProof) return;
    if (_expectedOtp.trim().isNotEmpty) {
      _showOtpBottomSheet(data);
      return;
    }
    if (_capturedImagePath == null) {
      CustomSnackBar.error(context, 'Please capture the delivery proof photo first.');
      return;
    }

    setState(() => _isSubmittingProof = true);

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {}

    try {
      final response = await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .uploadProofPhoto(
            imageFile: File(_capturedImagePath!),
            latitude: position?.latitude,
            longitude: position?.longitude,
          );

      _expectedOtp = response.otpCode;
      if (mounted && response.message.trim().isNotEmpty) {
        CustomSnackBar.success(context, response.message);
      }

      final mobile = data.deliveryContactNumber.trim();
      if (mobile.isNotEmpty && _expectedOtp.trim().isNotEmpty) {
        final smsOk = await ref
            .read(taskDetailControllerProvider(widget.taskId).notifier)
            .sendOtpSms(mobileNumber: mobile, otp: _expectedOtp);
        if (mounted && !smsOk) {
          CustomSnackBar.error(
              context, 'Failed to send OTP SMS. Share the OTP manually.');
        }
      }

      if (mounted) {
        _startResendTimer();
        _showOtpBottomSheet(data);
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Proof upload failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmittingProof = false);
    }
  }

  Future<void> _resendOtp(Data data) async {
    if (_resendCountdown.value > 0) return;
    final mobile = data.deliveryContactNumber.trim();
    if (mobile.isEmpty || _expectedOtp.trim().isEmpty) return;
    try {
      final ok = await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .sendOtpSms(mobileNumber: mobile, otp: _expectedOtp);
      if (mounted) {
        if (ok) {
          _startResendTimer();
          CustomSnackBar.success(context, 'OTP resent!');
        } else {
          CustomSnackBar.error(context, 'Failed to resend OTP.');
        }
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Error: $e');
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .updateTaskStatus(status: newStatus);
      ref.invalidate(taskRefreshTriggerProvider);
      _reloadDetail();
      if (mounted) {
        CustomSnackBar.success(
            context, 'Status updated to ${newStatus.toUpperCase()}');
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Failed to update status: $e');
    }
  }

  Future<void> _verifyOtp(Data data) async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 4) {
      CustomSnackBar.error(context, 'Enter the 4-digit OTP');
      return;
    }
    final expected = _expectedOtp.trim().isNotEmpty
        ? _expectedOtp.trim()
        : data.otpCode.trim();
    if (expected.isNotEmpty && otp != expected) {
      CustomSnackBar.error(context, 'Invalid OTP. Please try again.');
      return;
    }

    setState(() => _isVerifyingOtp = true);
    try {
      final response = await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .verifyTaskOtp(otp: otp);

      if (mounted) {
        Navigator.pop(context);
        setState(() => _isOtpVerified = true);
        ref.invalidate(taskRefreshTriggerProvider);
        CustomSnackBar.success(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Delivery Verified Successfully!',
        );
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Verification failed: $e');
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(taskDetailControllerProvider(widget.taskId));

    return detailAsync.when(
      loading: _buildLoading,
      error: (e, _) => _buildError(e),
      data: (detail) {
        // Trigger fade-in once
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_fadeCtrl.isCompleted) _fadeCtrl.forward();
        });
        return _buildMain(detail.data);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Loading
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLoading() => const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Error
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildError(Object? error) => Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_off_rounded,
                      color: Color(0xFFFF3B30), size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Could not load task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8EA0),
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                _solidButton(
                  label: 'Retry',
                  color: const Color(0xFF7C3AED),
                  onTap: _reloadDetail,
                  height: 48,
                ),
              ],
            ),
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Main scaffold
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMain(Data data) {
    final vendor = _Vendor.tryParse(data.vendor);
    final order = _Order.tryParse(data.order);
    final proofImage = _resolveProofImage(data);
    final isCompleted = data.status.trim().toLowerCase() == 'completed';
    final showProof = proofImage != null && (_isProofTaken || isCompleted);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(data),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildStatusTimeline(data),
                      const SizedBox(height: 14),
                      _buildDeliveryLocationCard(data, vendor),
                      const SizedBox(height: 14),
                      if (vendor != null) ...[
                        _buildVendorCard(data, vendor),
                        const SizedBox(height: 14),
                      ],
                      _buildCargoCard(data),
                      if (order != null) ...[
                        const SizedBox(height: 14),
                        _buildOrderSummaryCard(order),
                      ],
                      if (showProof) ...[
                        const SizedBox(height: 14),
                        _buildProofPhotoCard(data, proofImage),
                      ],
                      if (data.statusHistory.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildActivityLog(data),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _buildBottomBar(data, vendor),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(Data data) {
    final statusColor = _statusColor(data.status);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEF5))),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Color(0xFF1A1A2E)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.displayId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Delivery Task',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E).withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(data.status),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Status timeline
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatusTimeline(Data data) {
    final currentIdx = _statusIndex(data.status);
    final isFailed = ['failed', 'cancelled']
        .contains(data.status.trim().toLowerCase());

    if (isFailed) {
      return _card(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_rounded,
                  color: Color(0xFFFF3B30), size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              data.status.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF3B30),
              ),
            ),
          ],
        ),
      );
    }

    // Brand colour for delivery: purple
    const brand = Color(0xFF7C3AED);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROGRESS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8E8EA0),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(_statusOrder.length * 2 - 1, (i) {
              if (i.isOdd) {
                final lineIdx = i ~/ 2;
                final filled = lineIdx < currentIdx;
                return Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: filled ? brand : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
              final stepIdx = i ~/ 2;
              final isDone = stepIdx < currentIdx;
              final isCurrent = stepIdx == currentIdx;
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isCurrent ? 28 : 22,
                    height: isCurrent ? 28 : 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone || isCurrent
                          ? brand
                          : const Color(0xFFE5E7EB),
                      border: isCurrent
                          ? Border.all(
                              color: brand.withOpacity(0.3), width: 3)
                          : null,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: brand.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : _stepIcon(stepIdx),
                      size: isCurrent ? 14 : 11,
                      color: isDone || isCurrent
                          ? Colors.white
                          : const Color(0xFF8E8EA0),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stepShortLabel(stepIdx),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: isDone || isCurrent
                          ? brand
                          : const Color(0xFFB0B0C0),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _stepIcon(int idx) {
    const icons = [
      Icons.assignment_rounded,
      Icons.thumb_up_rounded,
      Icons.local_shipping_rounded,
      Icons.location_on_rounded,
      Icons.check_circle_rounded,
    ];
    return icons[idx.clamp(0, icons.length - 1)];
  }

  String _stepShortLabel(int idx) {
    const labels = ['Assigned', 'Accepted', 'Transit', 'Arrived', 'Done'];
    return labels[idx.clamp(0, labels.length - 1)];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Delivery location card  (navigate button)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDeliveryLocationCard(Data data, _Vendor? vendor) {
    final address = data.deliveryAddress.trim().isNotEmpty
        ? data.deliveryAddress.trim()
        : (vendor?.primaryAddress.trim() ?? 'Address not available');

    final date = data.scheduledDate;
    final timeSlot = data.scheduledTimeSlot.trim();

    // Show coords if available on vendor
    final lat = vendor?.latitude.trim() ?? '';
    final lng = vendor?.longitude.trim() ?? '';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel(label: 'DELIVERY LOCATION'),
              const Spacer(),
              // Navigate button
              GestureDetector(
                onTap: () => _openInGoogleMaps(data),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.navigation_rounded,
                          color: Colors.white, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'Navigate',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        height: 1.4,
                      ),
                    ),
                    if (lat.isNotEmpty && lng.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$lat, $lng',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8EA0),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (timeSlot.isNotEmpty || date != null) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFEEEEF5), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(
                  icon: Icons.calendar_today_rounded,
                  label: date != null
                      ? '${date.day.toString().padLeft(2, '0')} '
                          '${_monthShort(date.month)} ${date.year}'
                      : 'Scheduled',
                  color: const Color(0xFF7C3AED),
                ),
                if (timeSlot.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  _infoChip(
                    icon: Icons.access_time_rounded,
                    label: timeSlot,
                    color: const Color(0xFFFF9500),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Vendor card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildVendorCard(Data data, _Vendor vendor) {
    const brand = Color(0xFF7C3AED);
    final imageUrl = vendor.vendorPhotoUrl.trim();
    final mobile = data.deliveryContactNumber.trim().isNotEmpty
        ? data.deliveryContactNumber.trim()
        : vendor.mobile.trim();
    final businessType = vendor.businessType.trim();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'RECIPIENT'),
          const SizedBox(height: 14),
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: brand.withOpacity(0.08),
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.storefront_rounded,
                            color: Color(0xFF7C3AED), size: 26)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34C759),
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 2)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.shopName.isNotEmpty
                          ? vendor.shopName
                          : vendor.ownerName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (vendor.ownerName.isNotEmpty &&
                        vendor.shopName.isNotEmpty)
                      Text(
                        vendor.ownerName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8EA0),
                        ),
                      ),
                    if (businessType.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: brand.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          businessType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C3AED),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Call button
              if (mobile.isNotEmpty)
                GestureDetector(
                  onTap: () => _callContact(mobile),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.call_rounded,
                        color: Color(0xFF34C759), size: 22),
                  ),
                ),
            ],
          ),
          if (mobile.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFEEEEF5), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 14, color: Color(0xFF8E8EA0)),
                const SizedBox(width: 6),
                Text(
                  mobile,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                // Shop photo thumbnail if available
                if (vendor.shopPhotoUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      vendor.shopPhotoUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cargo card (simplified for delivery — no grade/photos)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCargoCard(Data data) {
    final crop = data.crop;
    final productName = crop.product.productName.trim();
    final weight = _formatWeight(
      crop.quantityKg.trim().isNotEmpty
          ? crop.quantityKg
          : data.expectedQuantityKg,
    );
    final notes = data.deliveryNotes.trim();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'DELIVERY MANIFEST'),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.inventory_2_rounded,
                    color: Color(0xFFFF9500), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName.isNotEmpty
                          ? _capitalise(productName)
                          : 'Cargo',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weight.isNotEmpty ? '$weight kg' : '—',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8E8EA0),
                      ),
                    ),
                  ],
                ),
              ),
              // Big weight badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    Text(
                      weight.isNotEmpty ? weight : '—',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const Text(
                      'KG',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7C3AED),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFEEEEF5), height: 1),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded,
                    size: 14, color: Color(0xFF8E8EA0)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    notes,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8EA0),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Order summary card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOrderSummaryCard(_Order order) {
    final isPaid = order.paymentStatus.trim().toLowerCase() == 'paid';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel(label: 'ORDER SUMMARY'),
              const Spacer(),
              // Payment status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFF34C759).withOpacity(0.1)
                      : const Color(0xFFFF9500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid
                          ? Icons.check_circle_rounded
                          : Icons.pending_rounded,
                      size: 11,
                      color: isPaid
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF9500),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.paymentStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isPaid
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF9500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (order.orderNumber.isNotEmpty)
            Text(
              order.orderNumber,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8EA0),
              ),
            ),
          const SizedBox(height: 16),
          // Amount breakdown
          _orderRow('Subtotal', '₹ ${order.subtotal}'),
          if (order.taxAmount.isNotEmpty && order.taxAmount != '0.00') ...[
            const SizedBox(height: 8),
            _orderRow(
              'Tax (${order.taxPercentage}%)',
              '₹ ${order.taxAmount}',
            ),
          ],
          if (order.deliveryCharges.isNotEmpty &&
              order.deliveryCharges != '0.00') ...[
            const SizedBox(height: 8),
            _orderRow('Delivery charges', '₹ ${order.deliveryCharges}'),
          ],
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFEEEEF5), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                '₹ ${order.finalAmount}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          if (order.expectedDeliveryDate != null) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFEEEEF5), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event_available_rounded,
                    size: 14, color: Color(0xFF8E8EA0)),
                const SizedBox(width: 6),
                Text(
                  'Expected by ${order.expectedDeliveryDate!.day} '
                  '${_monthShort(order.expectedDeliveryDate!.month)} '
                  '${order.expectedDeliveryDate!.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8EA0),
                  ),
                ),
              ],
            ),
          ],
          if (order.specialInstructions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: Color(0xFFFF9500)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.specialInstructions,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _orderRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8EA0),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Proof photo card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProofPhotoCard(Data data, ImageProvider proofImage) {
    final locationLabel = _verifiedLocationLabel ??
        _safeValue(data.deliveryAddress, 'Delivery location');

    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const _SectionLabel(label: 'DELIVERY PROOF'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.verified_rounded,
                          size: 11, color: Color(0xFF34C759)),
                      SizedBox(width: 4),
                      Text(
                        'VERIFIED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF34C759),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Stack(
              children: [
                Image(
                  image: proofImage,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Delivered to $locationLabel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Activity log
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActivityLog(Data data) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'ACTIVITY LOG'),
          const SizedBox(height: 14),
          ...data.statusHistory.reversed.map((h) {
            final time = h.createdAt;
            final timeStr = time != null
                ? '${time.hour.toString().padLeft(2, '0')}:'
                    '${time.minute.toString().padLeft(2, '0')} — '
                    '${time.day} ${_monthShort(time.month)}'
                : '';
            final isLast = data.statusHistory.reversed.last == h;
            return _activityRow(
              status: h.newStatus,
              time: timeStr,
              remarks: h.remarks?.toString() ?? '',
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _activityRow({
    required String status,
    required String time,
    required String remarks,
    required bool isLast,
  }) {
    final color = _statusColor(status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_activityIcon(status), size: 13, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFEEEEF5),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E8EA0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (remarks.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      remarks,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8EA0),
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _activityIcon(String status) {
    switch (status.trim().toLowerCase()) {
      case 'assigned':
        return Icons.assignment_rounded;
      case 'accepted':
        return Icons.thumb_up_rounded;
      case 'in_transit':
        return Icons.local_shipping_rounded;
      case 'reached':
        return Icons.location_on_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'failed':
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.circle;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom action bar  (2-step: Photo → OTP)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomBar(Data data, _Vendor? vendor) {
    final status = data.status.trim().toLowerCase();
    final isCompleted = status == 'completed';
    final isReached = status == 'reached';
    final isFailed = status == 'failed' || status == 'cancelled';
    final isProofLocked = _isProofTaken || isCompleted;

    String buttonText;
    VoidCallback? onPressed;
    Color buttonColor = const Color(0xFF7C3AED);

    if (isCompleted) {
      buttonText = 'DELIVERY COMPLETED';
      onPressed = () => Navigator.pop(context);
      buttonColor = const Color(0xFF34C759);
    } else if (isFailed) {
      buttonText = status.toUpperCase();
      onPressed = () => Navigator.pop(context);
      buttonColor = const Color(0xFFFF3B30);
    } else if (status == 'assigned') {
      buttonText = 'ACCEPT TASK';
      onPressed = () => _updateStatus('accepted');
    } else if (status == 'accepted') {
      buttonText = 'START JOURNEY';
      onPressed = () => _updateStatus('in_transit');
    } else if (status == 'in_transit') {
      buttonText = 'MARK ARRIVED';
      onPressed = () => _updateStatus('reached');
    } else if (isReached) {
      if (!_isProofTaken) {
        buttonText = 'CAPTURE PROOF PHOTO';
        onPressed = _startCapture;
      } else {
        buttonText = 'VERIFY & COMPLETE';
        onPressed = () => _submitProofAndShowOtp(data);
      }
    } else {
      buttonText = status.toUpperCase();
      onPressed = null;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 2-step tracker shown only while in reached state
          if (isReached && !isCompleted) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _stepHint(step: 1, label: 'Photo', done: _isProofTaken),
                  _stepConnector(),
                  _stepHint(step: 2, label: 'OTP', done: _isOtpVerified),
                ],
              ),
            ),
          ],
          Row(
            children: [
              // Camera quick button
              if (isReached || isCompleted) ...[
                GestureDetector(
                  onTap: isProofLocked ? null : _startCapture,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isProofLocked
                          ? const Color(0xFF34C759).withOpacity(0.1)
                          : const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isProofLocked
                            ? const Color(0xFF34C759).withOpacity(0.3)
                            : const Color(0xFFEEEEF5),
                      ),
                    ),
                    child: Icon(
                      isProofLocked
                          ? Icons.check_rounded
                          : Icons.camera_alt_rounded,
                      color: isProofLocked
                          ? const Color(0xFF34C759)
                          : const Color(0xFF8E8EA0),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              // Main CTA
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFEEEEF5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmittingProof
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
              // Navigate shortcut — always visible
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _openInGoogleMaps(data),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.2),
                    ),
                  ),
                  child: const Icon(Icons.navigation_rounded,
                      color: Color(0xFF7C3AED), size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepHint({
    required int step,
    required String label,
    required bool done,
  }) =>
      Expanded(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done
                    ? const Color(0xFF34C759)
                    : const Color(0xFFEEEEF5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 13, color: Colors.white)
                    : Text(
                        '$step',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8E8EA0),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: done
                    ? const Color(0xFF34C759)
                    : const Color(0xFF8E8EA0),
              ),
            ),
          ],
        ),
      );

  Widget _stepConnector() => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
          color: const Color(0xFFEEEEF5),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // OTP bottom sheet
  // ─────────────────────────────────────────────────────────────────────────
  void _showOtpBottomSheet(Data data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, _) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEF5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_open_rounded,
                      color: Color(0xFF7C3AED), size: 28),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Security Verification',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ask the recipient for the 4-digit OTP sent to their phone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF1A1A2E).withOpacity(0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _buildOtpField(i),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _solidButton(
                  label: 'VERIFY & CONFIRM',
                  color: const Color(0xFF7C3AED),
                  onTap:
                      _isVerifyingOtp ? null : () => _verifyOtp(data),
                  loading: _isVerifyingOtp,
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<int>(
                  valueListenable: _resendCountdown,
                  builder: (_, countdown, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        countdown > 0
                            ? 'Resend OTP in '
                            : "Didn't receive? ",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8EA0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (countdown > 0)
                        Text(
                          '${countdown}s',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C3AED),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => _resendOtp(data),
                          child: const Text(
                            'Resend Now',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7C3AED),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 58,
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? const Color(0xFF7C3AED)
              : const Color(0xFFEEEEF5),
          width: 2,
        ),
      ),
      child: KeyboardListener(
        focusNode:
            FocusNode(skipTraversal: true, canRequestFocus: false),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _otpControllers[index].text.isEmpty &&
              index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A2E),
          ),
          decoration: const InputDecoration(
              counterText: '', border: InputBorder.none),
          onChanged: (value) {
            if (value.isNotEmpty && index < 3) {
              _focusNodes[index + 1].requestFocus();
            }
            final otp = _otpControllers.map((c) => c.text).join();
            if (otp.length == 4 && !_isVerifyingOtp) {
              ref
                  .read(taskDetailControllerProvider(widget.taskId)
                      .notifier)
                  .fetch()
                  .then((detail) {
                if (detail != null && mounted) {
                  _verifyOtp(detail.data);
                }
              });
            }
          },
          onTap: () {
            _otpControllers[index].selection =
                TextSelection.fromPosition(TextPosition(
                    offset: _otpControllers[index].text.length));
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared UI helpers
  // ─────────────────────────────────────────────────────────────────────────
  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

  Widget _solidButton({
    required String label,
    required Color color,
    required VoidCallback? onTap,
    double height = 56,
    bool loading = false,
  }) =>
      SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFEEEEF5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      );

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Data helpers
  // ─────────────────────────────────────────────────────────────────────────
  ImageProvider? _resolveProofImage(Data data) {
    if (_capturedImagePath != null &&
        _capturedImagePath!.trim().isNotEmpty) {
      return FileImage(File(_capturedImagePath!));
    }
    final url = data.proofPhotoUrl.trim();
    if (url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  String _safeValue(String value, String fallback) {
    final t = value.trim();
    return t.isNotEmpty ? t : fallback;
  }

  String _formatWeight(String raw) {
    final n = raw.trim();
    if (n.isEmpty) return '';
    return n.toLowerCase().contains('kg')
        ? n.replaceAll(RegExp(r'(?i)kg'), '').trim()
        : n;
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ─────────────────────────────────────────────────────────────────────────
  // Status helpers
  // ─────────────────────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'assigned':
        return const Color(0xFFFF9500);
      case 'accepted':
        return const Color(0xFF7C3AED);
      case 'in_transit':
        return const Color(0xFF2563EB);
      case 'reached':
        return const Color(0xFF0EA5E9);
      case 'completed':
        return const Color(0xFF34C759);
      case 'failed':
      case 'cancelled':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF8E8EA0);
    }
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'assigned':
        return 'Assigned';
      case 'accepted':
        return 'Accepted';
      case 'in_transit':
        return 'In Transit';
      case 'reached':
        return 'Arrived';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _monthShort(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label widget
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF8E8EA0),
          letterSpacing: 1.2,
        ),
      );
}
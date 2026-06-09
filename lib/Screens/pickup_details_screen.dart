import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:delivery/widgets/custom_app_bar.dart';
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
// Status order for the progress timeline
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
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class PickupDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;
  const PickupDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<PickupDetailsScreen> createState() =>
      _PickupDetailsScreenState();
}

class _PickupDetailsScreenState extends ConsumerState<PickupDetailsScreen>
    with TickerProviderStateMixin {
  // ── Proof / procurement state ──────────────────────────────────────────────
  bool _isProofTaken = false;
  bool _procurementEntered = false;
  bool _didHydrateProcurement = false;
  String? _capturedImagePath;

  final TextEditingController _procuredQtyController = TextEditingController();
  final TextEditingController _procurementAmountController =
      TextEditingController();

  // ── OTP state ─────────────────────────────────────────────────────────────
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

  // ── Camera / picker ───────────────────────────────────────────────────────
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
    _procuredQtyController.dispose();
    _procurementAmountController.dispose();
    _resendCountdown.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  void _hydrateProcurementFromData(Data data) {
    final qty = data.actualQuantityKg?.toString().trim() ?? '';
    final amount = data.procurementAmount?.toString().trim() ?? '';
    if (qty.isNotEmpty && _procuredQtyController.text.isEmpty) {
      _procuredQtyController.text = qty;
    }
    if (amount.isNotEmpty && _procurementAmountController.text.isEmpty) {
      _procurementAmountController.text = amount;
    }
    if (qty.isNotEmpty && amount.isNotEmpty) _procurementEntered = true;
  }

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

  String _safeValue(String value, String fallback) {
    final t = value.trim();
    return t.isNotEmpty ? t : fallback;
  }

  String _formatWeight(String raw) {
    final n = raw.trim();
    if (n.isEmpty) return '';
    return n
        .toLowerCase()
        .contains('kg')
        ? n.replaceAll(RegExp(r'(?i)kg'), '').trim()
        : n;
  }

  bool _isStatusCompleted(Data data) =>
      data.status.trim().toLowerCase() == 'completed';

  ImageProvider? _resolveProofImage(Data data) {
    if (_capturedImagePath != null && _capturedImagePath!.trim().isNotEmpty) {
      return FileImage(File(_capturedImagePath!));
    }
    final url = data.proofPhotoUrl.trim();
    if (url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GPS → Google Maps
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _openInGoogleMaps(Data data) async {
    final lat = data.farmer.latitude.trim();
    final lng = data.farmer.longitude.trim();

    if (lat.isEmpty || lng.isEmpty) {
      // Fall back to address search
      final address = Uri.encodeComponent(data.pickupAddress.trim());
      final uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$address');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          CustomSnackBar.error(context, 'Could not open Google Maps.');
        }
      }
      return;
    }

    // Try the geo intent first (works on Android with Google Maps installed)
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Web fallback
    final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        CustomSnackBar.error(context, 'Could not open Google Maps.');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Phone call
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _callFarmer(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) CustomSnackBar.error(context, 'Could not launch dialler.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Location fetch
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
      // keep fallback
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
        if (mounted) {
          CustomSnackBar.success(context, 'Proof photo captured!');
        }
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Camera error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Proof submit + OTP flow
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _submitProofAndShowOtp(Data data) async {
    if (_isSubmittingProof) return;
    if (_expectedOtp.trim().isNotEmpty) {
      _showOtpBottomSheet(data);
      return;
    }
    if (_capturedImagePath == null) {
      CustomSnackBar.error(context, 'Please capture the pickup proof photo first.');
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

      final mobile = data.pickupContactNumber.trim();
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
    final mobile = data.pickupContactNumber.trim();
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

    final qty = double.tryParse(_procuredQtyController.text.trim());
    final amount =
        double.tryParse(_procurementAmountController.text.trim());
    if (qty == null || qty <= 0 || amount == null || amount <= 0) {
      CustomSnackBar.error(
          context, 'Enter procurement quantity and amount before verifying OTP');
      setState(() => _isVerifyingOtp = false);
      return;
    }

    try {
      final response = await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .verifyTaskOtp(
            otp: otp,
            actualQuantityKg: qty,
            procurementAmount: amount,
          );

      if (mounted) {
        Navigator.pop(context);
        setState(() => _isOtpVerified = true);
        ref.invalidate(taskRefreshTriggerProvider);
        CustomSnackBar.success(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Pickup Verified Successfully!',
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
        if (!_didHydrateProcurement) {
          _didHydrateProcurement = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _hydrateProcurementFromData(detail.data);
            setState(() {});
            _fadeCtrl.forward();
          });
        }
        return _buildMain(detail.data);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Loading
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLoading() => Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                _solidButton(
                  label: 'Retry',
                  color: const Color(0xFF2563EB),
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
    final proofImage = _resolveProofImage(data);
    final isCompleted = _isStatusCompleted(data);
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
                      const SizedBox(height: 20),
                      _buildPickupLocationCard(data),
                      const SizedBox(height: 14),
                      _buildFarmerCard(data),
                      const SizedBox(height: 14),
                      _buildCropCard(data),
                      if (showProof) ...[
                        const SizedBox(height: 14),
                        _buildProofPhotoCard(data, proofImage),
                      ],
                      if (_hasProcurementSummary(data)) ...[
                        const SizedBox(height: 14),
                        _buildProcurementCard(data),
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
      bottomSheet: _buildBottomBar(data),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(Data data) {
    final statusColor = _statusBadgeColor(data.status);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEF5), width: 1),
        ),
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
                  'Pickup Task',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E).withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                // Connector line
                final lineIdx = i ~/ 2;
                final filled = lineIdx < currentIdx;
                return Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: filled
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE5E7EB),
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
                      color: isDone
                          ? const Color(0xFF2563EB)
                          : isCurrent
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE5E7EB),
                      border: isCurrent
                          ? Border.all(
                              color: const Color(0xFF2563EB).withOpacity(0.3),
                              width: 3,
                            )
                          : null,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.3),
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
                          ? const Color(0xFF2563EB)
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
  // Pickup location card  (with GPS button)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPickupLocationCard(Data data) {
    final address = _safeValue(data.pickupAddress, 'Address not available');
    final timeSlot = data.scheduledTimeSlot.trim();
    final date = data.scheduledDate;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel(label: 'PICKUP LOCATION'),
              const Spacer(),
              // ── Google Maps button ────────────────────────────────────────
              GestureDetector(
                onTap: () => _openInGoogleMaps(data),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A73E8).withOpacity(0.35),
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
                  color: const Color(0xFF34C759).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_pin,
                    color: Color(0xFF34C759), size: 20),
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
                    if (data.farmer.latitude.isNotEmpty &&
                        data.farmer.longitude.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${data.farmer.latitude}, ${data.farmer.longitude}',
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
                  color: const Color(0xFF2563EB),
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

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
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
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Farmer card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFarmerCard(Data data) {
    final farmer = data.farmer;
    final name = _safeValue(farmer.fullName, 'Farmer');
    final mobile = data.pickupContactNumber.trim();
    final imageUrl = farmer.profilePhotoUrl.trim();
    final landInfo = farmer.totalLand.isNotEmpty
        ? '${farmer.totalLand} ${farmer.landUnit}'
        : '';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'FARMER'),
          const SizedBox(height: 14),
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFEEF2FF),
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.person_rounded,
                            color: Color(0xFF2563EB), size: 28)
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
                          BorderSide(color: Colors.white, width: 2),
                        ),
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
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (landInfo.isNotEmpty)
                      Text(
                        '$landInfo farmland',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8EA0),
                        ),
                      ),
                  ],
                ),
              ),
              // Call button
              if (mobile.isNotEmpty)
                GestureDetector(
                  onTap: () => _callFarmer(mobile),
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
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Crop / cargo card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCropCard(Data data) {
    final crop = data.crop;
    final product = crop.product;
    final productName = _safeValue(product.productName, 'Crop');
    final grade = crop.grade.trim().toUpperCase();
    final expectedQty = _formatWeight(
      crop.quantityKg.isNotEmpty ? crop.quantityKg : data.expectedQuantityKg,
    );
    final expectedPrice = crop.expectedPricePerKg.trim();

    // Crop photos
    List<String> cropPhotos = [];
    try {
      final raw = crop.cropPhotoUrl.trim();
      if (raw.startsWith('[')) {
        final decoded = (jsonDecodePhotos(raw));
        cropPhotos = decoded.whereType<String>().toList();
      } else if (raw.isNotEmpty) {
        cropPhotos = [raw];
      }
    } catch (_) {}

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'CARGO DETAILS'),
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
                child: const Icon(Icons.eco_rounded,
                    color: Color(0xFFFF9500), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName[0].toUpperCase() +
                          productName.substring(1),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (grade.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'GRADE $grade',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _statBox(
                  label: 'Expected Qty',
                  value: expectedQty.isNotEmpty ? '$expectedQty kg' : '—',
                  icon: Icons.scale_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  label: 'Expected Price',
                  value: expectedPrice.isNotEmpty ? '₹$expectedPrice' : '—',
                  icon: Icons.currency_rupee_rounded,
                  color: const Color(0xFF34C759),
                ),
              ),
            ],
          ),
          // Crop photos strip
          if (cropPhotos.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cropPhotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    cropPhotos[i],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: const Color(0xFFEEEEF5),
                      child: const Icon(Icons.broken_image_rounded,
                          color: Color(0xFF8E8EA0)),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (data.deliveryNotes.isNotEmpty) ...[
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
                    data.deliveryNotes,
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

  Widget _statBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
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
  // Proof photo card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProofPhotoCard(Data data, ImageProvider proofImage) {
    final locationLabel = _verifiedLocationLabel ??
        _safeValue(data.pickupAddress, 'Pickup location');

    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const _SectionLabel(label: 'PROOF PHOTO'),
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
                            'Verified at $locationLabel',
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
  // Procurement summary card
  // ─────────────────────────────────────────────────────────────────────────
  bool _hasProcurementSummary(Data data) {
    final qty = data.actualQuantityKg?.toString().trim() ?? '';
    final amount = data.procurementAmount?.toString().trim() ?? '';
    return qty.isNotEmpty || amount.isNotEmpty;
  }

  Widget _buildProcurementCard(Data data) {
    final qty = data.actualQuantityKg?.toString().trim() ?? '—';
    final amount = data.procurementAmount?.toString().trim() ?? '—';
    final perKg = data.procurementPricePerKg?.toString().trim();
    final pending = data.procurementStatus.trim() == 'pending_review';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel(label: 'PROCUREMENT RECORD'),
              const Spacer(),
              if (pending)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PENDING REVIEW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF9500),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'RECORDED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF34C759),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  label: 'Actual Qty',
                  value: '$qty kg',
                  icon: Icons.scale_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  label: 'Total Amount',
                  value: '₹$amount',
                  icon: Icons.currency_rupee_rounded,
                  color: const Color(0xFF34C759),
                ),
              ),
            ],
          ),
          if (perKg != null && perKg.isNotEmpty) ...[
            const SizedBox(height: 10),
            _statBox(
              label: 'Rate per kg',
              value: '₹$perKg / kg',
              icon: Icons.price_change_rounded,
              color: const Color(0xFF9B59B6),
            ),
          ],
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
            final isLast =
                data.statusHistory.reversed.last == h;
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
    final color = _statusBadgeColor(status);
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
  // Bottom action bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomBar(Data data) {
    final status = data.status.trim().toLowerCase();
    final isCompleted = status == 'completed';
    final isReached = status == 'reached';
    final isFailed =
        status == 'failed' || status == 'cancelled';
    final isProofLocked = _isProofTaken || isCompleted;

    String buttonText;
    VoidCallback? onPressed;
    Color buttonColor = const Color(0xFF2563EB);

    if (isCompleted) {
      buttonText = 'PICKUP COMPLETED';
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
      } else if (!_procurementEntered) {
        buttonText = 'ENTER PROCUREMENT';
        onPressed = () => _showProcurementBottomSheet(data);
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
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
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
          // Step hints for 'reached' state
          if (isReached && !isCompleted) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _stepHint(
                    step: 1,
                    label: 'Photo',
                    done: _isProofTaken,
                  ),
                  _stepConnector(),
                  _stepHint(
                    step: 2,
                    label: 'Procurement',
                    done: _procurementEntered,
                  ),
                  _stepConnector(),
                  _stepHint(
                    step: 3,
                    label: 'OTP',
                    done: _isOtpVerified,
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              // Camera quick-button for reached/completed states
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
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFFEEEEF5),
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
              // Navigate shortcut always visible
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _openInGoogleMaps(data),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1A73E8).withOpacity(0.2),
                    ),
                  ),
                  child: const Icon(Icons.navigation_rounded,
                      color: Color(0xFF1A73E8), size: 22),
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
  }) {
    return Expanded(
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
  }

  Widget _stepConnector() => Expanded(
        child: Container(
          height: 2,
          margin:
              const EdgeInsets.only(bottom: 16, left: 4, right: 4),
          color: const Color(0xFFEEEEF5),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Procurement bottom sheet
  // ─────────────────────────────────────────────────────────────────────────
  void _showProcurementBottomSheet(Data data) {
    final expectedQty = _formatWeight(data.expectedQuantityKg);
    if (_procuredQtyController.text.trim().isEmpty &&
        expectedQty.isNotEmpty) {
      _procuredQtyController.text = expectedQty;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEF5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'PROCUREMENT DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8E8EA0),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter quantity and amount agreed with farmer',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 24),
              _inputField(
                controller: _procuredQtyController,
                label: 'Actual quantity (kg)',
                suffix: 'KG',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 14),
              _inputField(
                controller: _procurementAmountController,
                label: 'Procurement amount',
                prefix: '₹',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              _solidButton(
                label: 'SAVE & CONTINUE',
                color: const Color(0xFF2563EB),
                onTap: () {
                  final qty = double.tryParse(
                      _procuredQtyController.text.trim());
                  final amount = double.tryParse(
                      _procurementAmountController.text.trim());
                  if (qty == null || qty <= 0) {
                    CustomSnackBar.error(
                        ctx, 'Enter a valid quantity');
                    return;
                  }
                  if (amount == null || amount <= 0) {
                    CustomSnackBar.error(
                        ctx, 'Enter a valid amount');
                    return;
                  }
                  setState(() => _procurementEntered = true);
                  Navigator.pop(ctx);
                  CustomSnackBar.success(context,
                      'Procurement details saved. Complete pickup with OTP.');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboard,
    String? prefix,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFF8E8EA0),
        ),
        prefixText: prefix != null ? '$prefix ' : null,
        suffixText: suffix,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEEEEF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OTP bottom sheet
  // ─────────────────────────────────────────────────────────────────────────
  void _showOtpBottomSheet(Data data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_open_rounded,
                      color: Color(0xFF2563EB), size: 28),
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
                  'Ask the farmer for the 4-digit OTP sent to their phone',
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
                  color: const Color(0xFF2563EB),
                  onTap: _isVerifyingOtp
                      ? null
                      : () => _verifyOtp(data),
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
                            color: Color(0xFF2563EB),
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
                              color: Color(0xFF2563EB),
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
              ? const Color(0xFF2563EB)
              : const Color(0xFFEEEEF5),
          width: 2,
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
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
            counterText: '',
            border: InputBorder.none,
          ),
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
  Widget _card({required Widget child, EdgeInsets? padding}) =>
      Container(
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

  // ─────────────────────────────────────────────────────────────────────────
  // Status helpers
  // ─────────────────────────────────────────────────────────────────────────
  Color _statusBadgeColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'assigned':
        return const Color(0xFFFF9500);
      case 'accepted':
        return const Color(0xFF2563EB);
      case 'in_transit':
        return const Color(0xFF9B59B6);
      case 'reached':
        return const Color(0xFF1A73E8);
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

  // ─────────────────────────────────────────────────────────────────────────
  // Date helpers
  // ─────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Crop photo URL parser helper (JSON array stored as string)
// ─────────────────────────────────────────────────────────────────────────────
List jsonDecodePhotos(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded;
  } catch (_) {}
  return [];
}
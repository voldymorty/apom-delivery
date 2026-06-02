import 'dart:async';
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

class DeliveryDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;

  const DeliveryDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<DeliveryDetailsScreen> createState() =>
      _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends ConsumerState<DeliveryDetailsScreen> {
  bool _isProofTaken = false;
  String? _capturedImagePath;
  final ImagePicker _picker = ImagePicker();
  bool _isOtpVerified = false;
  bool _isSubmittingProof = false;
  bool _isVerifyingOtp = false;
  String _expectedOtp = '';
  String? _verifiedLocationLabel;
  bool _isFetchingLocation = false;
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  Timer? _resendTimer;
  final ValueNotifier<int> _resendCountdown = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendCountdown.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendCountdown.value = 30;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown.value == 0) {
        timer.cancel();
      } else {
        _resendCountdown.value--;
      }
    });
  }

  Future<void> _resendOtp(Data data) async {
    if (_resendCountdown.value > 0) return;

    final mobile = data.deliveryContactNumber.trim();
    if (mobile.isEmpty || _expectedOtp.trim().isEmpty) return;

    try {
      final success = await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .sendOtpSms(
            mobileNumber: mobile,
            otp: _expectedOtp,
          );

      if (mounted) {
        if (success) {
          _startResendTimer();
          CustomSnackBar.success(context, 'OTP resent successfully!');
        } else {
          CustomSnackBar.error(context, 'Failed to resend OTP.');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Error resending OTP: $e');
      }
    }
  }

  void _reloadDetail() {
    ref.read(taskDetailControllerProvider(widget.taskId).notifier).fetch();
  }

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
          CustomSnackBar.success(
            context,
            'Delivery Photo Captured!',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(
          context,
          'Error launching camera: $e',
        );
      }
    }
  }

  Future<void> _submitProofAndShowOtp(Data data) async {
    if (_isSubmittingProof) return;
    if (_expectedOtp.trim().isNotEmpty) {
      _showOtpBottomSheet(data);
      return;
    }
    if (_capturedImagePath == null) {
      CustomSnackBar.error(
        context,
        'Please capture the delivery proof photo first.',
      );
      return;
    }

    setState(() {
      _isSubmittingProof = true;
    });

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Error getting location for proof upload: $e');
    }

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
            .sendOtpSms(
              mobileNumber: mobile,
              otp: _expectedOtp,
            );
        if (mounted && !smsOk) {
          CustomSnackBar.error(
            context,
            'Failed to send OTP SMS. Please share the OTP manually.',
          );
        }
      }

      if (mounted) {
        _startResendTimer();
        _showOtpBottomSheet(data);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(
          context,
          'Proof upload failed: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingProof = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(taskDetailControllerProvider(widget.taskId));

    return detailAsync.when(
      loading: _buildLoadingScaffold,
      error: (error, _) => _buildErrorScaffold(error),
      data: (detail) => _buildContentScaffold(detail.data),
    );
  }

  Scaffold _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Scaffold _buildErrorScaffold(Object? error) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load delivery details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary.withOpacity(0.7),
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
                onPressed: _reloadDetail,
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
      ),
    );
  }

  Scaffold _buildContentScaffold(Data data) {
    final displayId =
        data.displayId.isNotEmpty ? data.displayId : widget.taskId.trim();
    final isStatusConfirmed = _isStatusConfirmed(data);
    final proofImage = _resolveProofImage(data);
    final shouldShowProof =
        proofImage != null && (_isProofTaken || isStatusConfirmed);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                   CustomAppBar(
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: 'DELIVERY: #$displayId',
                    subtitle: 'DISTRIBUTION PROTOCOL',
                    centerTitle: true,
                    reverseTitleOrder: true,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildPathSection(data),
                          const SizedBox(height: 30),
                          _buildCustomerCard(data),
                          if (shouldShowProof) ...[
                            const SizedBox(height: 30),
                            _buildCapturedPhoto(data, proofImage),
                          ],
                          const SizedBox(height: 30),
                          _buildManifestChecklist(data),
                          const SizedBox(height: 120), // Space for bottom bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomActionBar(data),
    );
  }

  Widget _buildCapturedPhoto(Data data, ImageProvider proofImage) {
    final locationLabel =
        _verifiedLocationLabel ??
        _safeValue(
          data.deliveryAddress,
          'Delivery location',
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'DELIVERY PROOF PHOTO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Spacer(),
            Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
            SizedBox(width: 4),
            Text(
              'VERIFIED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(
              image: proofImage,
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
              ),
            ),
            padding: const EdgeInsets.all(20),
            alignment: Alignment.bottomLeft,
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Delivered to $locationLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPathSection(Data data) {
    final dropOffTitle = data.deliveryTitle;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildPointRow(
              title: dropOffTitle,
              address: _safeValue(data.deliveryAddress, 'Delivery address'),
              label: 'DROP-OFF POINT',
              icon: Icons.local_shipping_rounded,
              iconColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointRow({
    required String title,
    required String address,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: iconColor.withOpacity(0.5),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                address,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(Data data) {
    final name = data.deliveryTitle;
    final contact = data.deliveryContactNumber.trim();
    final addressLabel = _safeValue(data.deliveryAddress, 'Destination');
    final subtitle = contact.isNotEmpty ? contact : addressLabel;
    final imageUrl = data.farmer.profilePhotoUrl.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple.withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.background,
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child:
                  imageUrl.isNotEmpty
                      ? null
                      : const Icon(Icons.person_rounded, color: Colors.purple),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary.withOpacity(0.4),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.info_outline_rounded, color: Colors.purple, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildManifestChecklist(Data data) {
    final items = _buildManifestItems(data);
    final totalWeight = _formatWeight(data.expectedQuantityKg);
    final summary = _buildManifestSummary(items.length, totalWeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Manifest',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          summary,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondary.withOpacity(0.4),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 24),
        if (items.isEmpty)
          Text(
            'No manifest details available',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          )
        else
          ...items.map(
            (item) => _buildManifestItem(
              name: item.name,
              weight: item.weight,
              count: item.count,
              icon: item.icon,
            ),
          ),
      ],
    );
  }

  Widget _buildManifestItem({
    required String name,
    required String weight,
    required String count,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (count.trim().isNotEmpty)
                  Text(
                    count,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            weight.isNotEmpty ? '$weight KG' : '-',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(Data data) {
    final status = data.status.trim().toLowerCase();
    final isCompleted = status == 'completed';
    final isReached = status == 'reached';
    final isFailed = status == 'failed' || status == 'cancelled';
    final isProofLocked = _isProofTaken || isCompleted;

    String buttonText = '';
    VoidCallback? onPressed;
    Color buttonColor = AppColors.deliveryColor;

    if (isCompleted) {
      buttonText = 'DELIVERY COMPLETED';
      onPressed = () => Navigator.pop(context);
      buttonColor = AppColors.success;
    } else if (isFailed) {
      buttonText = 'FAILED';
      onPressed = () => Navigator.pop(context);
      buttonColor = AppColors.error;
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
      buttonText = _isProofTaken ? 'COMPLETE DELIVERY' : 'TAKE DELIVERY PROOF';
      onPressed = () {
        if (_isProofTaken) {
          _submitProofAndShowOtp(data);
        } else {
          _startCapture();
        }
      };
    } else {
      buttonText = status.toUpperCase();
      onPressed = null;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (isReached || isCompleted) ...[
                GestureDetector(
                  onTap: isProofLocked ? null : _startCapture,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: isProofLocked
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isProofLocked
                          ? Icons.check_circle_rounded
                          : Icons.photo_camera_rounded,
                      color: isProofLocked ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.1),
                    minimumSize: const Size(0, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isSubmittingProof
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .updateTaskStatus(status: newStatus);
      ref.invalidate(taskRefreshTriggerProvider);
      _reloadDetail();
      if (mounted) {
        CustomSnackBar.success(context, 'Status updated to ${newStatus.toUpperCase()}');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Failed to update status: $e');
      }
    }
  }

  void _showOtpBottomSheet(Data data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'SECURITY VERIFICATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter Delivery OTP',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask the recipient for the 4-digit code',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) => _buildOtpField(index)),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isVerifyingOtp ? null : () => _verifyOtp(data),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deliveryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: _isVerifyingOtp
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'VERIFY & CONFIRM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<int>(
                    valueListenable: _resendCountdown,
                    builder: (context, countdown, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            countdown > 0
                                ? "Resend OTP in "
                                : "Didn't receive OTP? ",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (countdown > 0)
                            Text(
                              "$countdown s",
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.deliveryColor,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () => _resendOtp(data),
                              child: const Text(
                                "Resend Now",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.deliveryColor,
                                  fontWeight: FontWeight.w900,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 60,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? AppColors.deliveryColor
              : AppColors.textSecondary.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(
          skipTraversal: true,
          canRequestFocus: false,
        ), // Listener's own focus node
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
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
          decoration:
              const InputDecoration(counterText: "", border: InputBorder.none),
          onChanged: (value) {
            if (value.isNotEmpty && index < 3) {
              _focusNodes[index + 1].requestFocus();
            }

            final otp = _otpControllers.map((e) => e.text).join();
            if (otp.length == 4 && !_isVerifyingOtp) {
              ref
                  .read(taskDetailControllerProvider(widget.taskId).notifier)
                  .fetch()
                  .then((detail) {
                if (detail != null) {
                  _verifyOtp(detail.data);
                }
              });
            }
          },
          onTap: () {
            _otpControllers[index].selection = TextSelection.fromPosition(
              TextPosition(offset: _otpControllers[index].text.length),
            );
          },
        ),
      ),
    );
  }

  Future<void> _verifyOtp(Data data) async {
    final otp = _otpControllers.map((e) => e.text).join();
    if (otp.length != 4) {
      CustomSnackBar.error(
        context,
        'Enter the 4-digit OTP',
      );
      return;
    }

    final expectedOtp =
        _expectedOtp.trim().isNotEmpty
            ? _expectedOtp.trim()
            : data.otpCode.trim();
    if (expectedOtp.isNotEmpty && otp != expectedOtp) {
      CustomSnackBar.error(
        context,
        'Invalid OTP. Please try again.',
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final response = await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .verifyTaskOtp(
            otp: otp,
          );

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        setState(() {
          _isOtpVerified = true;
        });
        ref.invalidate(taskRefreshTriggerProvider);
        CustomSnackBar.success(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Delivery Verified Successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(
          context,
          'OTP verification failed: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }

  String _safeValue(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty ? trimmed : fallback;
  }

  String _formatWeight(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return '';
    final lower = normalized.toLowerCase();
    if (lower.contains('kg')) {
      return normalized.replaceAll(RegExp(r'(?i)kg'), '').trim();
    }
    return normalized;
  }

  String _buildManifestSummary(int count, String totalWeight) {
    final countLabel = count == 0
        ? 'NO ITEMS'
        : '$count ITEM${count == 1 ? '' : 'S'}';
    if (totalWeight.trim().isEmpty) return countLabel;
    return '$countLabel - TOTAL $totalWeight KG';
  }

  Future<void> _loadCurrentLocation() async {
    if (_isFetchingLocation) return;
    setState(() {
      _isFetchingLocation = true;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final formatted = _formatPlacemark(placemarks);
      if (formatted.isNotEmpty) {
        if (mounted) {
          setState(() {
            _verifiedLocationLabel = formatted;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _verifiedLocationLabel =
              '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (_) {
      // Keep fallback address if location fails.
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  String _formatPlacemark(List<Placemark> placemarks) {
    if (placemarks.isEmpty) return '';
    final place = placemarks.first;
    final parts = [
      place.street,
      place.subLocality,
      place.locality,
      place.administrativeArea,
    ]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  bool _isStatusConfirmed(Data data) {
    final normalized = data.status.trim().toLowerCase();
    return normalized == 'completed';
  }

  ImageProvider? _resolveProofImage(Data data) {
    if (_capturedImagePath != null && _capturedImagePath!.trim().isNotEmpty) {
      return FileImage(File(_capturedImagePath!));
    }
    final url = data.proofPhotoUrl.trim();
    if (url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  List<_ManifestItem> _buildManifestItems(Data data) {
    final items = <_ManifestItem>[];
    final crop = data.crop;
    final productName = crop.product.productName.trim();
    final weight = _formatWeight(
      crop.quantityKg.trim().isNotEmpty
          ? crop.quantityKg
          : data.expectedQuantityKg,
    );

    if (productName.isNotEmpty || weight.isNotEmpty) {
      items.add(
        _ManifestItem(
          name: productName.isNotEmpty ? productName : 'Cargo',
          weight: weight,
          count: _resolveManifestNotes(data),
          icon: Icons.inventory_2_rounded,
        ),
      );
    }

    return items;
  }

  String _resolveManifestNotes(Data data) {
    final notes = data.deliveryNotes.trim();
    if (notes.isNotEmpty) return notes;
    final slot = data.scheduledTimeSlot.trim();
    if (slot.isNotEmpty) return slot;
    return '';
  }
}

class _ManifestItem {
  final String name;
  final String weight;
  final String count;
  final IconData icon;

  const _ManifestItem({
    required this.name,
    required this.weight,
    required this.count,
    required this.icon,
  });
}

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

class PickupDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;

  const PickupDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<PickupDetailsScreen> createState() =>
      _PickupDetailsScreenState();
}

class _PickupDetailsScreenState extends ConsumerState<PickupDetailsScreen> {
  bool _isProofTaken = false;
  bool _procurementEntered = false;
  bool _didHydrateProcurement = false;
  String? _capturedImagePath;
  final TextEditingController _procuredQtyController = TextEditingController();
  final TextEditingController _procurementAmountController =
      TextEditingController();
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
    _procuredQtyController.dispose();
    _procurementAmountController.dispose();
    _resendCountdown.dispose();
    super.dispose();
  }

  void _hydrateProcurementFromData(Data data) {
    final qty = data.actualQuantityKg?.toString().trim() ?? '';
    final amount = data.procurementAmount?.toString().trim() ?? '';
    if (qty.isNotEmpty && _procuredQtyController.text.isEmpty) {
      _procuredQtyController.text = qty;
    }
    if (amount.isNotEmpty && _procurementAmountController.text.isEmpty) {
      _procurementAmountController.text = amount;
    }
    if (qty.isNotEmpty && amount.isNotEmpty) {
      _procurementEntered = true;
    }
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

    final mobile = data.pickupContactNumber.trim();
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
        imageQuality: 70, // Optimize image size
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
            'Verification Photo Captured!',
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
        'Please capture the pickup proof photo first.',
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

      final mobile = data.pickupContactNumber.trim();
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
      data: (detail) {
        if (!_didHydrateProcurement) {
          _didHydrateProcurement = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _hydrateProcurementFromData(detail.data);
            setState(() {});
          });
        }
        return _buildContentScaffold(detail.data);
      },
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
                'Failed to load pickup details',
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
                    title: 'PICKUP: #$displayId',
                    subtitle: 'COLLECTION PROTOCOL',
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
                          _buildProducerCard(data),
                          if (shouldShowProof) ...[
                            const SizedBox(height: 30),
                            _buildCapturedPhoto(data, proofImage),
                          ],
                          const SizedBox(height: 30),
                          _buildCargoChecklist(data),
                          if (_hasProcurementSummary(data)) ...[
                            const SizedBox(height: 30),
                            _buildProcurementSummary(data),
                          ],
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
          data.pickupAddress,
          'Pickup location',
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'PICKUP VERIFICATION PHOTO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Spacer(),
            Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
            SizedBox(width: 4),
            Text(
              'TIMESTAMPED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.blue,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
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
                    'Verified at $locationLabel',
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
    final pickupTitle = data.pickupTitle;
    final deliveryTitle = data.deliveryTitle;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 40,
            top: 60,
            bottom: 60,
            child: SizedBox(
              width: 1.5,
              child: Column(
                children: List.generate(
                  15,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      width: 1.5,
                      decoration: BoxDecoration(
                        color:
                            index % 2 == 0
                                ? AppColors.deliveryColor.withOpacity(0.2)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildPointRow(
                  isPickup: true,
                  title: pickupTitle,
                  address: _safeValue(data.pickupAddress, 'Pickup address'),
                  icon: Icons.inventory_2_rounded,
                  iconColor: Colors.orange,
                ),
                const SizedBox(height: 48),
                _buildPointRow(
                  isPickup: false,
                  title: deliveryTitle,
                  address: _safeValue(data.deliveryAddress, 'Delivery address'),
                  icon: Icons.warehouse_rounded,
                  iconColor: AppColors.deliveryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointRow({
    required bool isPickup,
    required String title,
    required String address,
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
            border: Border.all(color: iconColor.withOpacity(0.2), width: 1.5),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPickup ? 'COLLECTION POINT' : 'DISTRIBUTION CENTER',
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

  Widget _buildProducerCard(Data data) {
    final name = data.pickupTitle;
    final subTitle = _safeValue(data.farmer.farmName, data.pickupAddress);
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
              border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.background,
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child:
                  imageUrl.isNotEmpty
                      ? null
                      : const Icon(Icons.person_rounded, color: Colors.blue),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subTitle,
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
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.call_rounded, color: Colors.blue, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoChecklist(Data data) {
    final items = _buildCargoItems(data);
    final totalWeight = _formatWeight(data.expectedQuantityKg);
    final summary = _buildCargoSummary(items.length, totalWeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cargo Inventory',
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
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (items.isEmpty)
          Text(
            'No cargo details available',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          )
        else
          ...items.map(
            (item) => _buildCargoItem(
              name: item.name,
              category: item.category,
              weight: item.weight,
              count: item.count,
              icon: item.icon,
              iconColor: item.iconColor,
            ),
          ),
      ],
    );
  }

  Widget _buildCargoItem({
    required String name,
    required String category,
    required String weight,
    required String count,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
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
                if (category.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: iconColor.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    weight,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'KG',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
              if (count.trim().isNotEmpty)
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary.withOpacity(0.4),
                  ),
                ),
            ],
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
      buttonText = 'PICKUP COMPLETED';
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
      if (!_isProofTaken) {
        buttonText = 'TAKE LOADING PROOF';
        onPressed = _startCapture;
      } else if (!_procurementEntered) {
        buttonText = 'ENTER PROCUREMENT';
        onPressed = () => _showProcurementBottomSheet(data);
      } else {
        buttonText = 'COMPLETE PICKUP';
        onPressed = () => _submitProofAndShowOtp(data);
      }
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isProofLocked ? Colors.blue.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isProofLocked ? Colors.blue.withOpacity(0.2) : AppColors.textSecondary.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      isProofLocked ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
                      color: isProofLocked ? Colors.blue : AppColors.textSecondary,
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
                    elevation: 0,
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

  bool _hasProcurementSummary(Data data) {
    final qty = data.actualQuantityKg?.toString().trim() ?? '';
    final amount = data.procurementAmount?.toString().trim() ?? '';
    return qty.isNotEmpty || amount.isNotEmpty;
  }

  Widget _buildProcurementSummary(Data data) {
    final qty = data.actualQuantityKg?.toString().trim() ?? '—';
    final amount = data.procurementAmount?.toString().trim() ?? '—';
    final perKg = data.procurementPricePerKg?.toString().trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Procurement Recorded',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _procurementRow('Quantity procured', '$qty kg'),
          const SizedBox(height: 8),
          _procurementRow('Procurement amount', '₹ $amount'),
          if (perKg != null && perKg.isNotEmpty) ...[
            const SizedBox(height: 8),
            _procurementRow('Rate', '₹ $perKg / kg'),
          ],
          if (data.procurementStatus.trim() == 'pending_review') ...[
            const SizedBox(height: 12),
            Text(
              'Awaiting admin inspection at warehouse',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _procurementRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showProcurementBottomSheet(Data data) {
    final expectedQty = _formatWeight(data.expectedQuantityKg);
    if (_procuredQtyController.text.trim().isEmpty && expectedQty.isNotEmpty) {
      _procuredQtyController.text = expectedQty;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'PROCUREMENT DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter quantity and amount agreed with farmer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _procuredQtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Actual quantity (kg)',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _procurementAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Procurement amount (₹ total)',
                    prefixText: '₹ ',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(
                      _procuredQtyController.text.trim(),
                    );
                    final amount = double.tryParse(
                      _procurementAmountController.text.trim(),
                    );
                    if (qty == null || qty <= 0) {
                      CustomSnackBar.error(
                        context,
                        'Enter a valid procured quantity',
                      );
                      return;
                    }
                    if (amount == null || amount <= 0) {
                      CustomSnackBar.error(
                        context,
                        'Enter a valid procurement amount',
                      );
                      return;
                    }
                    setState(() {
                      _procurementEntered = true;
                    });
                    Navigator.pop(context);
                    CustomSnackBar.success(
                      context,
                      'Procurement details saved. Complete pickup with OTP.',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deliveryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SAVE & CONTINUE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
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
                    'Enter Pickup OTP',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask the producer for the 4-digit code',
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

    final qty = double.tryParse(_procuredQtyController.text.trim());
    final amount = double.tryParse(_procurementAmountController.text.trim());
    if (qty == null || qty <= 0 || amount == null || amount <= 0) {
      CustomSnackBar.error(
        context,
        'Enter procurement quantity and amount before verifying OTP',
      );
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
        Navigator.pop(context); // Close bottom sheet
        setState(() {
          _isOtpVerified = true;
        });
        ref.invalidate(taskRefreshTriggerProvider);
        CustomSnackBar.success(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Pickup Verified Successfully!',
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

  String _buildCargoSummary(int count, String totalWeight) {
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

  List<_CargoItem> _buildCargoItems(Data data) {
    final items = <_CargoItem>[];
    final crop = data.crop;
    final productName = crop.product.productName.trim();
    final grade = crop.grade.trim();
    final weight = _formatWeight(
      crop.quantityKg.trim().isNotEmpty
          ? crop.quantityKg
          : data.expectedQuantityKg,
    );

    if (productName.isNotEmpty || weight.isNotEmpty) {
      items.add(
        _CargoItem(
          name: productName.isNotEmpty ? productName : 'Crop',
          category: grade.isNotEmpty ? grade.toUpperCase() : 'CROP',
          weight: weight.isNotEmpty ? weight : '-',
          count: _resolveCargoNotes(data),
          icon: Icons.inventory_2_rounded,
          iconColor: AppColors.deliveryColor,
        ),
      );
    }

    return items;
  }

  String _resolveCargoNotes(Data data) {
    final notes = data.deliveryNotes.trim();
    if (notes.isNotEmpty) return notes;
    final slot = data.scheduledTimeSlot.trim();
    if (slot.isNotEmpty) return slot;
    return '';
  }
}

class _CargoItem {
  final String name;
  final String category;
  final String weight;
  final String count;
  final IconData icon;
  final Color iconColor;

  const _CargoItem({
    required this.name,
    required this.category,
    required this.weight,
    required this.count,
    required this.icon,
    required this.iconColor,
  });
}

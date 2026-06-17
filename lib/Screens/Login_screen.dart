import 'package:delivery/Screens/Forgot_pass_screen.dart';
import 'package:delivery/Screens/bottom_navigation_screen.dart';
import 'package:delivery/repository/login_repository.dart';
import 'package:delivery/widgets/custom_snackbar.dart';
import 'package:delivery/widgets/custom_text_field.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/notify_Service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final mobile = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final fcmToken = await NotificationService().getToken();

    final result = await ref.read(loginControllerProvider.notifier).login(
      mobile: mobile,
      password: password,
      fcmToken: fcmToken,
    );

    if (!mounted) {
      return;
    }

    final state = ref.read(loginControllerProvider);
    state.whenOrNull(
      error: (error, _) {
        CustomSnackBar.error(context, error.toString());
      },
    );

    if (result?.success == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
      return;
    }

    if (result != null) {
      CustomSnackBar.error(
        context,
        result.message ?? "Invalid mobile number or password",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        child:  Stack(
          children: [
            // Decorative background elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.deliveryColor.withValues(alpha: 0.03),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSize.width * 0.06),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1200),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppSize.height * 0.05),
                    Column(
                      children: [
                        Image.asset(
                          "assets/images/apom_Go.png",
                          height:260,
                          width: 230,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    Text(
                      "Welcome Back",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppSize.width * 0.075,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),

                    Text(
                      "Login to your account to continue",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppSize.width * 0.04,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: AppSize.height * 0.02),

                    Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.12),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              label: "Mobile Number",
                              hintText: "Enter mobile number",
                              prefix: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 14),
                                  const Icon(
                                    Icons.phone_rounded,
                                    color: AppColors.primaryGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Container(width: 1, height: 20, color: Colors.grey.withOpacity(0.3)),
                                  const SizedBox(width: 10),
                                  Text(
                                    "+91",
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(width: 1, height: 20, color: Colors.grey.withOpacity(0.3)),
                                ],
                              ),
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter mobile number';
                                }
                                final trimmed = value.trim();
                                if (trimmed.length != 10) return 'Enter valid 10-digit number';
                                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) {
                                  return 'Mobile number should start with 6–9';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              label: "Password",
                              hintText: "Enter password",
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter password';
                                if (value.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),

                            // ── Forgot Password ───────────────────────────────────────
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordScreen(),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                ),
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // ── Login Button ──────────────────────────────────────────
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                    : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: AppSize.height * 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}

import 'package:delivery/Screens/Forgot_pass_screen.dart';
import 'package:delivery/Screens/bottom_navigation_screen.dart';
import 'package:delivery/repository/login_repository.dart';
import 'package:delivery/widgets/custom_snackbar.dart';
import 'package:delivery/widgets/custom_text_field.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    final result = await ref.read(loginControllerProvider.notifier).login(
      mobile: mobile,
      password: password,
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
      CustomSnackBar.success(context, "Welcome!");
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
                    SizedBox(height: AppSize.height * 0.08),

                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              "assets/images/logo.png",
                              height: AppSize.height * 0.15,
                              width: AppSize.width * 0.4,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

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
                    const SizedBox(height: 8),
                    Text(
                      "Login to your account to continue",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppSize.width * 0.04,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: AppSize.height * 0.06),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            label: "Mobile Number",
                            hintText: "Enter mobile number",
                            prefix: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.phone_rounded,
                                    color: AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "+91",
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            controller: _phoneController,
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter mobile number';
                              }
                              final trimmed = value.trim();
                              if (trimmed.length != 10) {
                                return 'Enter valid 10-digit number';
                              }
                              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) {
                                return 'Mobile number should start with 6-9';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

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
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: AppSize.height * 0.01),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.primaryGreen
                                    .withValues(alpha: 0.6),
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSize.height * 0.018,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child:
                                  isLoading
                                      ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                      : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ],
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
}

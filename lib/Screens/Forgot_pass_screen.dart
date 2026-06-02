import 'package:url_launcher/url_launcher.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:delivery/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  void _sendOTP() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // TODO: Call backend to send OTP to this number
    }
  }

  Future<void> _contactAdmin() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '9876543210');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      CustomSnackBar.error(context, "Could not launch dialer");
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_sharp, color: AppColors.primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.width * 0.06,
            vertical: AppSize.height * 0.04,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    "assets/images/logo.png",
                    height: 250,
                    width: 250,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),

                // Container wrapping title, description and button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        "Contact your admin to reset your password. They will help you regain access to your account.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Contact Admin Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _contactAdmin,
                          icon: Icon(
                            Icons.support_agent_rounded,
                            color: AppColors.primaryGreen,
                          ),
                          label: const Text(
                            "Contact Admin",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: AppColors.primaryGreen,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
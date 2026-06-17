import 'package:delivery/Screens/Login_screen.dart';
import 'package:delivery/Screens/history_screen.dart';
import 'package:delivery/Screens/personal_details_screen.dart';
import 'package:delivery/widgets/custom_app_bar.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:flutter/material.dart';
import 'package:delivery/Screens/help_support_screen.dart';
import 'package:delivery/models/profile_model.dart';
import 'package:delivery/repository/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: profileState.when(
        loading: () => _buildLoading(context),
        error: (error, _) => _buildError(context, error, ref),
        data: (profile) => _buildContent(context, ref, profile),
      ),
    );
  }

  // ─── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 60),
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
          child: const Column(
            children: [
              SizedBox(height: 20),
              CustomAppBar(
                backgroundColor: Colors.transparent,
                title: 'My Profile',
                subtitle: 'ACCOUNT SETTINGS',
              ),
            ],
          ),
        ),
        const Positioned(
          bottom: 18,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ],
    );
  }

  // ─── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Unable to load profile',
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
                  ref.read(profileControllerProvider.notifier).fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _openWebView(BuildContext context, String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(url: url, title: title),
      ),
    );
  }

  // ─── Content ───────────────────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ProfileModel profile,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref.read(profileControllerProvider.notifier).fetch(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeroHeader(context, profile.data),
            const SizedBox(height: 12),
            _buildNameBlock(profile.data),
            const SizedBox(height: 5),
            _buildMenuSection(
              title: "ACCOUNT",
              items: [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  title: "Personal Details",

                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>PersonalDetailsScreen()));
                  }
                ),
                _MenuItem(
                  icon: Icons.history_rounded,
                  title: "Task History",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>HistoryScreen()));
                    }
                ),
              ]
            ),
            const SizedBox(height: 15),
        _buildMenuSection(
          title: "INFORMATION",
          items: [
            _MenuItem(
              icon: Icons.description_outlined,
              title: "Terms & Conditions",
              subtitle: "Rules for using our platform",
              onTap: () => _openWebView(context, "https://apom.in/terms-conditions", "Terms & Conditions"),
            ),
            _MenuItem(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              subtitle: "How we handle your data",
              onTap: () => _openWebView(context, "https://apom.in/privacy-policy", "Privacy Policy"),
            ),
            _MenuItem(
              icon: Icons.receipt_outlined,
              title: "Refund & Cancellation",
              subtitle: "Policy for refunds and cancellations",
              onTap: () => _openWebView(context, "https://apom.in/refund-cancellation", "Refund & Cancellation"),
            ),
            _MenuItem(
              icon: Icons.support_agent_outlined,
              title: "Help & Support",
              subtitle: "Get help with your queries",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportDeliveryScreen(),
                  ),
                );
              },
            ),
            _MenuItem(
              icon: Icons.info_outline_rounded,
              title: "About Us",
              subtitle: "Learn more about Apom",
              onTap: () => _openWebView(context, "https://apom.in/about", "About Us"),
            ),
          ],
        ),
            _buildProfileOption(
              Icons.logout_rounded,
              'Logout',
              subtitle: 'Sign out of your account',
              iconColor: Colors.red,
              isDestructive: true,
              onTap: () => _showLogoutDialog(context, ref),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Logout dialog ─────────────────────────────────────────────────────────

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',style: TextStyle(color: Colors.black),),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(profileControllerProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child:
                const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── Hero header ───────────────────────────────────────────────────────────

  Widget _buildHeroHeader(BuildContext context, Data data) {
    final imageUrl = _profileImageUrl(data.profilePhotoUrl);
    final initials = _initialsForName(data.fullName);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.deliveryColor,
                AppColors.deliveryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: const Column(
            children: [
              SizedBox(height: 20),
              CustomAppBar(
                backgroundColor: AppColors.deliveryColor,
                title: 'My Profile',
                subtitle: 'ACCOUNT SETTINGS',
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage:
                imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: AppColors.textPrimary,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  /// Name + subtitle shown directly below the avatar.
  Widget _buildNameBlock(Data data) {
    final subtitle = _profileSubtitle(data);
    return Column(
      children: [
        Text(
          data.fullName.isNotEmpty ? data.fullName : '—',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Section / option widgets ──────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.black,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String title, {
    String? subtitle,
    Color? iconColor,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.deliveryColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.deliveryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDestructive
                          ? Colors.red
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only( bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.deliveryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: AppColors.deliveryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: item.subtitle != null
                          ? Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      )
                          : null,
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.deliveryColor,
                      ),
                      onTap: item.onTap,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Utilities ─────────────────────────────────────────────────────────────

  String _profileImageUrl(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  String _initialsForName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _profileSubtitle(Data data) {
    final vehicle = data.vehicleType.trim();
    if (vehicle.isNotEmpty) return vehicle.toUpperCase();
    final email = data.user.email?.toString().trim() ?? '';
    if (email.isNotEmpty) return email;
    final mobile = data.user.mobileNumber.trim();
    if (mobile.isNotEmpty) return mobile;
    return '';
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}

// WebView Screen
class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _progress = 0.0;
            });
          },
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load page: ${error.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.farmerColor),
            ),
          if (_isLoading && _progress == 0.0)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

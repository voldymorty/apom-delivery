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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
            const SizedBox(height: 28),
            _buildSectionHeader('ACCOUNT'),
            _buildProfileOption(
              Icons.person_outline_rounded,
              'Personal Details',
              subtitle: 'View your information',
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonalDetailsScreen(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              Icons.history_rounded,
              'Task History',
              subtitle: 'View past deliveries',
              iconColor: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('SUPPORT'),
            _buildProfileOption(
              Icons.help_outline_rounded,
              'Help & Support',
              subtitle: 'FAQs and contact us',
              iconColor: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportDeliveryScreen(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              Icons.logout_rounded,
              'Logout',
              subtitle: 'Exit your session',
              iconColor: Colors.red,
              isDestructive: true,
              onTap: () => _showLogoutDialog(context, ref),
            ),
            const SizedBox(height: 50),
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
            child: const Text('Cancel'),
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
            radius: 60,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary.withOpacity(0.6),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
            ],
          ),
        ),
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
import 'package:delivery/global/colortheme.dart';
import 'package:delivery/models/profile_model.dart';
import 'package:delivery/repository/profile_repository.dart';
import 'package:delivery/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonalDetailsScreen extends ConsumerWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: profileState.when(
        loading: () => _buildLoading(),
        error: (error, _) => _buildError(context, error, ref),
        data: (profile) => _buildContent(context, profile.data),
      ),
    );
  }

  // ─── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
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
              'Unable to load details',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
                fontSize: 13,
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

  Widget _buildContent(BuildContext context, Data data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildSectionLabel('BASIC INFORMATION'),
          const SizedBox(height: 8),
          _buildCard([
            _buildDetailRow(
              icon: Icons.person_rounded,
              label: 'Full Name',
              value: data.fullName.isNotEmpty ? data.fullName : '—',
              iconColor: Colors.blue,
            ),
            _buildDivider(),
            _buildDetailRow(
              icon: Icons.phone_rounded,
              label: 'Mobile Number',
              value: data.user.mobileNumber.isNotEmpty
                  ? data.user.mobileNumber
                  : '—',
              iconColor: Colors.green,
            ),
            _buildDivider(),
            _buildDetailRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: _readEmail(data.user.email),
              iconColor: Colors.orange,
            ),
            _buildDivider(),
            _buildDetailRow(
              icon: data.isAvailable
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              label: 'Availability',
              value: data.isAvailable ? 'Available' : 'Unavailable',
              valueColor:
                  data.isAvailable ? Colors.green : Colors.red,
              iconColor:
                  data.isAvailable ? Colors.green : Colors.red,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionLabel('VEHICLE INFORMATION'),
          const SizedBox(height: 8),
          _buildCard([
            _buildDetailRow(
              icon: Icons.directions_car_rounded,
              label: 'Vehicle Type',
              value: data.vehicleType.isNotEmpty ? data.vehicleType : '—',
              iconColor: Colors.indigo,
            ),
            _buildDivider(),
            _buildDetailRow(
              icon: Icons.pin_rounded,
              label: 'Vehicle Number',
              value: data.vehicleNumber.isNotEmpty ? data.vehicleNumber : '—',
              iconColor: Colors.deepPurple,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionLabel('LICENSE DETAILS'),
          const SizedBox(height: 8),
          _buildCard([
            _buildDetailRow(
              icon: Icons.badge_rounded,
              label: 'License Number',
              value: data.licenseNumber.isNotEmpty ? data.licenseNumber : '—',
              iconColor: Colors.teal,
            ),
            _buildDivider(),
            _buildDetailRow(
              icon: Icons.event_rounded,
              label: 'License Expiry',
              value: _formatDate(data.licenseExpiryDate),
              valueColor: _isExpiringSoon(data.licenseExpiryDate)
                  ? Colors.red
                  : null,
              iconColor: _isExpiringSoon(data.licenseExpiryDate)
                  ? Colors.red
                  : Colors.teal,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionLabel('DELIVERY STATISTICS'),
          const SizedBox(height: 8),
          _buildStatsCard(data),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 5),
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
      child: Column(
        children: [
          const SizedBox(height: 20),
          CustomAppBar(
            backgroundColor: Colors.transparent,
            title: 'Personal Details',
            subtitle: 'YOUR INFORMATION',
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary.withOpacity(0.6),
          letterSpacing: 1.6,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.deliveryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? AppColors.deliveryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withOpacity(0.6),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Data data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCell(
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
                value: data.rating.isNotEmpty ? data.rating : '—',
                label: 'Rating',
              ),
            ),
            _buildStatDivider(),
            Expanded(
              child: _buildStatCell(
                icon: Icons.task_alt_rounded,
                iconColor: Colors.blue,
                value: '${data.totalDeliveries}',
                label: 'Total Tasks',
              ),
            ),
            _buildStatDivider(),
            Expanded(
              child: _buildStatCell(
                icon: Icons.check_circle_rounded,
                iconColor: Colors.green,
                value: '${data.completedDeliveries}',
                label: 'Completed',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.withOpacity(0.15),
    );
  }

  // ─── Utilities ─────────────────────────────────────────────────────────────

  String _readEmail(dynamic email) {
    if (email == null) return '—';
    final str = email.toString().trim();
    return str.isNotEmpty ? str : '—';
  }

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return '—';
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} '
        '${date.year}';
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }

  bool _isExpiringSoon(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return false;
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    return diff < 30;
  }
}

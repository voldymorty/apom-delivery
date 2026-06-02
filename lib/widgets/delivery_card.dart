import 'package:flutter/material.dart';
import 'package:delivery/global/colortheme.dart';

class DeliveryCard extends StatelessWidget {
  final String id;
  final String status;
  final Color statusColor;
  final String time;
  final String title;
  final String subtitle;
  final String? loadDetails; // Optional for delivery if using statusLeading
  final String? priority;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final Widget? statusLeading;

  const DeliveryCard({
    super.key,
    required this.id,
    required this.status,
    required this.statusColor,
    required this.time,
    required this.title,
    required this.subtitle,
    this.loadDetails,
    this.priority,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.statusLeading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.deliveryColor, width: 1),
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.textSecondary.withOpacity(0.05),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: ID, Status, Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#$id',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary.withOpacity(0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // const SizedBox(width: 8),
                  // Expanded(child: _buildTimeRow(time)),
                ],
              ),
              const SizedBox(height: 24),

              // Content Row: Type Icon, Title/Subtitle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeIcon(),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AppColors.textSecondary.withOpacity(0.4),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary.withOpacity(
                                    0.7,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Load Details or Status Leading
              if (statusLeading != null) ...[
                statusLeading!,
                const SizedBox(height: 24),
              ] else if (loadDetails != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DELIVERY PROTOCOL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textSecondary.withOpacity(0.4),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 14,
                                  color: AppColors.deliveryColor.withOpacity(
                                    0.6,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    loadDetails!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildSideDetail(),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // Action Buttons
              ElevatedButton(
                onPressed: onPrimaryAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      status == 'Verified'
                          ? AppColors.textPrimary
                          : AppColors.deliveryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: (status == 'Verified'
                          ? AppColors.textPrimary
                          : AppColors.deliveryColor)
                      .withOpacity(0.3),
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      primaryActionLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      status == 'Verified'
                          ? Icons.arrow_forward_ios_outlined
                          : Icons.bolt_rounded,
                      size: 15,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    const icon = Icons.local_shipping_rounded;
    const label = 'DELIVERY';
    final color = status == 'Verified' ? AppColors.success : Colors.blue;

    return Container(
      width: 60,
      height: 70,
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideDetail() {
    if (priority != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'PRIORITY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary.withOpacity(0.4),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.priority_high_rounded,
                  size: 12,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  priority!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  Widget _buildTimeRow(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return const SizedBox();
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 14,
          color: AppColors.textSecondary.withOpacity(0.4),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}

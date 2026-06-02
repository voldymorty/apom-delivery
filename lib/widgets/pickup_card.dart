import 'package:flutter/material.dart';
import 'package:delivery/global/colortheme.dart';

class PickupCard extends StatelessWidget {
  final String id;
  final String status;
  final Color statusColor;
  final String time;
  final String title;
  final String subtitle;
  final String loadDetails;
  final String weight;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;

  const PickupCard({
    super.key,
    required this.id,
    required this.status,
    required this.statusColor,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.loadDetails,
    required this.weight,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
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
                mainAxisAlignment:MainAxisAlignment.spaceBetween,
                children: [
                  Container(
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
                  const SizedBox(width: 8),
                  Container(
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

              // Load Details
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
                            'LOAD PROTOCOL',
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
                                color: AppColors.deliveryColor.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  loadDetails,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onPrimaryAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deliveryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppColors.deliveryColor.withOpacity(0.3),
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
                          const Icon(Icons.bolt_rounded, size: 15),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    const icon = Icons.inventory_2_rounded;
    const label = 'PICKUP';
    const color = Colors.orange;

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
            child: const Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          const Text(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'WEIGHT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondary.withOpacity(0.4),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.scale_rounded,
              size: 14,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(width: 4),
            Text(
              weight,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
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

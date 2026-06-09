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
  final String? cropName;
  final String? cropGrade;
  final String? pricePerKg;
  final String? harvestDate;
  final String? contactNumber;
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
    this.cropName,
    this.cropGrade,
    this.pricePerKg,
    this.harvestDate,
    this.contactNumber,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.deliveryColor.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.deliveryColor,
                    AppColors.deliveryColor.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),

            // Card body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row — ID + badges
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            id,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deliveryColor.withValues(
                                alpha: 0.55,
                              ),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _TypeBadge(label: 'PICKUP', isPickup: true),
                            const SizedBox(height: 5),
                            _StatusBadge(
                              label: status,
                              color: statusColor,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 11),

                    // Crop chip row
                    if (cropName != null && cropName!.isNotEmpty)
                      _CropChip(
                        cropName: cropName!,
                        cropGrade: cropGrade,
                        pricePerKg: pricePerKg,
                        harvestDate: harvestDate,
                        weight: weight,
                      ),

                    const SizedBox(height: 8),

                    // Farmer name + address
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A0A2E),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9A86B0),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),
                    _Divider(color: const Color(0xFFF0EAF8)),
                    const SizedBox(height: 11),

                    // Footer — schedule + phone + action
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (time.isNotEmpty)
                                _MetaRow(
                                  icon: Icons.calendar_today_rounded,
                                  label: time,
                                  color: AppColors.deliveryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              if (contactNumber != null &&
                                  contactNumber!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                _MetaRow(
                                  icon: Icons.phone_rounded,
                                  label: contactNumber!,
                                  color: AppColors.deliveryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _ActionButton(
                          label: primaryActionLabel,
                          isPickup: true,
                          onTap: onPrimaryAction,
                        ),
                      ],
                    ),
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

// ─── Crop Chip ──────────────────────────────────────────────────────────────

class _CropChip extends StatelessWidget {
  final String cropName;
  final String? cropGrade;
  final String? pricePerKg;
  final String? harvestDate;
  final String weight;

  const _CropChip({
    required this.cropName,
    this.cropGrade,
    this.pricePerKg,
    this.harvestDate,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (pricePerKg != null && pricePerKg!.isNotEmpty)
        '₹$pricePerKg/kg',
      if (harvestDate != null && harvestDate!.isNotEmpty)
        'Harvest $harvestDate',
    ].join(' · ');

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.deliveryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.eco_rounded,
            size: 18,
            color: AppColors.deliveryColor.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  cropName,
                  if (cropGrade != null && cropGrade!.isNotEmpty)
                    'Grade ${cropGrade!}',
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A1A5C),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB09EC4),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _WeightPill(label: weight, isPickup: true),
      ],
    );
  }
}

// ─── Shared sub-widgets ─────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String label;
  final bool isPickup;
  const _TypeBadge({required this.label, required this.isPickup});

  @override
  Widget build(BuildContext context) {
    final bg = isPickup
        ? AppColors.deliveryColor.withValues(alpha: 0.1)
        : const Color(0xFFE8EEFF);
    final fg = isPickup ? AppColors.deliveryColor : const Color(0xFF1A4CAC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _WeightPill extends StatelessWidget {
  final String label;
  final bool isPickup;
  const _WeightPill({required this.label, required this.isPickup});

  @override
  Widget build(BuildContext context) {
    final bg = isPickup
        ? AppColors.deliveryColor.withValues(alpha: 0.1)
        : const Color(0xFFE8EEFF);
    final fg = isPickup ? AppColors.deliveryColor : const Color(0xFF1A4CAC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9A86B0),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: color);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPickup;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.isPickup,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPickup ? AppColors.deliveryColor : const Color(0xFF1A4CAC);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
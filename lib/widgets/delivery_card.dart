import 'package:flutter/material.dart';
import 'package:delivery/global/colortheme.dart';

class DeliveryCard extends StatelessWidget {
  final String id;
  final String status;
  final Color statusColor;
  final String time;
  final String title;
  final String subtitle;
  final String? loadDetails;
  final String? priority;
  final String? shopName;
  final String? productSummary;
  final String? orderNumber;
  final String? orderStatus;
  final String? contactNumber;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;

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
    this.shopName,
    this.productSummary,
    this.orderNumber,
    this.orderStatus,
    this.contactNumber,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
  });

  static const Color _blueAccent = Color(0xFF1A4CAC);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _blueAccent.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar — blue for delivery
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _blueAccent,
                    _blueAccent.withValues(alpha: 0.45),
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
                              color: _blueAccent.withValues(alpha: 0.5),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _DeliveryTypeBadge(),
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

                    // Vendor + order chip
                    if (shopName != null && shopName!.isNotEmpty)
                      _VendorChip(
                        shopName: shopName!,
                        productSummary: productSummary,
                        orderNumber: orderNumber,
                        orderStatus: orderStatus,
                        weight: loadDetails,
                      ),

                    const SizedBox(height: 8),

                    // Contact name + delivery address
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
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF86909A),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),
                    _Divider(),
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
                                  iconColor: _blueAccent.withValues(
                                    alpha: 0.45,
                                  ),
                                  textColor: const Color(0xFF8090B4),
                                ),
                              if (contactNumber != null &&
                                  contactNumber!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                _MetaRow(
                                  icon: Icons.phone_rounded,
                                  label: contactNumber!,
                                  iconColor: _blueAccent.withValues(
                                    alpha: 0.45,
                                  ),
                                  textColor: const Color(0xFF8090B4),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _ActionButton(
                          label: primaryActionLabel,
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

// ─── Vendor Chip ─────────────────────────────────────────────────────────────

class _VendorChip extends StatelessWidget {
  final String shopName;
  final String? productSummary;
  final String? orderNumber;
  final String? orderStatus;
  final String? weight;

  const _VendorChip({
    required this.shopName,
    this.productSummary,
    this.orderNumber,
    this.orderStatus,
    this.weight,
  });

  static const Color _blueAccent = Color(0xFF1A4CAC);

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (orderNumber != null && orderNumber!.isNotEmpty) orderNumber!,
      if (orderStatus != null && orderStatus!.isNotEmpty)
        orderStatus!.replaceAll('_', ' ').toUpperCase(),
    ].join(' · ');

    final chipLabel = productSummary != null && productSummary!.isNotEmpty
        ? '$shopName · $productSummary'
        : shopName;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _blueAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.store_rounded,
            size: 18,
            color: _blueAccent.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chipLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2A5C),
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
                    color: Color(0xFF8090B4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (weight != null && weight!.isNotEmpty) ...[
          const SizedBox(width: 8),
          _WeightPill(label: weight!),
        ],
      ],
    );
  }
}

// ─── Shared sub-widgets ─────────────────────────────────────────────────────

class _DeliveryTypeBadge extends StatelessWidget {
  const _DeliveryTypeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'DELIVERY',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A4CAC),
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
  const _WeightPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A4CAC),
        ),
      ),
    );
  }
}

// ignore: non_constant_identifier_names
Widget _WeightPillFixed(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFE8EEFF),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A4CAC),
      ),
    ),
  );
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
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
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0xFFEAF0F8));
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1A4CAC),
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
import 'package:flutter/material.dart';
import 'package:delivery/global/colortheme.dart';

class CustomAppBar extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool reverseTitleOrder;
  final Color? backgroundColor;
  final double? titleFontSize;

  const CustomAppBar({
    super.key,
    this.leading,
    required this.title,
    this.subtitle = '',
    this.actions,
    this.centerTitle = false,
    this.reverseTitleOrder = false,
    this.backgroundColor,
    this.titleFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = backgroundColor != null &&
        ThemeData.estimateBrightnessForColor(backgroundColor!) == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: backgroundColor != null
          ? const EdgeInsets.only(bottom: 10)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: backgroundColor != null ? AppColors.premiumGradient(backgroundColor!) : null,
        borderRadius: backgroundColor != null
            ? const BorderRadius.vertical(bottom: Radius.circular(32))
            : null,
        boxShadow: backgroundColor != null
            ? [
              BoxShadow(
                color: backgroundColor!.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ]
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment:
              centerTitle ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (leading != null) ...[
              leading!,
              if (!centerTitle) const SizedBox(width: 12),
            ],
            if (centerTitle) const Spacer(),
            Column(
              crossAxisAlignment:
                  centerTitle
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reverseTitleOrder) ...[
                  if (subtitle.isNotEmpty) _buildSubtitle(isDark),
                  _buildTitle(isDark),
                ] else ...[
                  _buildTitle(isDark),
                  if (subtitle.isNotEmpty) _buildSubtitle(isDark),
                ],
              ],
            ),
            if (centerTitle) const Spacer(),
            if (!centerTitle) const Spacer(),
            if (actions != null) ...actions!,
            if (centerTitle && leading != null)
              const SizedBox(width: 48), // Visual balance for leading icon
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: titleFontSize ?? (centerTitle ? 14 : 22),
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : (centerTitle ? AppColors.deliveryColor : AppColors.textPrimary),
      ),
    );
  }

  Widget _buildSubtitle(bool isDark) {
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: centerTitle ? 12 : 10,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  static Widget buildActionButton(IconData icon, {bool showDot = false, VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: AppColors.surface, size: 22),
            if (showDot)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:delivery/global/colortheme.dart';
import 'package:flutter/material.dart';

/// Custom SnackBar for consistent look across the app
///
/// Usage examples:
/// CustomSnackBar.show(context, "Success message", isSuccess: true);
/// CustomSnackBar.show(context, "Error occurred", isError: true);
/// CustomSnackBar.show(context, "Info text", duration: const Duration(seconds: 4));
class CustomSnackBar {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context,
    String message, {
    bool isSuccess = false,
    bool isError = false,
    bool isInfo = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    Color backgroundColor = AppColors.textSecondary; // default neutral
    IconData? icon;

    if (isSuccess) {
      backgroundColor = AppColors.success;
      icon = Icons.check_circle_outline_rounded;
    } else if (isError) {
      backgroundColor = AppColors.error;
      icon = Icons.error_outline_rounded;
    } else if (isInfo) {
      backgroundColor = AppColors.primaryGreen.withOpacity(0.9);
      icon = Icons.info_outline_rounded;
    }

    _dismiss();

    _currentOverlay = OverlayEntry(
      builder:
          (context) => _TopSnackBarWidget(
            message: message,
            backgroundColor: backgroundColor,
            icon: icon,
            duration: duration,
            onDismiss: _dismiss,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
    );

    final overlay = Overlay.of(context, rootOverlay: true);

    overlay.insert(_currentOverlay!);
  }

  static void _dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  // Quick success helper
  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      isSuccess: true,
      duration: duration ?? const Duration(seconds: 3),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  // Quick error helper
  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      isError: true,
      duration: duration ?? const Duration(seconds: 4),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  // Quick info helper
  static void info(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      isInfo: true,
      duration: duration ?? const Duration(seconds: 3),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _TopSnackBarWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TopSnackBarWidget({
    required this.message,
    required this.backgroundColor,
    this.icon,
    required this.duration,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_TopSnackBarWidget> createState() => _TopSnackBarWidgetState();
}

class _TopSnackBarWidgetState extends State<_TopSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAction =
        widget.actionLabel != null && widget.onAction != null;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (hasAction) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      widget.onDismiss();
                      widget.onAction?.call();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,color:Colors.white,
                      ),
                    ),
                    child: Text(widget.actionLabel!,),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

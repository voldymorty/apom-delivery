import 'package:delivery/global/colortheme.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final int? maxLength;
  final String? prefixText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final Widget? prefix;
  final Widget? suffixWidget;

  // NEW: customizable colors
  final Color? focusedBorderColor; // color when field is focused
  final Color? prefixIconColor; // color for prefix icon
  final Color? suffixIconColor; // color for suffix icon (optional)
  final bool readOnly; // NEW: read-only mode
  final VoidCallback? onTap; // NEW: tap handler

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLength,
    this.prefixText,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefix,
    this.suffixWidget,
    this.focusedBorderColor,
    this.prefixIconColor,
    this.suffixIconColor,
    this.readOnly = false, // ← new
    this.onTap, // ← new
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFocusedColor = focusedBorderColor ?? AppColors.primaryGreen;
    final effectivePrefixColor = prefixIconColor ?? AppColors.primaryGreen;
    final effectiveSuffixColor = suffixIconColor ?? AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly, // ← pass to TextFormField
          onTap: onTap, // ← pass to TextFormField
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 13),
            prefixIcon:
                prefix ??
                (prefixIcon != null
                    ? Icon(prefixIcon, color: effectivePrefixColor)
                    : null),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
            suffixIcon:
                suffixIcon != null
                    ? IconTheme(
                      data: IconThemeData(color: effectiveSuffixColor),
                      child: suffixIcon!,
                    )
                    : null,
            suffix: suffixWidget,
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: effectiveFocusedColor, width: 2),
            ),
            filled: true,
            fillColor:
                enabled ? Colors.white : AppColors.divider.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }
}

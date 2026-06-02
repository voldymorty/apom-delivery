import 'package:flutter/material.dart';

/// Color Theme for Wholesale Fruits & Vegetables Management App
class AppColors {
  // Role-based colors
  static const Color farmerColor = Color(0xFF3E2723); // Deep Brown
  static const Color vendorColor = Color(0xFF0061FF); // Vibrant Blue
  static const Color deliveryColor = Color(0xFF7A1CAC); // Emerald Green

  // Primary theme colors
  static const Color primaryGreen = Color(0xFF7A1CAC);
  static const Color lightGreen = Color(0xFFF1F8E9);

  // UI colors
  static const Color background = Color(0xFFFDFDFD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF131313);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color divider = Color(0xFFF1F3F5);

  // Status colors
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);

  // Gradients
  static LinearGradient premiumGradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color, color.withValues(alpha: 0.8)],
  );

  static LinearGradient meshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color(0xFF00C853).withValues(alpha: 0.05),
      const Color(0xFF00C853).withValues(alpha: 0.02),
      Colors.white,
    ],
  );

  // Helper methods
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'farmer':
        return farmerColor;
      case 'vendor':
        return vendorColor;
      case 'delivery':
        return deliveryColor;
      default:
        return primaryGreen;
    }
  }
}

class AppSize {
  static late double width;
  static late double height;

  static void init(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
  }
}

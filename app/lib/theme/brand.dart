import 'package:flutter/material.dart';

class Brand {
  // Dusty Rose & Charcoal Color Scheme
  
  // Primary rose gradient: #d0a3af -> #ba8593
  static const Color primaryStart = Color(0xFFD0A3AF);
  static const Color primaryEnd = Color(0xFFBA8593);
  
  // Charcoal accent for contrast
  static const Color charcoal = Color(0xFF3D3840);
  
  // Background colors
  static const Color backgroundLight = Color(0xFFF8F5F6);
  static const Color backgroundMedium = Color(0xFFF0EAEC);
  
  // Text colors
  static const Color textPrimary = Color(0xFF3D3840);
  static const Color textSecondary = Color(0xFF6D6168);
  static const Color textTertiary = Color(0xFF8A7B82);
  
  // Card and surface colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundSecondary = Color(0xFFFDFBFC);
  
  // Border colors
  static const Color borderLight = Color(0xFFF0E8EB);
  static const Color borderMedium = Color(0xFFE8E0E3);

  // Accent mint for pay-it-forward elements
  static const Color mintColor = Color(0xFF2ECC71);
  
  // Legacy accent (deprecated, use primaryStart instead)
  static const Color accent = Color(0xFFD0A3AF);

  // Secondary gradient: lighter rose tones
  static const Color secondaryStart = Color(0xFFF5EDEF);
  static const Color secondaryEnd = Color(0xFFE8E0E3);

  // Deep gradient: charcoal to rose
  static const Color deepStart = Color(0xFF3D3840);
  static const Color deepEnd = Color(0xFF6D6168);

  static const double radius = 12;

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryStart, primaryEnd],
      );

  static LinearGradient get secondaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [secondaryStart, secondaryEnd],
      );

  static LinearGradient get deepGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [deepStart, deepEnd],
      );

  static BoxDecoration gradientDecoration({bool secondary = false}) => BoxDecoration(
        gradient: secondary ? secondaryGradient : primaryGradient,
      );

  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 4)),
        ],
      );
}

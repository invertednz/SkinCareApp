import 'package:flutter/material.dart';

class Brand {
  // Colors derived from styles.css
  static const Color accent = Color(0xFFFF7EB3);

  // Primary gradient: #a8edea -> #fed6e3
  static const Color primaryStart = Color(0xFFA8EDEA);
  static const Color primaryEnd = Color(0xFFFED6E3);

  // Secondary gradient: #e0c3fc -> #8ec5fc
  static const Color secondaryStart = Color(0xFFE0C3FC);
  static const Color secondaryEnd = Color(0xFF8EC5FC);

  // Deep gradient: #6A11CB -> #2575FC
  static const Color deepStart = Color(0xFF6A11CB);
  static const Color deepEnd = Color(0xFF2575FC);

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

import 'package:flutter/material.dart';

/// Responsive breakpoints utility for consistent UI across different screen sizes
class Breakpoints {
  // Breakpoint constants
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;

  /// Get responsive text style based on screen size
  static TextStyle getResponsiveTextStyle(
    BuildContext context,
    TextStyle baseStyle, {
    double? mobileFactor,
    double? tabletFactor,
    double? desktopFactor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = 1.0;

    if (screenWidth < mobile) {
      scaleFactor = mobileFactor ?? 0.9;
    } else if (screenWidth < tablet) {
      scaleFactor = mobileFactor ?? 0.95;
    } else if (screenWidth < desktop) {
      scaleFactor = tabletFactor ?? 1.0;
    } else {
      scaleFactor = desktopFactor ?? 1.1;
    }

    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * scaleFactor,
    );
  }

  /// Get responsive spacing based on screen size
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobile) {
      return baseSpacing * 0.8;
    } else if (screenWidth < tablet) {
      return baseSpacing * 0.9;
    } else if (screenWidth < desktop) {
      return baseSpacing;
    } else {
      return baseSpacing * 1.2;
    }
  }

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tablet;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context, EdgeInsets basePadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    double factor = 1.0;

    if (screenWidth < mobile) {
      factor = 0.8;
    } else if (screenWidth < tablet) {
      factor = 0.9;
    } else if (screenWidth >= desktop) {
      factor = 1.2;
    }

    return EdgeInsets.only(
      left: basePadding.left * factor,
      top: basePadding.top * factor,
      right: basePadding.right * factor,
      bottom: basePadding.bottom * factor,
    );
  }

  /// Get responsive width based on screen size
  static double getResponsiveWidth(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < Breakpoints.tablet) {
      return mobile ?? screenWidth * 0.9;
    } else if (screenWidth < Breakpoints.desktop) {
      return tablet ?? screenWidth * 0.8;
    } else {
      return desktop ?? screenWidth * 0.6;
    }
  }
}

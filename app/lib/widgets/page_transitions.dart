import 'package:flutter/material.dart';

/// Page transition builder for cross-fade effect
/// Duration: 300ms, Curve: linear (as per guidelines)
class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Check for reduced motion preference
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    if (reducedMotion) {
      return child;
    }

    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

/// Custom page route with cross-fade transition
class FadePageRoute<T> extends MaterialPageRoute<T> {
  FadePageRoute({
    required super.builder,
    super.settings,
    super.maintainState = true,
    super.fullscreenDialog = false,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Check for reduced motion preference
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    if (reducedMotion) {
      return child;
    }

    // Cross-fade: old screen fades out while new screen fades in
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.linear, // Linear as per guidelines
      ),
      child: child,
    );
  }
}

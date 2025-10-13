import 'package:flutter/material.dart';

/// Staggered fade + slide-up animation widget
/// Animates children sequentially with 100ms delay between each
/// Duration: 600ms per element, Curve: ease-out
class StaggeredAnimation extends StatefulWidget {
  const StaggeredAnimation({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.animationDuration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
    this.slideDistance = 0.3, // 30% of widget height
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Curve curve;
  final double slideDistance; // Fraction of widget height (0.0 to 1.0)

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    // Start animation after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
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
    // Check for reduced motion preference
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    if (reducedMotion) {
      return Column(
        children: widget.children,
      );
    }

    return Column(
      children: [
        for (int i = 0; i < widget.children.length; i++)
          _StaggeredItem(
            index: i,
            staggerDelay: widget.staggerDelay,
            animationDuration: widget.animationDuration,
            curve: widget.curve,
            slideDistance: widget.slideDistance,
            child: widget.children[i],
          ),
      ],
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({
    required this.index,
    required this.staggerDelay,
    required this.animationDuration,
    required this.curve,
    required this.slideDistance,
    required this.child,
  });

  final int index;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Curve curve;
  final double slideDistance;
  final Widget child;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideDistance),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    // Start animation with stagger delay
    Future.delayed(widget.staggerDelay * widget.index, () {
      if (mounted) {
        _controller.forward();
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
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Individual animated card with staggered entry
/// Use this for individual cards when you want manual control over the delay
class AnimatedCard extends StatefulWidget {
  const AnimatedCard({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
    this.slideDistance = 0.3,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final double slideDistance;

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideDistance),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    // Start animation with delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
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
    // Check for reduced motion preference
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    if (reducedMotion) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

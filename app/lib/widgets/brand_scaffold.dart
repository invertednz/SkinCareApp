import 'package:flutter/material.dart';
import '../theme/brand.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({super.key, required this.title, this.trailing, this.height = 140});
  final String title;
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: Brand.gradientDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class OverlapCard extends StatelessWidget {
  const OverlapCard({super.key, required this.child, this.overlap = 32, this.horizontalMargin = 16, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final double overlap;
  final double horizontalMargin;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -overlap),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
        padding: padding,
        decoration: Brand.cardDecoration(context),
        child: child,
      ),
    );
  }
}

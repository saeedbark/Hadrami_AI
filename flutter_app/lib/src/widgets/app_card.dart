import 'package:flutter/material.dart';
import 'package:hadrami_nlp/src/configs/app_radius.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.elevation,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        elevation: elevation ?? 1,
        borderRadius: AppRadius.lg,
        color: color ?? colorScheme.surface,
        shadowColor: colorScheme.shadow.withValues(alpha: .08),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lg,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

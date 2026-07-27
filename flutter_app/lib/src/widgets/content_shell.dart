import 'package:flutter/material.dart';
import 'package:hadrami_nlp/src/core/theme/theme.dart';

class ContentShell extends StatelessWidget {
  const ContentShell({
    super.key,
    required this.child,
    this.maxWidth = 880,
    this.horizontalPadding = 0,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final double horizontalPadding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return horizontalPadding == 0
          ? child
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: child,
            );
    }
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        ),
      ),
    );
  }
}

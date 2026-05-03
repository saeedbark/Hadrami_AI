import 'package:flutter/material.dart';

class AnimatedAppear extends StatefulWidget {
  const AnimatedAppear({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    this.delay = Duration.zero,
    this.slideOffset = const Offset(0, 0.06),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset slideOffset;
  final Curve curve;

  @override
  State<AnimatedAppear> createState() => _AnimatedAppearState();
}

class _AnimatedAppearState extends State<AnimatedAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved =
        CurvedAnimation(parent: _controller, curve: widget.curve);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(
              widget.slideOffset.dx * (1 - t) * 32,
              widget.slideOffset.dy * (1 - t) * 32,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class StaggeredAppear extends StatelessWidget {
  const StaggeredAppear({
    super.key,
    required this.children,
    this.stagger = const Duration(milliseconds: 60),
    this.itemDuration = const Duration(milliseconds: 320),
    this.slideOffset = const Offset(0, 0.08),
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
  });

  final List<Widget> children;
  final Duration stagger;
  final Duration itemDuration;
  final Offset slideOffset;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++)
          AnimatedAppear(
            duration: itemDuration,
            delay: stagger * i,
            slideOffset: slideOffset,
            child: children[i],
          ),
      ],
    );
  }
}

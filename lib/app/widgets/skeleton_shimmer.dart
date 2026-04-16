import 'package:flutter/material.dart';

class SkeletonShimmerBox extends StatefulWidget {
  const SkeletonShimmerBox({
    super.key,
    this.height,
    this.width,
    this.borderRadius = BorderRadius.zero,
    this.baseColor = const Color(0xFFE9EDF2),
  });

  final double? height;
  final double? width;
  final BorderRadius borderRadius;
  final Color baseColor;

  @override
  State<SkeletonShimmerBox> createState() => _SkeletonShimmerBoxState();
}

class _SkeletonShimmerBoxState extends State<SkeletonShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Container(
      height: widget.height,
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        color: widget.baseColor,
        borderRadius: widget.borderRadius,
      ),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final slide = _controller.value * 2 - 1;
            return LinearGradient(
              begin: Alignment(-1.4 + slide, -0.25),
              end: Alignment(1.4 + slide, 0.25),
              colors: const [
                Color(0xFFE7EBF0),
                Color(0xFFF8FAFC),
                Color(0xFFE7EBF0),
              ],
              stops: const [0.15, 0.5, 0.85],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: base,
    );
  }
}

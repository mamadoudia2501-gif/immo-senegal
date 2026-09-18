import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ShimmerBlock extends StatefulWidget {
  const ShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.4 + _controller.value * 2.8, 0),
              end: Alignment(-0.4 + _controller.value * 2.8, 0),
              colors: const [
                Color(0xFFE9DFD0),
                Color(0xFFF7F1E8),
                Color(0xFFE9DFD0),
              ],
            ),
          ),
          child: SizedBox(width: widget.width, height: widget.height),
        );
      },
    );
  }
}

class ListingSkeleton extends StatelessWidget {
  const ListingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: appCardShadow,
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBlock(width: double.infinity, height: 132, radius: 14),
            SizedBox(height: 12),
            ShimmerBlock(width: 220, height: 16),
            SizedBox(height: 8),
            ShimmerBlock(width: 140, height: 12),
            SizedBox(height: 12),
            ShimmerBlock(width: 160, height: 18),
          ],
        ),
      ),
    );
  }
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBlock(width: double.infinity, height: 180, radius: 28),
          SizedBox(height: 22),
          ShimmerBlock(width: 140, height: 18),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ShimmerBlock(width: 80, height: 88, radius: 20)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBlock(width: 80, height: 88, radius: 20)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBlock(width: 80, height: 88, radius: 20)),
            ],
          ),
          SizedBox(height: 22),
          ListingSkeleton(),
        ],
      ),
    );
  }
}

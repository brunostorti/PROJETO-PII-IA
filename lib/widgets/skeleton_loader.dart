import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Widget de skeleton loader moderno para estados de carregamento
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                widget.baseColor ?? Colors.grey[200]!,
                widget.highlightColor ?? Colors.grey[100]!,
                widget.baseColor ?? Colors.grey[200]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton para card de projeto
class ProjectCardSkeleton extends StatelessWidget {
  const ProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonLoader(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(8))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLoader(height: 16, width: 150),
                      const SizedBox(height: 8),
                      const SkeletonLoader(height: 12, width: 100),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonLoader(height: 120, borderRadius: BorderRadius.all(Radius.circular(12))),
            const SizedBox(height: 12),
            Row(
              children: [
                const SkeletonLoader(width: 80, height: 24, borderRadius: BorderRadius.all(Radius.circular(12))),
                const Spacer(),
                const SkeletonLoader(width: 60, height: 24, borderRadius: BorderRadius.all(Radius.circular(12))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para lista de comparações
class ComparisonCardSkeleton extends StatelessWidget {
  const ComparisonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const SkeletonLoader(width: 56, height: 56, borderRadius: BorderRadius.all(Radius.circular(8))),
        title: const SkeletonLoader(height: 16, width: 120),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: SkeletonLoader(height: 12, width: 200),
        ),
        trailing: const SkeletonLoader(width: 40, height: 20, borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }
}


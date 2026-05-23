import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shimmer-style placeholder shown while analysis is in progress (FR 1.3).
class SkeletonMeterPlaceholder extends StatefulWidget {
  const SkeletonMeterPlaceholder({super.key, this.compact = false});

  final bool compact;

  @override
  State<SkeletonMeterPlaceholder> createState() =>
      _SkeletonMeterPlaceholderState();
}

class _SkeletonMeterPlaceholderState extends State<SkeletonMeterPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 125.0 : 170.0;
    final width = widget.compact ? 200.0 : 280.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.45 + (_controller.value * 0.55),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text(
                'Analyzing risk...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: width * 0.7,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

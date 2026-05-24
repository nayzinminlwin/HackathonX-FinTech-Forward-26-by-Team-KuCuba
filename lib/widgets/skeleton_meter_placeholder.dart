import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shimmer-style placeholder shown while analysis is in progress (FR 1.3).
class SkeletonMeterPlaceholder extends StatefulWidget {
  const SkeletonMeterPlaceholder({
    super.key,
    this.compact = false,
    this.messageText = '',
  });

  final bool compact;
  final String messageText;

  @override
  State<SkeletonMeterPlaceholder> createState() =>
      _SkeletonMeterPlaceholderState();
}

class _SkeletonMeterPlaceholderState extends State<SkeletonMeterPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _stageTimer;
  late DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _stageTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant SkeletonMeterPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageText != widget.messageText) {
      _startedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 112.0 : 170.0;
    final width = widget.compact ? 184.0 : 280.0;

    final stage = _currentStage();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final pulse = 0.65 + (_controller.value * 0.35);
            return Opacity(opacity: pulse, child: child);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Positioned(
                        left: width * _controller.value - 22,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.transparent,
                                AppColors.corporateRed.withValues(alpha: 0.14),
                                AppColors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: widget.compact ? 34 : 48,
                              height: widget.compact ? 34 : 48,
                              decoration: BoxDecoration(
                                color: AppColors.corporateRed
                                    .withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shield_outlined,
                                color: AppColors.corporateRed,
                                size: widget.compact ? 22 : 26,
                              ),
                            ),
                            SizedBox(height: widget.compact ? 8 : 12),
                            SizedBox(
                              width: widget.compact ? 152 : 220,
                              child: Text(
                                stage.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: widget.compact ? 14 : 16,
                                ),
                              ),
                            ),
                            SizedBox(height: widget.compact ? 4 : 6),
                            SizedBox(
                              width: widget.compact ? 160 : 230,
                              child: Text(
                                stage.detail,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: widget.compact ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: widget.compact ? 8 : 12),
        SizedBox(
          width: width,
          child: Row(
            children: [
              _StageDot(active: stage.index >= 0),
              const SizedBox(width: 7),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: stage.index >= 1
                        ? AppColors.corporateRed
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              _StageDot(active: stage.index >= 2),
              const SizedBox(width: 7),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: stage.index >= 3
                        ? AppColors.corporateRed
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              _StageDot(active: stage.index >= 3),
            ],
          ),
        ),
      ],
    );
  }

  _LoadingStage _currentStage() {
    final elapsed = DateTime.now().difference(_startedAt).inMilliseconds;
    final hasShortenedUrl = _hasShortenedUrl(widget.messageText);

    if (elapsed >= 2500) {
      return const _LoadingStage(
        index: 3,
        title: 'Almost done...',
        detail: 'Finalizing the risk explanation.',
      );
    }

    if (hasShortenedUrl && elapsed >= 800) {
      return const _LoadingStage(
        index: 1,
        title: 'Verifying hidden links...',
        detail: 'Following redirects with a short timeout.',
      );
    }

    if (elapsed >= (hasShortenedUrl ? 1550 : 850)) {
      return const _LoadingStage(
        index: 2,
        title: 'Analyzing message context...',
        detail: 'Checking language, urgency, and scam patterns.',
      );
    }

    return const _LoadingStage(
      index: 0,
      title: 'Checking links...',
      detail: 'Looking for known unsafe destinations.',
    );
  }

  bool _hasShortenedUrl(String text) {
    return RegExp(
      r'\b(bit\.ly|tinyurl\.com|is\.gd|t\.co|goo\.gl|ow\.ly|buff\.ly|cutt\.ly|rebrand\.ly|shorturl\.at|s\.id|lnkd\.in)\b',
      caseSensitive: false,
    ).hasMatch(text);
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: active ? AppColors.corporateRed : AppColors.divider,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LoadingStage {
  final int index;
  final String title;
  final String detail;

  const _LoadingStage({
    required this.index,
    required this.title,
    required this.detail,
  });
}

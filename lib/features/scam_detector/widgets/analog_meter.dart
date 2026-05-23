import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'risk_utils.dart';

enum MeterSize { small, medium, large }

class AnalogMeter extends StatelessWidget {
  const AnalogMeter({
    super.key,
    required this.riskScore,
    this.size = MeterSize.large,
  });

  final int riskScore;
  final MeterSize size;

  @override
  Widget build(BuildContext context) {
    final config = switch (size) {
      MeterSize.small => const _MeterConfig(
        width: 200,
        height: 130,
        radius: 74,
      ),
      MeterSize.medium => const _MeterConfig(
        width: 280,
        height: 180,
        radius: 102,
      ),
      MeterSize.large => const _MeterConfig(
        width: 360,
        height: 230,
        radius: 132,
      ),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: riskScore.toDouble()),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOut,
      builder: (context, animatedValue, child) {
        final score = animatedValue.clamp(0, 100).toDouble();
        final color = riskColor(score.round());
        return SizedBox(
          width: config.width,
          height: config.height,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CustomPaint(
                size: Size(config.width, config.height),
                painter: _MeterPainter(
                  score: score,
                  color: color,
                  config: config,
                ),
              ),
              Positioned(
                bottom: 8,
                child: Column(
                  children: [
                    Text(
                      score.round().toString(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: size == MeterSize.small ? 30 : 54,
                      ),
                    ),
                    const Text(
                      'Risk Score',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MeterConfig {
  const _MeterConfig({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter({
    required this.score,
    required this.color,
    required this.config,
  });

  final double score;
  final Color color;
  final _MeterConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 24);
    final rect = Rect.fromCircle(center: center, radius: config.radius);

    final baseStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18;

    final segmentSweep = math.pi * 0.30;
    baseStroke.color = const Color(0x33059669);
    canvas.drawArc(rect, math.pi, segmentSweep, false, baseStroke);
    baseStroke.color = const Color(0x33F59E0B);
    canvas.drawArc(
      rect,
      math.pi + segmentSweep,
      segmentSweep,
      false,
      baseStroke,
    );
    baseStroke.color = const Color(0x33DC2626);
    canvas.drawArc(
      rect,
      math.pi + segmentSweep * 2,
      segmentSweep,
      false,
      baseStroke,
    );

    final activeStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18
      ..color = color;
    canvas.drawArc(rect, math.pi, math.pi * (score / 100), false, activeStroke);

    final markerPaint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final value in [0, 30, 50, 70, 100]) {
      final angle = math.pi + math.pi * (value / 100);
      final inner = Offset(
        center.dx + (config.radius - 10) * math.cos(angle),
        center.dy + (config.radius - 10) * math.sin(angle),
      );
      final outer = Offset(
        center.dx + (config.radius + 8) * math.cos(angle),
        center.dy + (config.radius + 8) * math.sin(angle),
      );
      canvas.drawLine(inner, outer, markerPaint);

      textPainter.text = TextSpan(
        text: '$value',
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      );
      textPainter.layout();
      final textPos = Offset(
        center.dx +
            (config.radius + 22) * math.cos(angle) -
            (textPainter.width / 2),
        center.dy +
            (config.radius + 22) * math.sin(angle) -
            (textPainter.height / 2),
      );
      textPainter.paint(canvas, textPos);
    }

    final rotation = math.pi + math.pi * (score / 100);
    final needleEnd = Offset(
      center.dx + (config.radius - 16) * math.cos(rotation),
      center.dy + (config.radius - 16) * math.sin(rotation),
    );
    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(needleEnd, 5, Paint()..color = color);
    canvas.drawCircle(center, 10, Paint()..color = const Color(0xCC1F2937));
    canvas.drawCircle(center, 7, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MeterPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

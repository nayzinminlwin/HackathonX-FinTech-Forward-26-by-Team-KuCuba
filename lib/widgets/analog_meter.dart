import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Animated 180° analog risk-score meter.
///
/// Draws a 7-segment arc (green → red) with a tapered needle and
/// LOW / MEDIUM / HIGH labels, matching the Bank Islam gauge design.
///
/// Uses [CustomPainter] per rule.md §6.1. Needle animates over 1200 ms
/// with [Curves.easeOutBack] on first build and on score changes.
///
/// Set [compact] to true for the Phase 2 overlay (smaller rendering).
class AnalogMeter extends StatefulWidget {
  final int riskScore;
  final bool compact;

  const AnalogMeter({
    super.key,
    required this.riskScore,
    this.compact = false,
  });

  @override
  State<AnalogMeter> createState() => _AnalogMeterState();
}

class _AnalogMeterState extends State<AnalogMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _needleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _buildTween();
    _controller.forward();
  }

  void _buildTween() {
    _needleAnimation = Tween<double>(
      begin: 0.0,
      end: widget.riskScore.clamp(0, 100) / 100.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void didUpdateWidget(covariant AnalogMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.riskScore != widget.riskScore) {
      _controller.reset();
      _buildTween();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _scoreColor() {
    final s = widget.riskScore;
    if (s <= 30) return AppColors.meterGreen;
    if (s <= 70) return AppColors.meterYellow;
    return AppColors.meterRed;
  }

  String _riskLabel() {
    final s = widget.riskScore;
    if (s <= 30) return 'Low Risk';
    if (s <= 70) return 'Medium Risk';
    return 'High Risk';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.compact;
    final double w = c ? 200 : 280;
    final double h = c ? 125 : 170;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── The gauge ──
        SizedBox(
          width: w,
          height: h,
          child: AnimatedBuilder(
            animation: _needleAnimation,
            builder: (_, __) => CustomPaint(
              size: Size(w, h),
              painter: _GaugePainter(
                value: _needleAnimation.value,
                compact: c,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Score number ──
        Text(
          'Risk Score: ${widget.riskScore}%',
          style: TextStyle(
            fontSize: c ? 18 : 24,
            fontWeight: FontWeight.bold,
            color: _scoreColor(),
          ),
        ),

        const SizedBox(height: 2),

        // ── Verbal label ──
        Text(
          _riskLabel(),
          style: TextStyle(
            fontSize: c ? 12 : 15,
            fontWeight: FontWeight.w600,
            color: _scoreColor(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Custom painter — 7-segment arc + labels + tapered needle + hub
// ─────────────────────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, this.compact = false});

  /// Normalised risk score: 0.0 (low / left) → 1.0 (high / right).
  final double value;
  final bool compact;

  // 7 arc segment colours (green → red gradient, matching reference).
  static const _segColors = <Color>[
    Color(0xFF4CAF50), // 1  Green
    Color(0xFF8BC34A), // 2  Light green
    Color(0xFFCDDC39), // 3  Lime
    Color(0xFFFFEB3B), // 4  Yellow
    Color(0xFFFF9800), // 5  Orange
    Color(0xFFFF5722), // 6  Deep orange
    Color(0xFFF44336), // 7  Red
  ];

  static const _navy = Color(0xFF1B2A4A);

  @override
  void paint(Canvas canvas, Size size) {
    // ── Layout constants ──
    final thick = compact ? 22.0 : 30.0; // arc stroke width
    final pad = compact ? 28.0 : 38.0; // label gutter
    final cx = size.width / 2;
    final cy = size.height * 0.88; // hub sits near bottom
    final center = Offset(cx, cy);
    final r = cx - pad; // arc centre-line radius

    _drawArcSegments(canvas, center, r, thick);
    _drawLabels(canvas, center, r, thick);
    _drawNeedle(canvas, center, r, thick);
    _drawHub(canvas, center);
  }

  // ── 1. Seven coloured arc segments with gaps ──
  void _drawArcSegments(
      Canvas canvas, Offset center, double r, double thick) {
    const n = 7;
    const gap = 0.05; // radians between segments (~2.9°)
    const sweep = (pi - (n - 1) * gap) / n; // per-segment arc

    final rect = Rect.fromCircle(center: center, radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.butt;

    var angle = pi; // start at 9-o'clock (left)
    for (var i = 0; i < n; i++) {
      paint.color = _segColors[i];
      canvas.drawArc(rect, angle, sweep, false, paint);
      angle += sweep + gap;
    }
  }

  // ── 2. LOW / MEDIUM / HIGH labels ──
  void _drawLabels(
      Canvas canvas, Offset center, double r, double thick) {
    final style = TextStyle(
      color: _navy,
      fontSize: compact ? 10 : 13,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
    );
    final labelR = r + thick / 2 + (compact ? 10 : 14);

    // LOW — lower-left, rotated 60° CCW so it follows the arc
    _paintLabel(canvas, 'LOW', style, center, labelR,
        posAngle: pi + 0.25, rotation: pi / 3);

    // MEDIUM — top centre, horizontal
    _paintLabel(canvas, 'MEDIUM', style, center, labelR,
        posAngle: 3 * pi / 2, rotation: 0);

    // HIGH — lower-right, rotated 60° CW
    _paintLabel(canvas, 'HIGH', style, center, labelR,
        posAngle: 2 * pi - 0.25, rotation: -pi / 3);
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset center,
    double labelR, {
    required double posAngle,
    required double rotation,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final x = center.dx + labelR * cos(posAngle);
    final y = center.dy + labelR * sin(posAngle);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  // ── 3. Tapered needle ──
  void _drawNeedle(
      Canvas canvas, Offset center, double r, double thick) {
    final nAngle = pi + value * pi; // 0 → π (left), 1 → 2π (right)
    final nLen = r - thick * 0.7; // stop before the arc stroke

    // Tip
    final tip = Offset(
      center.dx + nLen * cos(nAngle),
      center.dy + nLen * sin(nAngle),
    );

    // Base half-width perpendicular to needle direction
    final bw = compact ? 4.0 : 5.5;
    final perp = nAngle + pi / 2;
    final bL = Offset(
      center.dx + bw * cos(perp),
      center.dy + bw * sin(perp),
    );
    final bR = Offset(
      center.dx - bw * cos(perp),
      center.dy - bw * sin(perp),
    );

    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(bL.dx, bL.dy)
        ..lineTo(bR.dx, bR.dy)
        ..close(),
      Paint()
        ..color = _navy
        ..style = PaintingStyle.fill,
    );
  }

  // ── 4. Centre hub ──
  void _drawHub(Canvas canvas, Offset center) {
    final outerR = compact ? 9.0 : 13.0;
    canvas.drawCircle(center, outerR, Paint()..color = _navy);
    canvas.drawCircle(
      center,
      outerR * 0.4,
      Paint()..color = const Color(0xFF3D5A80), // subtle highlight
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}
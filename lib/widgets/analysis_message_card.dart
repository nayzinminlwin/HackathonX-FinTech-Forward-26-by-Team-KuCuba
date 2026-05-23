import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'risk_utils.dart';

class AnalysisMessageCard extends StatelessWidget {
  const AnalysisMessageCard({
    super.key,
    required this.message,
    required this.riskScore,
  });

  final String message;
  final int riskScore;

  @override
  Widget build(BuildContext context) {
    final zoneColor = riskColor(riskScore);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: zoneColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(riskIcon(riskScore), color: zoneColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
  }
}

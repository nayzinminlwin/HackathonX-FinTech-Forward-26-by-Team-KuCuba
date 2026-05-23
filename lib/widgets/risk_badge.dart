import 'package:flutter/material.dart';

import 'risk_utils.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.riskScore});

  final int riskScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: riskTint(riskScore),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: riskColor(riskScore),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            riskLabel(riskScore),
            style: TextStyle(
              color: riskShade(riskScore),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

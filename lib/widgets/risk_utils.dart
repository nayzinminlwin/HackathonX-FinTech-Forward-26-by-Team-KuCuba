import 'package:flutter/material.dart';

Color riskColor(int risk) {
  if (risk <= 30) {
    return const Color(0xFF059669);
  }
  if (risk <= 70) {
    return const Color(0xFFF59E0B);
  }
  return const Color(0xFFDC2626);
}

Color riskTint(int risk) {
  if (risk <= 30) {
    return const Color(0xFFECFDF5);
  }
  if (risk <= 70) {
    return const Color(0xFFFEFCE8);
  }
  return const Color(0xFFFEF2F2);
}

Color riskShade(int risk) {
  if (risk <= 30) {
    return const Color(0xFF047857);
  }
  if (risk <= 70) {
    return const Color(0xFFB45309);
  }
  return const Color(0xFFB91C1C);
}

IconData riskIcon(int risk) {
  if (risk > 70) {
    return Icons.cancel;
  }
  if (risk > 30) {
    return Icons.warning_amber_rounded;
  }
  return Icons.check_circle;
}

String riskLabel(int risk) {
  if (risk <= 30) {
    return 'SAFE';
  }
  if (risk <= 70) {
    return 'CAUTION';
  }
  return 'DANGER';
}

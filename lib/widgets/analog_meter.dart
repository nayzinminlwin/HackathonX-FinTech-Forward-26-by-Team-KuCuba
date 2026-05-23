import 'package:flutter/material.dart';

class AnalogMeter extends StatelessWidget {
  final int riskScore;
  const AnalogMeter({super.key, required this.riskScore});

  @override
  Widget build(BuildContext context) {
    Color color = riskScore > 70 ? Colors.red : riskScore > 30 ? Colors.orange : Colors.green;
    return Column(
      children: [
        Icon(Icons.speed, size: 80, color: color),
        Text(
          "Risk Score: $riskScore%",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

class AnalysisMessageCard extends StatelessWidget {
  final String message;
  const AnalysisMessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
      child: Text(message, style: const TextStyle(fontSize: 16)),
    );
  }
}
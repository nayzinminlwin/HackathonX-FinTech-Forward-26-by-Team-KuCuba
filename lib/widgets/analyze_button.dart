import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AnalyzeButton extends StatelessWidget {
  const AnalyzeButton({
    super.key,
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final canPress = enabled && !isLoading && onPressed != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canPress ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canPress ? AppColors.corporateRed : const Color(0xFFBDBDBD),
          disabledBackgroundColor: const Color(0xFFBDBDBD),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Analyze',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

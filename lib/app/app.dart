import 'package:flutter/material.dart';

import '../features/scam_detector/screens/scam_detector_page.dart';
import 'theme/app_theme.dart';

class BeUApp extends StatelessWidget {
  const BeUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Be U Scam Detector',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const ScamDetectorPage(),
    );
  }
}

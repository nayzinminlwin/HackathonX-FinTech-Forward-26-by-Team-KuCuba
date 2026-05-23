import 'package:flutter/material.dart';

import 'screens/intent_router.dart';
import 'theme/bank_islam_theme.dart';

class KuCubaApp extends StatelessWidget {
  const KuCubaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eternal Guardian',
      debugShowCheckedModeBanner: false,
      theme: bankIslamTheme(),
      home: const IntentRouter(),
    );
  }
}

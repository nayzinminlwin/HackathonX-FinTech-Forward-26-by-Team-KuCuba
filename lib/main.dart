import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/analysis_provider.dart';
import 'providers/stats_provider.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = LiveApiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnalysisProvider(apiService)),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
      ],
      child: const KuCubaApp(),
    ),
  );
}

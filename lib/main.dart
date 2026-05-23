import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'providers/analysis_provider.dart';
import 'services/api_service.dart';
import 'services/mock_api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = AppConfig.useMockApi
      ? MockApiService()
      : LiveApiService();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AnalysisProvider(apiService),
      child: const KuCubaApp(),
    ),
  );
}

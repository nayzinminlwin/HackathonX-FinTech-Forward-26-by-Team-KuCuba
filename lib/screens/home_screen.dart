import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../widgets/analysis_message_card.dart';
import '../widgets/analog_meter.dart';
import '../widgets/analyze_button.dart';
import '../widgets/error_banner.dart';
import '../widgets/skeleton_meter_placeholder.dart';
import '../widgets/text_input_area.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onAnalyze() async {
    final text = _textController.text;
    await context.read<AnalysisProvider>().analyze(text);
  }

  void _onRetry() {
    _onAnalyze();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final hasInput = _textController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.shield, size: 28),
        ),
        title: const Text('Scam Detector'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Check any message for scams',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextInputArea(
              controller: _textController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AnalyzeButton(
              enabled: hasInput,
              isLoading: provider.isLoading,
              onPressed: _onAnalyze,
            ),
            const SizedBox(height: 32),
            switch (provider.state) {
              AnalysisState.idle => const SizedBox.shrink(),
              AnalysisState.loading => const SkeletonMeterPlaceholder(),
              AnalysisState.complete when provider.result != null => Column(
                  children: [
                    AnalogMeter(riskScore: provider.result!.riskScore),
                    const SizedBox(height: 16),
                    AnalysisMessageCard(
                      message: provider.result!.analysisMessage,
                      riskScore: provider.result!.riskScore,
                    ),
                  ],
                ),
              AnalysisState.error => ErrorBanner(
                  message: provider.errorMessage ??
                      'Could not analyze. Please try again.',
                  onRetry: hasInput ? _onRetry : null,
                ),
              _ => const SizedBox.shrink(),
            },
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

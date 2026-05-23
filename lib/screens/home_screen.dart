import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../services/notification_service_controller.dart';
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
  bool _guardianModeEnabled = false;
  bool _guardianModeBusy = false;
  String? _guardianModeError;

  @override
  void initState() {
    super.initState();
    _loadGuardianModeStatus();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadGuardianModeStatus() async {
    final isRunning = await NotificationServiceController.isRunning();
    if (!mounted) return;
    setState(() => _guardianModeEnabled = isRunning);
  }

  Future<void> _onAnalyze() async {
    final text = _textController.text;
    await context.read<AnalysisProvider>().analyze(text);
  }

  void _onRetry() {
    _onAnalyze();
  }

  Future<void> _onGuardianModeChanged(bool enabled) async {
    setState(() {
      _guardianModeBusy = true;
      _guardianModeError = null;
    });

    try {
      if (enabled) {
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          setState(() {
            _guardianModeEnabled = false;
            _guardianModeError = 'Notification permission is required.';
          });
          return;
        }
        await NotificationServiceController.startService();
      } else {
        await NotificationServiceController.stopService();
      }

      setState(() => _guardianModeEnabled = enabled);
    } catch (_) {
      setState(() {
        _guardianModeEnabled = false;
        _guardianModeError = 'Guardian Mode could not be updated.';
      });
    } finally {
      if (mounted) {
        setState(() => _guardianModeBusy = false);
      }
    }
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
            const SizedBox(height: 16),
            _GuardianModeTile(
              enabled: _guardianModeEnabled,
              busy: _guardianModeBusy,
              errorMessage: _guardianModeError,
              onChanged: _onGuardianModeChanged,
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

class _GuardianModeTile extends StatelessWidget {
  const _GuardianModeTile({
    required this.enabled,
    required this.busy,
    required this.errorMessage,
    required this.onChanged,
  });

  final bool enabled;
  final bool busy;
  final String? errorMessage;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('Guardian Mode'),
              subtitle: const Text('Pinned notification for paste-to-analyze.'),
              value: enabled,
              onChanged: busy ? null : onChanged,
            ),
            if (busy) const LinearProgressIndicator(minHeight: 2),
            if (errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

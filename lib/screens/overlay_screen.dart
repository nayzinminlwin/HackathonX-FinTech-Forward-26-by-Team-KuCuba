import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/analysis_message_card.dart';
import '../widgets/analog_meter.dart';
import '../widgets/error_banner.dart';
import '../widgets/skeleton_meter_placeholder.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({
    super.key,
    required this.sharedText,
    required this.onDismiss,
  });

  final String sharedText;
  final VoidCallback onDismiss;

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisProvider>().analyze(widget.sharedText);
    });
  }

  void _retry() {
    context.read<AnalysisProvider>().analyze(widget.sharedText);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          widget.onDismiss();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: Stack(
          children: [
            // Scrim — no GestureDetector; tap outside does not dismiss (FR 2.5).
            const ColoredBox(color: AppColors.overlayScrim),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height * 0.88,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    16,
                    24,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.shield,
                            color: AppColors.corporateRed,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Scam Analysis',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: widget.onDismiss,
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                      const Divider(),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.sharedText,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(height: 10),
                              switch (provider.state) {
                                AnalysisState.loading ||
                                AnalysisState.idle =>
                                  SkeletonMeterPlaceholder(
                                    compact: true,
                                    messageText: widget.sharedText,
                                  ),
                                AnalysisState.complete
                                    when provider.result != null =>
                                  Column(
                                    children: [
                                      AnalogMeter(
                                        riskScore: provider.result!.riskScore,
                                        compact: true,
                                      ),
                                      const SizedBox(height: 10),
                                      AnalysisMessageCard(
                                        message:
                                            provider.result!.analysisMessage,
                                        riskScore: provider.result!.riskScore,
                                      ),
                                    ],
                                  ),
                                AnalysisState.error => ErrorBanner(
                                    message: provider.errorMessage ??
                                        'Could not analyze. Please try again.',
                                    onRetry: _retry,
                                  ),
                                _ => const SizedBox.shrink(),
                              },
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onDismiss,
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

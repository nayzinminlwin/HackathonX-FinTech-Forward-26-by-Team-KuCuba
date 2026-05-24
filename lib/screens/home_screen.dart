import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../providers/stats_provider.dart';
import '../theme/app_colors.dart';
import '../models/scam_demo_models.dart';
import '../services/notification_service_controller.dart';
import '../widgets/analysis_message_card.dart';
import '../widgets/analog_meter.dart';
import '../widgets/analyze_button.dart';
import '../widgets/error_banner.dart';
import '../widgets/risk_badge.dart';
import '../widgets/scam_widgets.dart';
import '../widgets/skeleton_meter_placeholder.dart';
import '../widgets/text_input_area.dart';
import 'overlay_screen.dart';

enum AppScreen { home, scan, result }

class ScamDetectorPage extends StatefulWidget {
  const ScamDetectorPage({super.key});

  @override
  State<ScamDetectorPage> createState() => _ScamDetectorPageState();
}

class _ScamDetectorPageState extends State<ScamDetectorPage> {
  final TextEditingController _textController = TextEditingController();

  AppScreen _currentScreen = AppScreen.home;
  int? _lastRecordedRiskScore; // Track to avoid duplicate recordings
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

  Future<void> _analyzeText({String? text}) async {
    final inputText = (text ?? _textController.text).trim();
    if (inputText.isEmpty) return;

    if (text != null) {
      _textController.text = text;
    }

    setState(() => _currentScreen = AppScreen.result);

    if (!mounted) return;
    await context.read<AnalysisProvider>().analyze(inputText);
  }

  void _onRetry() => _analyzeText();

  Future<void> _openBottomSheetDemo() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => OverlayScreen(
        sharedText:
            'Congratulations! You have won RM50,000. Send RM500 fee to claim your prize now!',
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    setState(() => _textController.text = text);
  }

  void _setScreenFromNav(int index) {
    setState(() {
      _currentScreen = switch (index) {
        0 => AppScreen.home,
        1 => AppScreen.scan,
        _ => AppScreen.home,
      };
      _lastRecordedRiskScore = null; // Reset when navigating
    });
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
    return PopScope(
      canPop: _currentScreen == AppScreen.home,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _currentScreen = AppScreen.home);
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: switch (_currentScreen) {
            AppScreen.home => _buildHomeScreen(),
            AppScreen.scan => _buildScanScreen(),
            AppScreen.result => _buildResultScreen(),
          },
        ),
      ),
    );
  }

  // ── Home ──────────────────────────────────────────────────────────────────

  Widget _buildHomeScreen() {
    final stats = context.watch<StatsProvider>();
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 30),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.corporateRed, AppColors.corporateRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        const Icon(Icons.shield, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eternal Guardian',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white, fontSize: 22),
                        ),
                        const Text(
                          'Scam Detector',
                          style:
                              TextStyle(color: Color(0xFFD1FAE5), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                    ),
                    icon: const Icon(Icons.settings, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: GlassStatCard(
                      value: stats.totalScans.toString(),
                      label: 'Scans Protected',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassStatCard(
                      value: stats.threatsBlocked.toString(),
                      label: 'Threats Blocked',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
            children: [
              _buildQuickScanButton(),
              const SizedBox(height: 14),
              _buildGuardianModeCard(),
              const SizedBox(height: 24),
              Text(
                'Try Quick Examples',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 10),
              ...quickScanExamples.map(_buildQuickExampleCard),
              const SizedBox(height: 24),
              Text(
                'Share Sheet Demo',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Material(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openBottomSheetDemo,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Text(
                      'Preview WhatsApp Share Integration',
                      style: TextStyle(
                        color: AppColors.corporateRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
        BottomNavBar(selectedIndex: 0, onSelect: _setScreenFromNav),
      ],
    );
  }

  // ── Scan ──────────────────────────────────────────────────────────────────

  Widget _buildScanScreen() {
    final provider = context.watch<AnalysisProvider>();
    final hasInput = _textController.text.trim().isNotEmpty;

    return Column(
      children: [
        _screenHeader(
          onBack: () => setState(() => _currentScreen = AppScreen.home),
          icon: Icons.arrow_back,
          actionLabel: 'Back',
          title: 'Scan Message',
          subtitle: 'Paste suspicious text or link to analyze',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: ClipRect(
                    child: TextInputArea(
                      controller: _textController,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnalyzeButton(
                  enabled: hasInput,
                  isLoading: provider.isLoading,
                  onPressed: _analyzeText,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _pasteFromClipboard,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF374151),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Paste from Clipboard'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Result ────────────────────────────────────────────────────────────────

  Widget _buildResultScreen() {
    final provider = context.watch<AnalysisProvider>();
    final stats = context.read<StatsProvider>();
    final hasInput = _textController.text.trim().isNotEmpty;

    // Record analysis once when it completes
    if (provider.state == AnalysisState.complete &&
        provider.result != null &&
        _lastRecordedRiskScore != provider.result!.riskScore) {
      _lastRecordedRiskScore = provider.result!.riskScore;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        stats.recordAnalysis(provider.result!.riskScore);
      });
    }

    return Column(
      children: [
        _screenHeader(
          onBack: () => setState(() => _currentScreen = AppScreen.home),
          icon: Icons.home_outlined,
          actionLabel: 'Home',
          title: 'Scan Result',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: switch (provider.state) {
              AnalysisState.idle => const SizedBox.shrink(),
              AnalysisState.loading => Column(
                  children: [
                    const SizedBox(height: 80),
                    SkeletonMeterPlaceholder(
                      messageText: _textController.text,
                    ),
                  ],
                ),
              AnalysisState.error => ErrorBanner(
                  message: provider.errorMessage ??
                      'Could not analyze. Please try again.',
                  onRetry: hasInput ? _onRetry : null,
                ),
              AnalysisState.complete when provider.result != null => Column(
                  children: [
                    AnalogMeter(riskScore: provider.result!.riskScore),
                    const SizedBox(height: 12),
                    RiskBadge(riskScore: provider.result!.riskScore),
                    const SizedBox(height: 12),
                    if (provider.result!.isUnavailable)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Text(
                          'Live backend not reachable. Showing local heuristic estimate.',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    AnalysisMessageCard(
                      message: provider.result!.analysisMessage,
                      riskScore: provider.result!.riskScore,
                    ),
                    const SizedBox(height: 20),
                    if (provider.result!.riskScore > 30)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.corporateRed,
                          ),
                          child: const Text(
                            'Report to Authorities',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () {
                          setState(() {
                            _textController.clear();
                            _currentScreen = AppScreen.scan;
                          });
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: const Color(0xFF374151),
                        ),
                        child: const Text(
                          'Scan Another Message',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildQuickScanButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _currentScreen = AppScreen.scan),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.corporateRed, AppColors.corporateRed],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D10B981),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                _QuickScanIcon(),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Check a message now',
                        style:
                            TextStyle(color: Color(0xFFD1FAE5), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickExampleCard(QuickScanExample example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _analyzeText(text: example.text),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        example.preview,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        example.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuardianModeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _guardianModeEnabled
              ? const Color(0xFFF4B7B6)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _guardianModeEnabled
                      ? const Color(0xFFFFE4E3)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _guardianModeEnabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_outlined,
                  color: _guardianModeEnabled
                      ? AppColors.corporateRed
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guardian Mode',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Keep scam protection running in notifications',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_guardianModeBusy)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Switch(
                  value: _guardianModeEnabled,
                  activeThumbColor: AppColors.corporateRed,
                  onChanged: _onGuardianModeChanged,
                ),
            ],
          ),
          if (_guardianModeError != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFCCD3)),
              ),
              child: Text(
                _guardianModeError!,
                style: const TextStyle(
                  color: Color(0xFFBE123C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _screenHeader({
    required VoidCallback onBack,
    required IconData icon,
    required String actionLabel,
    required String title,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 12, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
              onPressed: onBack, icon: Icon(icon), label: Text(actionLabel)),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _QuickScanIcon extends StatelessWidget {
  const _QuickScanIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.scanner_outlined, color: Colors.white, size: 28),
    );
  }
}

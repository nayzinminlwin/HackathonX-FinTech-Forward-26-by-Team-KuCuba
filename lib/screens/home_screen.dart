import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../models/analysis_result.dart';
import '../models/scam_demo_models.dart';
import '../services/analysis_service.dart';
import '../widgets/analog_meter.dart';
import '../widgets/risk_badge.dart';
import '../widgets/scam_widgets.dart';
import 'overlay_screen.dart';

enum AppScreen { home, scan, result }

class ScamDetectorPage extends StatefulWidget {
  const ScamDetectorPage({super.key});

  @override
  State<ScamDetectorPage> createState() => _ScamDetectorPageState();
}

class _ScamDetectorPageState extends State<ScamDetectorPage> {
  final TextEditingController _textController = TextEditingController();
  final AnalysisService _analysisService = AnalysisService();

  AppScreen _currentScreen = AppScreen.home;
  bool _isLoading = false;
  AnalysisResult? _result;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyzeText({String? text}) async {
    final inputText = (text ?? _textController.text).trim();
    if (inputText.isEmpty) {
      return;
    }

    setState(() {
      _currentScreen = AppScreen.result;
      _isLoading = true;
      _result = null;
      if (text != null) {
        _textController.text = text;
      }
    });

    final result = await _analysisService.analyzeText(inputText);

    if (!mounted) {
      return;
    }

    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  Future<void> _openBottomSheetDemo() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => OverlayScreen(
        sharedText: 'Congratulations! You have won RM50,000. Send RM500 fee to claim your prize now!',
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _textController.text = text;
    });
  }

  void _setScreenFromNav(int index) {
    setState(() {
      _currentScreen = switch (index) {
        0 => AppScreen.home,
        1 => AppScreen.scan,
        _ => AppScreen.home,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentScreen == AppScreen.home, // only exit if on home
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() => _currentScreen = AppScreen.home);
        }
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

  Widget _buildHomeScreen() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 30),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.emerald, AppTheme.emeraldDeep],
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
                    child: const Icon(
                      Icons.shield,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eternal Guardian',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.white, fontSize: 22),
                        ),
                        const Text(
                          'Scam Detector',
                          style: TextStyle(
                            color: Color(0xFFD1FAE5),
                            fontSize: 12,
                          ),
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
              const Row(
                children: [
                  Expanded(
                    child: GlassStatCard(
                      value: '127',
                      label: 'Scans Protected',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GlassStatCard(value: '23', label: 'Threats Blocked'),
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
              const SizedBox(height: 24),
              Text(
                'Try Quick Examples',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 10),
              ...quickScanExamples.map(_buildQuickExampleCard),
              const SizedBox(height: 24),
              Text(
                'Share Sheet Demo',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 18),
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
                        color: AppTheme.primaryBrand,
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

  Widget _buildScanScreen() {
    final canAnalyze = !_isLoading && _textController.text.trim().isNotEmpty;

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
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText:
                            'Paste message here...\n\nExample:\nURGENT! Your bank account has been suspended. Click here to verify: http://fake-link.xyz',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          height: 1.4,
                        ),
                      ),
                    ),
                  )
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canAnalyze ? _analyzeText : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrand,
                    ),
                    icon: const Icon(Icons.scanner_outlined),
                    label: const Text(
                      'Analyze Now',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
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

  Widget _buildResultScreen() {
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
            child: _isLoading
                ? const Column(
                    children: [
                      SizedBox(height: 80),
                      SpinningLoader(size: 80),
                      SizedBox(height: 22),
                      Text(
                        'Analyzing...',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Checking 10,000+ known scams',
                        style: TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  )
                : _result == null
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      AnalogMeter(
                        riskScore: _result!.riskScore,
                      ),
                      const SizedBox(height: 12),
                      RiskBadge(riskScore: _result!.riskScore),
                      const SizedBox(height: 12),
                      if (_result!.isFallback)
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(18),
                          border: const Border(
                            left: BorderSide(
                              color: AppTheme.primaryBrand,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppTheme.primaryBrand,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Analysis',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _result!.analysisMessage,
                              style: const TextStyle(
                                color: Color(0xFF374151),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_result!.riskScore > 30)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryBrand,
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
          ),
        ),
      ],
    );
  }

  Widget _buildQuickScanButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _currentScreen = AppScreen.scan),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.emerald, AppTheme.emeraldDeep],
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
                        style: TextStyle(
                          color: Color(0xFFD1FAE5),
                          fontSize: 14,
                        ),
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
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
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

  Widget _screenHeader({
    required VoidCallback onBack,
    required IconData icon,
    required String actionLabel,
    required String title,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 12, 24, 24), // ← replaces hardcoded 56
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: Icon(icon),
            label: Text(actionLabel),
          ),
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

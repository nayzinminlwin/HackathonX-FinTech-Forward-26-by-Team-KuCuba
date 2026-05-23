import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../widgets/analog_meter.dart';
import '../widgets/analysis_message_card.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyze() {
    if (_controller.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus(); // dismiss keyboard
    context.read<AnalysisProvider>().analyze(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AnalysisProvider>().state;
    final result = context.watch<AnalysisProvider>().result;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('KuCuba Scam Detector', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.corporateRed,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste a message or link below to scan it for scams.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter text here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.corporateRed, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: state == AnalysisState.loading ? null : _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.corporateRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: state == AnalysisState.loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Analyze', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 32),
            
            if (state == AnalysisState.error)
              const Center(
                child: Text(
                  'Failed to connect to backend. Make sure it is running on port 8080.',
                  style: TextStyle(color: Colors.red),
                ),
              ),

            if (state == AnalysisState.complete && result != null) ...[
              const Center(
                child: Text('Analysis Results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              Center(child: AnalogMeter(riskScore: result.riskScore)),
              const SizedBox(height: 24),
              AnalysisMessageCard(message: result.analysisMessage),
            ]
          ],
        ),
      ),
    );
  }
}
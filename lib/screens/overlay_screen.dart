import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../widgets/analog_meter.dart';
import '../widgets/analysis_message_card.dart';

class OverlayScreen extends StatefulWidget {
  final String sharedText;
  final VoidCallback onDismiss;

  const OverlayScreen({
    super.key,
    required this.sharedText,
    required this.onDismiss,
  });

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-trigger the AI analysis instantly when the sheet opens. No buttons required.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisProvider>().analyze(widget.sharedText);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AnalysisProvider>().state;
    final result = context.watch<AnalysisProvider>().result;

    return PopScope(
      canPop: false, // Prevent accidental back-button exit messing up the intent
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onDismiss();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // This keeps WhatsApp visible behind it
        body: Stack(
          children: [
            // The Dark Semi-transparent Scrim
            Container(color: Colors.black54),
            
            // The Bottom Sheet Panel
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("🛡️ Scam Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: widget.onDismiss,
                        ),
                      ],
                    ),
                    const Divider(),
                    
                    // The Suspicious Message Preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        widget.sharedText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Analysis UI (Re-using your teammate's Phase 1 widgets)
                    if (state == AnalysisState.loading)
                      const CircularProgressIndicator(color: Color(0xFFED2321)), // Bank Islam Red
                    
                    if (state == AnalysisState.complete && result != null) ...[
                      AnalogMeter(riskScore: result.riskScore),
                      const SizedBox(height: 16),
                      AnalysisMessageCard(message: result.analysisMessage),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFED2321)),
                        onPressed: widget.onDismiss,
                        child: const Text("Done", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
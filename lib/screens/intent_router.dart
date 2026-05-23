import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'home_screen.dart';
import 'overlay_screen.dart';

class IntentRouter extends StatefulWidget {
  const IntentRouter({super.key});

  @override
  State<IntentRouter> createState() => _IntentRouterState();
}

class _IntentRouterState extends State<IntentRouter> {
  StreamSubscription? _intentSub;
  String? _sharedText;
  bool _isFromShare = false;

  @override
  void initState() {
    super.initState();
    
    // 1. Check if the app was opened directly via a Share intent (Cold Start)
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        setState(() {
          _sharedText = value.first.path; // For text/plain, the text is stored in 'path'
          _isFromShare = true;
        });
      }
    });

    // 2. Listen for share intents if the app was already running in the background (Warm Start)
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          setState(() {
            _sharedText = value.first.path;
            _isFromShare = true;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If we received text from WhatsApp/SMS, show the invisible overlay screen
    if (_isFromShare && _sharedText != null) {
      return OverlayScreen(
        sharedText: _sharedText!,
        onDismiss: () {
          ReceiveSharingIntent.instance.reset(); // Clear the intent
          SystemNavigator.pop(); // Close the overlay and return cleanly to WhatsApp
        },
      );
    }
    // Otherwise, show the normal Phase 1 app screen your teammate built
    return const HomeScreen(); 
  }
}
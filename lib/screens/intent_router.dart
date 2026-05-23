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

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _handleSharedMedia(value);
    });

    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleSharedMedia,
    );
  }

  void _handleSharedMedia(List<SharedMediaFile> value) {
    if (value.isEmpty) {
      return;
    }

    final text = value.first.path.trim();
    if (text.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _sharedText = text;
      _isFromShare = true;
    });
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  void _dismissOverlay() {
    ReceiveSharingIntent.instance.reset();
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFromShare && _sharedText != null) {
      return OverlayScreen(
        sharedText: _sharedText!,
        onDismiss: _dismissOverlay,
      );
    }

    return const ScamDetectorPage();
  }
}

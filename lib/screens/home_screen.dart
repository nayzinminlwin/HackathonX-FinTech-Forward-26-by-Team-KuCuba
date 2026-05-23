import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eternal Guardian')),
      body: const Center(child: Text('Phase 1 UI - Waiting for Ariff tomorrow!')),
    );
  }
}
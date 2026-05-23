import 'package:flutter/material.dart';

class TextInputArea extends StatelessWidget {
  const TextInputArea({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 4,
      maxLines: 8,
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Paste a suspicious message or conversation here...',
        alignLabelWithHint: true,
      ),
    );
  }
}

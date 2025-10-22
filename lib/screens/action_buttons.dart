import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onClearPressed;
  final VoidCallback onHintPressed;
  final VoidCallback onNewGamePressed;
  final bool showHint;

  const ActionButtons({
    Key? key,
    required this.onClearPressed,
    required this.onHintPressed,
    required this.onNewGamePressed,
    this.showHint = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onClearPressed,
            icon: const Icon(Icons.backspace),
            label: const Text('Xóa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (showHint) ...[
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onHintPressed,
            icon: const Icon(Icons.lightbulb),
            label: const Text('Gợi ý'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onNewGamePressed,
            icon: const Icon(Icons.refresh),
            label: const Text('Mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
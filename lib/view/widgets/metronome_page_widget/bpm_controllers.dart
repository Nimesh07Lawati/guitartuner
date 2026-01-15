import 'package:flutter/material.dart';

class BPMControls extends StatelessWidget {
  final int bpm;
  final VoidCallback onPlus;
  final VoidCallback onMinus;

  const BPMControls({
    super.key,
    required this.bpm,
    required this.onPlus,
    required this.onMinus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('BPM', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: onMinus, icon: const Icon(Icons.remove)),
            Text(
              '$bpm',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            IconButton(onPressed: onPlus, icon: const Icon(Icons.add)),
          ],
        ),
      ],
    );
  }
}

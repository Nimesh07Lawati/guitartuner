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
        const Text(
          'BPM',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minus Button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2A2A2A),
              ),
              child: IconButton(
                onPressed: onMinus,
                icon: const Icon(Icons.remove),
                color: const Color(0xFFF27121),
                iconSize: 28,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ),

            const SizedBox(width: 20),

            // BPM Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFF27121).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Text(
                '$bpm',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Plus Button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2A2A2A),
              ),
              child: IconButton(
                onPressed: onPlus,
                icon: const Icon(Icons.add),
                color: const Color(0xFFF27121),
                iconSize: 28,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class PendulumVisualizer extends StatelessWidget {
  final int beats;
  final int currentBeat;
  final bool isPlaying;

  const PendulumVisualizer({
    super.key,
    required this.beats,
    required this.currentBeat,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(beats, (i) {
            final beat = i + 1;
            final active = beat == currentBeat && isPlaying;

            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: active
                    ? (beat == 1 ? Colors.green : const Color(0xFFF27121))
                    : Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$beat',
                  style: TextStyle(
                    color: active ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 30),
        AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 4,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8A2387), Color(0xFFF27121), Color(0xFFE94057)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

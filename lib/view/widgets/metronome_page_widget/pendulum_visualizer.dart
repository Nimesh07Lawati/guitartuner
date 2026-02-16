import 'package:flutter/material.dart';
import 'dart:math' as math;

class PendulumVisualizer extends StatefulWidget {
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
  State<PendulumVisualizer> createState() => _PendulumVisualizerState();
}

class _PendulumVisualizerState extends State<PendulumVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _swingController;
  late Animation<double> _swingAnimation;

  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _swingAnimation = Tween<double>(begin: -0.3, end: 0.3).animate(
      CurvedAnimation(parent: _swingController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(PendulumVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger swing animation on beat change
    if (widget.currentBeat != oldWidget.currentBeat && widget.isPlaying) {
      _swingController.reset();
      _swingController.forward();
    }

    // Stop animation when not playing
    if (!widget.isPlaying && oldWidget.isPlaying) {
      _swingController.reset();
    }
  }

  @override
  void dispose() {
    _swingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Beat indicators with improved styling
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.beats, (i) {
              final beat = i + 1;
              final active = beat == widget.currentBeat && widget.isPlaying;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: active
                      ? (beat == 1 ? Colors.green : const Color(0xFFF27121))
                      : Colors.white24,
                  shape: BoxShape.circle,
                  border: active
                      ? null
                      : Border.all(color: Colors.white38, width: 1),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color:
                                (beat == 1
                                        ? Colors.green
                                        : const Color(0xFFF27121))
                                    .withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$beat',
                    style: TextStyle(
                      color: active ? Colors.black : Colors.white,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 40),

        // Animated Pendulum
        SizedBox(
          height: 180,
          child: AnimatedBuilder(
            animation: _swingAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: widget.isPlaying ? _swingAnimation.value : 0,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Pendulum string
                    Container(
                      width: 4,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8A2387),
                            Color(0xFFF27121),
                            Color(0xFFE94057),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Pendulum weight
                    Positioned(
                      top: 130,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const RadialGradient(
                            colors: [Color(0xFFF27121), Color(0xFF8A2387)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF27121).withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Pivot point (outside rotation)
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFF27121),
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(height: 20),

        // Current beat indicator when playing
        if (widget.isPlaying)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.currentBeat == 1
                        ? Colors.green
                        : const Color(0xFFF27121),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Beat ${widget.currentBeat} of ${widget.beats}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

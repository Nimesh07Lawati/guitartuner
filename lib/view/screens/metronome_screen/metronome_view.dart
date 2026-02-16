import 'package:flutter/material.dart';
import 'package:guitartuner/view/widgets/metronome_page_widget/bpm_controllers.dart';
import 'package:guitartuner/view/widgets/metronome_page_widget/pendulum_visualizer.dart';
import 'metronome_controller.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen>
    with SingleTickerProviderStateMixin {
  late MetronomeController controller;

  @override
  void initState() {
    super.initState();
    controller = MetronomeController(this);
  }

  @override
  void dispose() {
    controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Scaffold(
          backgroundColor: const Color(0xFF141414),
          appBar: AppBar(
            title: const Text(
              'Metronome',
              style: TextStyle(fontWeight: FontWeight.w300, letterSpacing: 1.5),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // BPM Controls with enhanced styling
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: BPMControls(
                      bpm: controller.bpm,
                      onPlus: controller.incrementBpm,
                      onMinus: controller.decrementBpm,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Time Signature Selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Time Signature:',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: controller.timeSignature,
                              dropdownColor: const Color(0xFF2A2A2A),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFFF27121),
                              ),
                              items: [2, 3, 4, 5, 6].map((value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text('$value/4'),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  controller.updateTimeSignature(value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Pendulum Visualizer
                  Expanded(
                    child: PendulumVisualizer(
                      beats: controller.timeSignature,
                      currentBeat: controller.currentBeat,
                      isPlaying: controller.isPlaying,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Play/Stop Button
                  Container(
                    width: double.infinity,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: controller.isPlaying
                          ? controller.stop
                          : controller.start,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isPlaying
                            ? const Color(0xFFE94057)
                            : const Color(0xFFF27121),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        controller.isPlaying ? 'Stop' : 'Start',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

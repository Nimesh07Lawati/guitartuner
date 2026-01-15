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
          appBar: AppBar(title: const Text('Metronome')),
          body: Column(
            children: [
              BPMControls(
                bpm: controller.bpm,
                onPlus: controller.incrementBpm,
                onMinus: controller.decrementBpm,
              ),
              Expanded(
                child: PendulumVisualizer(
                  beats: controller.timeSignature,
                  currentBeat: controller.currentBeat,
                  isPlaying: controller.isPlaying,
                ),
              ),
              ElevatedButton(
                onPressed: controller.isPlaying
                    ? controller.stop
                    : controller.start,
                child: Text(controller.isPlaying ? 'Stop' : 'Start'),
              ),
            ],
          ),
        );
      },
    );
  }
}

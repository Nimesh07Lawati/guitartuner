import 'package:flutter/material.dart';
import '../../../models/guitar_string.dart';
import 'guitar_tuner_controller.dart';
import '../widgets/guitar_tuner_page_widget/tuning_button.dart';

class GuitarTunerScreen extends StatefulWidget {
  const GuitarTunerScreen({super.key});

  @override
  State<GuitarTunerScreen> createState() => _GuitarTunerScreenState();
}

class _GuitarTunerScreenState extends State<GuitarTunerScreen> {
  late GuitarTunerController controller;

  final guitarStrings = const [
    GuitarString(name: 'E', note: 'E', frequency: 82.41, stringNumber: 6),
    GuitarString(name: 'A', note: 'A', frequency: 110.00, stringNumber: 5),
    GuitarString(name: 'D', note: 'D', frequency: 146.83, stringNumber: 4),
    GuitarString(name: 'G', note: 'G', frequency: 196.00, stringNumber: 3),
    GuitarString(name: 'B', note: 'B', frequency: 246.94, stringNumber: 2),
    GuitarString(name: 'E', note: 'E', frequency: 329.63, stringNumber: 1),
  ];

  @override
  void initState() {
    super.initState();
    controller = GuitarTunerController(guitarStrings);
  }

  @override
  void dispose() {
    controller.audioHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Scaffold(
          backgroundColor: const Color(0xFF141414),
          appBar: AppBar(title: const Text('Guitar Tuner')),
          body: Column(
            children: [
              Expanded(child: Container()), // other widgets
              TuningButton(
                isTuning: controller.isTuning,
                onPressed: controller.isTuning
                    ? controller.stopTuning
                    : () => controller.startTuning(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

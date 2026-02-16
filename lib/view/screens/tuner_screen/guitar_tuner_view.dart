import 'package:flutter/material.dart';
import 'package:guitartuner/view/widgets/guitar_tuner_page_widget/frequency_display.dart';
import 'package:guitartuner/view/widgets/guitar_tuner_page_widget/radial_gauge.dart';
import 'package:guitartuner/view/widgets/guitar_tuner_page_widget/string_selector.dart';
import 'package:guitartuner/view/widgets/guitar_tuner_page_widget/tuning_button.dart';
import 'package:guitartuner/view/widgets/guitar_tuner_page_widget/tuning_header.dart';
import '../../../../models/guitar_string.dart';
import 'guitar_tuner_controller.dart';

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
          appBar: AppBar(
            title: const Text('Guitar Tuner'),
            backgroundColor: Colors.black,
          ),
          body: SafeArea(
            child: Column(
              children: [
                /// 🔹 HEADER (Tuning Mode + Status)
                TuningHeader(
                  mode: controller.currentMode,
                  statusText: controller.statusText,
                  statusColor: controller.statusColor,
                ),

                const SizedBox(height: 10),

                /// 🔹 STRING SELECTOR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StringSelector(
                    strings: guitarStrings,
                    selectedIndex: controller.selectedIndex,
                    autoDetectedIndex: controller.autoDetectedIndex,
                    onSelect: controller.selectString,
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔹 RADIAL GAUGE
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TunerRadialGauge(
                      needleValue: controller.cents,
                      string: controller.currentString,
                      statusColor: controller.statusColor,
                      autoDetected: controller.autoDetectedIndex != null,
                    ),
                  ),
                ),

                /// 🔹 FREQUENCY DISPLAY
                FrequencyDisplay(
                  isTuning: controller.isTuning,
                  currentFrequency: controller.currentFrequency,
                  targetFrequency: controller.currentString.frequency,
                  cents: controller.cents,
                  statusColor: controller.statusColor,
                  currentString: controller.currentString,
                  autoDetected: controller.autoDetectedIndex != null,
                ),

                const SizedBox(height: 10),

                /// 🔹 START / STOP BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: TuningButton(
                    isTuning: controller.isTuning,
                    onPressed: controller.isTuning
                        ? controller.stopTuning
                        : () => controller.startTuning(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../models/guitar_string.dart';
import '../../../utils/audio_pitch_helper.dart';

class GuitarTunerController extends ChangeNotifier {
  late AudioPitchHelper audioHelper;

  double currentFrequency = 0.0;
  bool isTuning = false;
  int selectedStringIndex = 0;
  int? autoDetectedStringIndex;

  final List<GuitarString> guitarStrings;

  GuitarTunerController(this.guitarStrings) {
    audioHelper = AudioPitchHelper(
      detectionThreshold: 0.7,
      onFrequencyDetected: _onFrequencyDetected,
    );
  }

  void _onFrequencyDetected(double freq) {
    currentFrequency = freq;
    _autoDetectString(freq);
    notifyListeners();
  }

  Future<void> startTuning(BuildContext context) async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      await audioHelper.start();
      isTuning = true;
      notifyListeners();
    }
  }

  Future<void> stopTuning() async {
    await audioHelper.stop();
    isTuning = false;
    currentFrequency = 0;
    autoDetectedStringIndex = null;
    notifyListeners();
  }

  void selectString(int index) {
    selectedStringIndex = index;
    autoDetectedStringIndex = null;
    notifyListeners();
  }

  void _autoDetectString(double frequency) {
    if (frequency <= 0) return;

    final closest = AudioPitchHelper.findClosestFrequency(
      frequency,
      guitarStrings.map((s) => s.frequency).toList(),
    );

    autoDetectedStringIndex = guitarStrings.indexWhere(
      (s) => s.frequency == closest,
    );
  }

  double get needleValue {
    if (!isTuning || currentFrequency <= 0) return 0;
    final target =
        guitarStrings[autoDetectedStringIndex ?? selectedStringIndex].frequency;

    final cents = AudioPitchHelper.centsDifference(
      currentFrequency,
      target,
    ).clamp(-50.0, 50.0);

    return cents.abs() < 1 ? 0 : cents;
  }
}

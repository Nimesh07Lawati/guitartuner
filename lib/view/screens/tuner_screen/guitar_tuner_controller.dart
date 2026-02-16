import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../models/guitar_string.dart';
import '../../../../models/tuning_mode.dart';
import '../../../../utils/audio_pitch_helper.dart';

class GuitarTunerController extends ChangeNotifier {
  late AudioPitchHelper audioHelper;

  double currentFrequency = 0.0;
  bool isTuning = false;
  int selectedStringIndex = 0;
  int? autoDetectedStringIndex;

  TuningMode _currentMode = TuningMode.standard;

  GuitarTunerController(List<GuitarString> _) {
    audioHelper = AudioPitchHelper(
      detectionThreshold: 0.7,
      onFrequencyDetected: _onFrequencyDetected,
    );
  }

  // =========================
  // GETTERS
  // =========================

  TuningMode get currentMode => _currentMode;

  List<GuitarString> get guitarStrings => _currentMode.strings;

  int get selectedIndex => selectedStringIndex;

  int? get autoDetectedIndex => autoDetectedStringIndex;

  GuitarString get currentString =>
      guitarStrings[autoDetectedStringIndex ?? selectedStringIndex];

  double get cents {
    if (!isTuning || currentFrequency <= 0) return 0;

    return AudioPitchHelper.centsDifference(
      currentFrequency,
      currentString.frequency,
    ).clamp(-50.0, 50.0);
  }

  Color get statusColor {
    if (!isTuning) return Colors.grey;

    final diff = cents.abs();

    if (diff <= 2) return Colors.green;
    if (diff <= 8) return Colors.orange;
    return Colors.red;
  }

  String get statusText {
    if (!isTuning) return "Idle";

    if (cents.abs() <= 2) return "Perfect";
    if (cents > 0) return "Sharp";
    return "Flat";
  }

  double get needleValue => cents;

  // =========================
  // METHODS
  // =========================

  void changeTuningMode(TuningMode mode) {
    _currentMode = mode;
    selectedStringIndex = 0;
    autoDetectedStringIndex = null;
    notifyListeners();
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
}

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';

/// Callback triggered when a new frequency (Hz) is detected.
typedef FrequencyCallback = void Function(double frequency);

class AudioPitchHelper {
  final _audioCapture = FlutterAudioCapture();
  late PitchDetector _pitchDetector;
  final FrequencyCallback onFrequencyDetected;

  final int sampleRate;
  final int bufferSize;
  final double detectionThreshold;

  bool _isRunning = false;

  AudioPitchHelper({
    required this.onFrequencyDetected,
    this.sampleRate = 44100,
    this.bufferSize = 2048,
    this.detectionThreshold = 0.8,
  }) {
    _pitchDetector = PitchDetector(
      audioSampleRate: sampleRate.toDouble(),
      bufferSize: bufferSize,
    );
  }

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      await _audioCapture.start(
        _onAudioData,
        _onError,
        sampleRate: sampleRate,
        bufferSize: bufferSize,
      );
    } catch (e) {
      print('AudioPitchHelper start error: $e');
      _isRunning = false;
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    try {
      await _audioCapture.stop();
    } catch (e) {
      print('AudioPitchHelper stop error: $e');
    } finally {
      _isRunning = false;
    }
  }

  void _onError(dynamic error) {
    print('AudioPitchHelper error: $error');
  }

  void _onAudioData(dynamic obj) {
    if (!_isRunning) return;

    try {
      if (obj is Float32List) {
        final samples = obj.map((v) => v.toDouble()).toList();
        final result = _pitchDetector.getPitchFromFloatBuffer(samples);
        _handleResult(result);
      } else if (obj is Uint8List) {
        final result = _pitchDetector.getPitchFromIntBuffer(obj);
        _handleResult(result);
      } else if (obj is List) {
        final doubles = obj.map((e) => (e as num).toDouble()).toList();
        final result = _pitchDetector.getPitchFromFloatBuffer(doubles);
        _handleResult(result);
      }
    } catch (e) {
      print('AudioPitchHelper process error: $e');
    }
  }

  void _handleResult(dynamic result) {
    if (result == null) return;
    final double? pitch = result.pitch as double?;
    final double? probability = result.probability as double?;
    final bool? pitched = result.pitched as bool?;

    if (pitched == true &&
        probability != null &&
        probability > detectionThreshold &&
        pitch != null &&
        pitch > 0) {
      onFrequencyDetected(pitch);
    }
  }

  /// Returns cent difference between detected and target frequency.
  static double centsDifference(double detected, double target) {
    if (detected <= 0 || target <= 0) return 0;
    return 1200 * (log(detected / target) / ln2);
  }
}

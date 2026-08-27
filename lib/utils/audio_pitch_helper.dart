import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitch_detector_dart/pitch_detector_result.dart';

/// Callback triggered when a new frequency (Hz) is detected.
typedef FrequencyCallback = void Function(double frequency);

class AudioPitchHelper {
  final _audioCapture = FlutterAudioCapture();
  final FrequencyCallback onFrequencyDetected;

  final int sampleRate;
  final int bufferSize;
  final double detectionThreshold;

  bool _isRunning = false;
  bool _isInitialized = false;
  int _audioDataCallCount = 0;
  bool _isProcessing = false;

  // Pitch detector runs on the main isolate. YIN's difference function is
  // O(bufferSize^2) — roughly 1M iterations at the default 2048 — so each
  // buffer blocks the UI thread for a few ms. That is still cheaper than the
  // per-buffer ReceivePort churn the old isolate version paid. If low-end
  // devices ever show jank on the tuner screen, halve `bufferSize`: the cost
  // is quadratic, so 1024 quarters the work and still resolves guitar's
  // 82-330Hz range comfortably.
  PitchDetector? _detector;

  // Improved pitch smoothing
  final List<double> _pitchBuffer = [];
  static const int _bufferSize = 5; // Number of readings to average
  static const double _confidenceThreshold = 0.7; // Higher confidence threshold

  // Frequency validation
  // Floor has to clear the lowest target we ship (Drop C's C2 at 65.41Hz)
  // with room to spare, or a string that is genuinely flat reads as silence
  // and the tuner shows nothing at the exact moment it is needed. 60Hz gives
  // C2 a full semitone of headroom below pitch.
  static const double minValidFrequency = 60.0;
  static const double maxValidFrequency = 450.0; // For high E string harmonics

  AudioPitchHelper({
    required this.onFrequencyDetected,
    this.sampleRate = 44100,
    this.bufferSize = 2048,
    this.detectionThreshold = 0.7, // Higher threshold for more accuracy
  });

  bool get isRunning => _isRunning;

  void _initDetector() {
    _detector ??= PitchDetector(
      audioSampleRate: sampleRate.toDouble(),
      bufferSize: bufferSize,
    );
  }

  Future<void> start() async {
    if (_isRunning) {
      return;
    }

    _initDetector();

    _audioDataCallCount = 0;
    _isProcessing = false;
    _pitchBuffer.clear();

    try {
      if (!_isInitialized) {
        await _audioCapture.init();
        _isInitialized = true;
      }

      await _audioCapture.start(listener, (error) {
        // handle error
      }, sampleRate: sampleRate);
      _isRunning = true;
    } catch (e) {
      // handle error
    }
  }

  void listener(dynamic obj) {
    if (!_isRunning || _isProcessing) return;

    _audioDataCallCount++;

    // Don't await - process asynchronously to avoid blocking the mic callback
    _processAudioData(obj);
  }

  Future<void> _processAudioData(dynamic obj) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      if (obj is Float32List) {
        final samples = obj.map((v) => v.toDouble()).toList();

        // Improved RMS calculation with better threshold
        final rms = _calculateRMS(samples);
        if (rms < 0.01) {
          // Adjusted threshold for better sensitivity
          return;
        }

        await _detectPitch(samples);
      }
    } catch (e) {
      if (_audioDataCallCount <= 10) {
        // handle error
      }
    } finally {
      _isProcessing = false;
    }
  }

  double _calculateRMS(List<double> samples) {
    if (samples.isEmpty) return 0;
    double sum = 0;
    for (var sample in samples) {
      sum += sample * sample;
    }
    return sqrt(sum / samples.length);
  }

  Future<void> _detectPitch(List<double> samples) async {
    if (_detector == null) return;

    try {
      // No timeout here: YIN does all its work synchronously and only wraps
      // the result in a Future at the very end, so the future is already
      // complete by the time anything could attach to it. The only real lever
      // on how long this blocks is `bufferSize`, below.
      final result = await _detector!.getPitchFromFloatBuffer(samples);
      _handleResult(result);
    } catch (e) {
      // Silently handle detection errors
    }
  }

  void _handleResult(PitchDetectorResult result) {
    final pitch = result.pitch;
    final prob = result.probability;
    final pitched = result.pitched;

    // Improved validation with guitar-specific frequency range
    if (pitched == true &&
        prob > _confidenceThreshold &&
        pitch >= minValidFrequency &&
        pitch <= maxValidFrequency) {
      // Add to buffer for smoothing
      _pitchBuffer.add(pitch);

      // Keep buffer at fixed size
      if (_pitchBuffer.length > _bufferSize) {
        _pitchBuffer.removeAt(0);
      }

      // Calculate median for more stable reading (better than average for pitch)
      final smoothedPitch = _calculateMedian(_pitchBuffer);

      // Send smoothed pitch for display
      onFrequencyDetected(smoothedPitch);
    } else if (_pitchBuffer.isNotEmpty) {
      // If no valid pitch but we have previous data, gradually clear buffer
      if (_pitchBuffer.length > 1) {
        _pitchBuffer.removeAt(0);
        final smoothedPitch = _calculateMedian(_pitchBuffer);
        onFrequencyDetected(smoothedPitch);
      }
    }
  }

  double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;

    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;

    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;
    _pitchBuffer.clear();
    await _audioCapture.stop();
  }

  void dispose() {
    stop();
    _detector = null;
  }

  /// Calculate the difference in cents between current and target frequency
  /// Cents = 1200 * log2(f1/f2)
  static double centsDifference(
    double currentFrequency,
    double targetFrequency,
  ) {
    if (currentFrequency <= 0 || targetFrequency <= 0) return 0;
    return 1200 * (log(currentFrequency / targetFrequency) / ln2);
  }

  /// Find the closest guitar string frequency to the detected pitch
  static double findClosestFrequency(
    double currentFrequency,
    List<double> targetFrequencies,
  ) {
    if (targetFrequencies.isEmpty) return 0;

    double closestFreq = targetFrequencies[0];
    double minDiff = (currentFrequency - closestFreq).abs();

    for (var freq in targetFrequencies) {
      final diff = (currentFrequency - freq).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestFreq = freq;
      }
    }

    return closestFreq;
  }
}

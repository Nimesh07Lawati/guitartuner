import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitch_detector_dart/pitch_detector_result.dart';

// --- Isolate entry function ---
void pitchDetectionIsolate(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  PitchDetector? detector;
  int? currentSampleRate;
  int? currentBufferSize;

  receivePort.listen((message) async {
    try {
      final samples = message[0] as List<double>;
      final sampleRate = message[1] as int;
      final bufferSize = message[2] as int;
      final SendPort replyPort = message[3] as SendPort;

      // Only create detector if parameters changed or first time
      if (detector == null ||
          currentSampleRate != sampleRate ||
          currentBufferSize != bufferSize) {
        detector = PitchDetector(
          audioSampleRate: sampleRate.toDouble(),
          bufferSize: bufferSize,
        );
        currentSampleRate = sampleRate;
        currentBufferSize = bufferSize;
      }

      final result = await detector!.getPitchFromFloatBuffer(samples);
      replyPort.send(result);
    } catch (e) {
      print('❌ Isolate error: $e');
    }
  });
}

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
  int _validPitchCount = 0;
  bool _isProcessing = false;

  // Improved pitch smoothing
  final List<double> _pitchBuffer = [];
  static const int _bufferSize = 5; // Number of readings to average
  static const double _confidenceThreshold = 0.7; // Higher confidence threshold

  // Frequency validation
  static const double _minValidFrequency = 65.0; // Lowered for bass strings
  static const double _maxValidFrequency = 450.0; // For high E string harmonics

  // --- Isolate communication ports ---
  Isolate? _isolate;
  SendPort? _isolateSendPort;

  AudioPitchHelper({
    required this.onFrequencyDetected,
    this.sampleRate = 44100,
    this.bufferSize = 2048,
    this.detectionThreshold = 0.7, // Higher threshold for more accuracy
  });

  bool get isRunning => _isRunning;

  Future<void> _initIsolate() async {
    if (_isolateSendPort != null) return;

    print('🚀 Spawning pitch detection isolate...');
    final readyPort = ReceivePort();
    _isolate = await Isolate.spawn(pitchDetectionIsolate, readyPort.sendPort);
    _isolateSendPort = await readyPort.first as SendPort;
    print('✅ Pitch detection isolate ready');
  }

  Future<void> start() async {
    if (_isRunning) {
      print('⚠️ AudioPitchHelper already running');
      return;
    }

    await _initIsolate();

    _audioDataCallCount = 0;
    _validPitchCount = 0;
    _isProcessing = false;
    _pitchBuffer.clear();

    try {
      if (!_isInitialized) {
        print('🔧 Initializing FlutterAudioCapture...');
        await _audioCapture.init();
        _isInitialized = true;
      }

      print('🎙️ Starting audio capture...');
      await _audioCapture.start(listener, (error) {
        print('❌ Audio capture error: $error');
      }, sampleRate: sampleRate);
      _isRunning = true;
    } catch (e) {
      print('❌ Error starting audio capture: $e');
    }
  }

  void listener(dynamic obj) {
    if (!_isRunning || _isProcessing) return;

    _audioDataCallCount++;

    // Don't await - process asynchronously to avoid blocking
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

        await _sendToIsolate(samples);
      }
    } catch (e) {
      if (_audioDataCallCount <= 10) {
        print('❌ AudioPitchHelper process error: $e');
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

  Future<void> _sendToIsolate(List<double> samples) async {
    if (_isolateSendPort == null) return;

    final responsePort = ReceivePort();

    try {
      _isolateSendPort!.send([
        samples,
        sampleRate,
        bufferSize,
        responsePort.sendPort,
      ]);

      final result = await responsePort.first.timeout(
        const Duration(
          milliseconds: 150,
        ), // Reduced timeout for faster response
        onTimeout: () => null,
      );

      if (result is PitchDetectorResult) {
        _handleResult(result);
      }
    } catch (e) {
      // Silently handle timeout errors
    } finally {
      responsePort.close();
    }
  }

  void _handleResult(PitchDetectorResult result) {
    final pitch = result.pitch;
    final prob = result.probability;
    final pitched = result.pitched;

    // Improved validation with guitar-specific frequency range
    if (pitched == true &&
        prob != null &&
        prob > _confidenceThreshold && // Use higher confidence
        pitch != null &&
        pitch >= _minValidFrequency &&
        pitch <= _maxValidFrequency) {
      // Add to buffer for smoothing
      _pitchBuffer.add(pitch);

      // Keep buffer at fixed size
      if (_pitchBuffer.length > _bufferSize) {
        _pitchBuffer.removeAt(0);
      }

      // Calculate median for more stable reading (better than average for pitch)
      final smoothedPitch = _calculateMedian(_pitchBuffer);

      _validPitchCount++;

      if (_validPitchCount % 15 == 0) {
        print(
          '✅ Pitch: ${smoothedPitch.toStringAsFixed(2)} Hz | Confidence: ${prob.toStringAsFixed(2)} | Buffer: ${_pitchBuffer.length}',
        );
      }

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
    print('🛑 Stopping audio capture...');
    _isRunning = false;
    _pitchBuffer.clear();
    await _audioCapture.stop();
  }

  void dispose() {
    stop();
    if (_isolate != null) {
      print('🧹 Killing pitch detection isolate...');
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
      _isolateSendPort = null;
    }
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

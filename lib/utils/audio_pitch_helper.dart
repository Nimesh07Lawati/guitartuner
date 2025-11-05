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

  // Pitch smoothing
  final List<double> _recentPitches = [];
  static const int _smoothingWindowSize = 5;

  // --- Isolate communication ports ---
  Isolate? _isolate;
  SendPort? _isolateSendPort;

  AudioPitchHelper({
    required this.onFrequencyDetected,
    this.sampleRate = 44100,
    this.bufferSize = 2048,
    this.detectionThreshold = 0.8,
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
    if (_audioDataCallCount % 50 == 0) {
      print('📡 Audio data callback #$_audioDataCallCount');
    }

    // Don't await - process asynchronously to avoid blocking
    _processAudioData(obj);
  }

  Future<void> _processAudioData(dynamic obj) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      if (obj is Float32List) {
        if (_audioDataCallCount == 1) {
          print('📊 Received Float32List with ${obj.length} samples');
        }

        final samples = obj.map((v) => v.toDouble()).toList();

        // Check if audio is loud enough (RMS amplitude check)
        final rms = _calculateRMS(samples);
        if (rms < 0.01) {
          // Ignore very quiet sounds
          if (_audioDataCallCount <= 5) {
            print('🔇 Audio too quiet, RMS: ${rms.toStringAsFixed(4)}');
          }
          return;
        }

        await _sendToIsolate(samples);
      } else {
        print('⚠️ Unknown audio data type: ${obj.runtimeType}');
      }
    } catch (e) {
      if (_audioDataCallCount <= 5) {
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

      // Add timeout to prevent hanging
      final result = await responsePort.first.timeout(
        const Duration(milliseconds: 200),
        onTimeout: () => null,
      );

      if (result is PitchDetectorResult) {
        _handleResult(result);
      }
    } catch (e) {
      print('❌ Error sending to isolate: $e');
    } finally {
      responsePort.close();
    }
  }

  void _handleResult(PitchDetectorResult result) {
    final pitch = result.pitch;
    final prob = result.probability;
    final pitched = result.pitched;

    // Always log first 20 results to see what's happening
    if (_audioDataCallCount <= 20) {
      print(
        '🎵 Result #$_audioDataCallCount: pitched=$pitched, prob=${prob?.toStringAsFixed(2)}, pitch=${pitch?.toStringAsFixed(2)} Hz',
      );
    }

    if (pitched == true &&
        prob != null &&
        prob > detectionThreshold &&
        pitch != null &&
        pitch > 0 &&
        pitch >= 70 &&
        pitch <= 400) {
      // Filter to guitar frequency range

      // Add to smoothing window
      _recentPitches.add(pitch);
      if (_recentPitches.length > _smoothingWindowSize) {
        _recentPitches.removeAt(0);
      }

      // Calculate median for stability (better than average for outliers)
      if (_recentPitches.length >= 3) {
        final sorted = List<double>.from(_recentPitches)..sort();
        final median = sorted[sorted.length ~/ 2];

        _validPitchCount++;
        if (_validPitchCount % 10 == 0) {
          print(
            '✅ Valid pitch detected: ${median.toStringAsFixed(2)} Hz (prob: ${prob.toStringAsFixed(2)})',
          );
        }
        onFrequencyDetected(median);
      }
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    print('🛑 Stopping audio capture...');
    _isRunning = false;
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
}

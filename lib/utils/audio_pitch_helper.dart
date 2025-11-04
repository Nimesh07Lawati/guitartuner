import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitch_detector_dart/pitch_detector_result.dart';

/// --- Isolate entry function ---
void pitchDetectionIsolate(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  late PitchDetector detector;

  receivePort.listen((message) async {
    try {
      final samples = message[0] as List<double>;
      final sampleRate = message[1] as int;
      final bufferSize = message[2] as int;
      final SendPort replyPort = message[3] as SendPort;

      detector = PitchDetector(
        audioSampleRate: sampleRate.toDouble(),
        bufferSize: bufferSize,
      );

      final result = await detector.getPitchFromFloatBuffer(samples);
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

  // --- Smoothing & Stability ---
  double _smoothedPitch = 0.0;
  double _lastStablePitch = 0.0;
  int _stabilityCounter = 0;
  final double _smoothingFactor = 0.25; // Lower = smoother, higher = quicker
  final int _requiredStableFrames = 4;

  // --- Isolate communication ports ---
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  final _receivePort = ReceivePort();

  AudioPitchHelper({
    required this.onFrequencyDetected,
    this.sampleRate = 44100,
    this.bufferSize = 4096, // ✅ more stable for low notes
    this.detectionThreshold = 0.7,
  }) {
    print('🎵 AudioPitchHelper initialized:');
    print('   • Sample Rate: $sampleRate Hz');
    print('   • Buffer Size: $bufferSize');
    print('   • Threshold: $detectionThreshold');
  }

  bool get isRunning => _isRunning;

  Future<void> _initIsolate() async {
    if (_isolateSendPort != null) return;
    print('🚀 Starting pitch detection isolate...');
    final readyPort = ReceivePort();
    _isolate = await Isolate.spawn(pitchDetectionIsolate, readyPort.sendPort);
    _isolateSendPort = await readyPort.first as SendPort;
    print('✅ Pitch detection isolate ready');
  }

  Future<void> start() async {
    if (_isRunning) {
      print('⚠️ Already running');
      return;
    }

    await _initIsolate();

    _audioDataCallCount = 0;
    _validPitchCount = 0;

    try {
      if (!_isInitialized) {
        print('🔧 Initializing FlutterAudioCapture...');
        await _audioCapture.init();
        _isInitialized = true;
      }

      print('🎤 Starting audio capture...');
      await _audioCapture.start(
        _onAudioData,
        _onError,
        sampleRate: sampleRate,
        bufferSize: bufferSize,
      );
      _isRunning = true;
      print('✅ Audio capture started');
    } catch (e) {
      print('❌ Start error: $e');
      _isRunning = false;
      _isInitialized = false;
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    try {
      print('🛑 Stopping audio capture...');
      await _audioCapture.stop();
      print('✅ Audio stopped');
      print(
        '📊 Stats: $_audioDataCallCount calls, $_validPitchCount valid pitches',
      );
    } catch (e) {
      print('❌ Stop error: $e');
    } finally {
      _isRunning = false;
    }
  }

  void _onError(dynamic error) {
    print('❌ Audio capture error: $error');
  }

  void _onAudioData(dynamic obj) {
    if (!_isRunning) return;
    _audioDataCallCount++;

    if (obj is Float32List) {
      final samples = obj.map((v) => v.toDouble()).toList();
      _sendToIsolate(samples);
    }
  }

  Future<void> _sendToIsolate(List<double> samples) async {
    if (_isolateSendPort == null) return;
    final responsePort = ReceivePort();
    _isolateSendPort!.send([
      samples,
      sampleRate,
      bufferSize,
      responsePort.sendPort,
    ]);
    final result = await responsePort.first;
    if (result is PitchDetectorResult) _handleResult(result);
  }

  void _handleResult(PitchDetectorResult result) {
    final pitch = result.pitch;
    final prob = result.probability;
    final pitched = result.pitched;

    if (pitched == true &&
        prob != null &&
        prob > detectionThreshold &&
        pitch != null &&
        pitch > 0) {
      _validPitchCount++;

      // --- Smooth pitch ---
      if (_smoothedPitch == 0.0) {
        _smoothedPitch = pitch;
      } else {
        _smoothedPitch =
            _smoothingFactor * pitch + (1 - _smoothingFactor) * _smoothedPitch;
      }

      // --- Stability check ---
      if ((_lastStablePitch - _smoothedPitch).abs() < 2) {
        _stabilityCounter++;
      } else {
        _stabilityCounter = 0;
      }

      if (_stabilityCounter >= _requiredStableFrames) {
        onFrequencyDetected(_smoothedPitch);
        _stabilityCounter = 0;
      }

      _lastStablePitch = _smoothedPitch;
    }
  }

  void dispose() {
    if (_isolate != null) {
      print('🧹 Disposing pitch detection isolate...');
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
      _isolateSendPort = null;
    }
  }

  /// Returns cent difference between detected and target frequency.
  static double centsDifference(double detected, double target) {
    if (detected <= 0 || target <= 0) return 0;
    return 1200 * (log(detected / target) / ln2);
  }

  /// Snap a frequency to the closest guitar note (EADGBE).
  static const _noteFrequencies = {
    'E2': 82.41,
    'A2': 110.00,
    'D3': 146.83,
    'G3': 196.00,
    'B3': 246.94,
    'E4': 329.63,
  };

  static String nearestNoteName(double freq) {
    String nearest = '';
    double minDiff = double.infinity;
    _noteFrequencies.forEach((note, f) {
      final diff = (freq - f).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = note;
      }
    });
    return nearest;
  }
}

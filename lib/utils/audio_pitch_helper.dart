import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitch_detector_dart/pitch_detector_result.dart';

// --- Isolate entry function (from Step 1) ---
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

  // --- Isolate communication ports ---
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  final _receivePort = ReceivePort();

  AudioPitchHelper({
    required this.onFrequencyDetected,
    this.sampleRate = 44100,
    this.bufferSize = 2048,
    this.detectionThreshold = 0.8,
  }) {
    print('🎵 AudioPitchHelper created with:');
    print('   - Sample Rate: $sampleRate Hz');
    print('   - Buffer Size: $bufferSize');
    print('   - Detection Threshold: $detectionThreshold');
  }

  bool get isRunning => _isRunning;

  Future<void> _initIsolate() async {
    if (_isolateSendPort != null) return; // already initialized

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

    try {
      if (!_isInitialized) {
        print('🔧 Initializing FlutterAudioCapture...');
        await _audioCapture.init();
        _isInitialized = true;
        print('✅ FlutterAudioCapture initialized');
      }

      print('🎤 Starting audio capture...');
      await _audioCapture.start(
        _onAudioData,
        _onError,
        sampleRate: sampleRate,
        bufferSize: bufferSize,
      );
      _isRunning = true;
      print('✅ Audio capture started successfully');
    } catch (e) {
      print('❌ AudioPitchHelper start error: $e');
      _isRunning = false;
      _isInitialized = false;
    }
  }

  Future<void> stop() async {
    if (!_isRunning) {
      print('⚠️ AudioPitchHelper not running');
      return;
    }
    try {
      print('🛑 Stopping audio capture...');
      await _audioCapture.stop();
      print('✅ Audio capture stopped');
      print(
        '📊 Stats: $_audioDataCallCount audio callbacks, $_validPitchCount valid pitches',
      );
    } catch (e) {
      print('❌ AudioPitchHelper stop error: $e');
    } finally {
      _isRunning = false;
    }
  }

  void _onError(dynamic error) {
    print('❌ AudioPitchHelper error: $error');
  }

  void _onAudioData(dynamic obj) {
    if (!_isRunning) return;
    _audioDataCallCount++;

    if (obj is Float32List) {
      if (_audioDataCallCount == 1) {
        print('📊 Received Float32List with ${obj.length} samples');
      }

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
    if (result is PitchDetectorResult) {
      _handleResult(result);
    }
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
      print(
        '✅ Valid pitch detected: ${pitch.toStringAsFixed(2)} Hz (prob: ${prob.toStringAsFixed(2)})',
      );
      onFrequencyDetected(pitch);
    }
  }

  void dispose() {
    if (_isolate != null) {
      print('🧹 Killing pitch detection isolate...');
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
}

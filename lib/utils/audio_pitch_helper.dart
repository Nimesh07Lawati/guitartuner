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
  late PitchDetector _pitchDetector;
  final FrequencyCallback onFrequencyDetected;

  final int sampleRate;
  final int bufferSize;
  final double detectionThreshold;

  bool _isRunning = false;
  bool _isInitialized = false;
  int _audioDataCallCount = 0;
  int _validPitchCount = 0;

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
    print('🎵 AudioPitchHelper created with:');
    print('   - Sample Rate: $sampleRate Hz');
    print('   - Buffer Size: $bufferSize');
    print('   - Detection Threshold: $detectionThreshold');
  }

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) {
      print('⚠️ AudioPitchHelper already running');
      return;
    }

    _audioDataCallCount = 0;
    _validPitchCount = 0;

    try {
      // Initialize if not already
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
    if (_audioDataCallCount % 50 == 0) {
      print('📡 Audio data callback #$_audioDataCallCount');
    }

    // Process asynchronously but don't wait
    _processAudioData(obj);
  }

  Future<void> _processAudioData(dynamic obj) async {
    try {
      if (obj is Float32List) {
        if (_audioDataCallCount == 1) {
          print('📊 Received Float32List with ${obj.length} samples');
        }
        // Convert to List<double> for pitch detector
        final samples = obj.map((v) => v.toDouble()).toList();
        final result = await _pitchDetector.getPitchFromFloatBuffer(samples);
        _handleResult(result);
      } else if (obj is Uint8List) {
        if (_audioDataCallCount == 1) {
          print('📊 Received Uint8List with ${obj.length} samples');
        }
        // Pass directly as Uint8List
        final result = await _pitchDetector.getPitchFromIntBuffer(obj);
        _handleResult(result);
      } else if (obj is List) {
        if (_audioDataCallCount == 1) {
          print('📊 Received List with ${obj.length} samples');
        }
        final samples = obj.map((e) => (e as num).toDouble()).toList();
        final result = await _pitchDetector.getPitchFromFloatBuffer(samples);
        _handleResult(result);
      } else {
        print('⚠️ Unknown audio data type: ${obj.runtimeType}');
      }
    } catch (e) {
      if (_audioDataCallCount <= 5) {
        print('❌ AudioPitchHelper process error: $e');
      }
    }
  }

  void _handleResult(PitchDetectorResult? result) {
    if (result == null) {
      if (_audioDataCallCount % 100 == 0) {
        print('⚠️ Pitch detection returned null');
      }
      return;
    }

    final double? pitch = result.pitch;
    final double? probability = result.probability;
    final bool? pitched = result.pitched;

    if (_audioDataCallCount <= 5 ||
        (pitched == true &&
            probability != null &&
            probability > detectionThreshold)) {
      print(
        '🎯 Pitch result: pitch=$pitch Hz, probability=$probability, pitched=$pitched',
      );
    }

    if (pitched == true &&
        probability != null &&
        probability > detectionThreshold &&
        pitch != null &&
        pitch > 0) {
      _validPitchCount++;
      print(
        '✅ Valid pitch detected! #$_validPitchCount: $pitch Hz (prob: $probability)',
      );
      onFrequencyDetected(pitch);
    } else if (_audioDataCallCount <= 5) {
      print(
        '❌ Invalid pitch: pitched=$pitched, prob=$probability (threshold=$detectionThreshold), pitch=$pitch',
      );
    }
  }

  /// Returns cent difference between detected and target frequency.
  static double centsDifference(double detected, double target) {
    if (detected <= 0 || target <= 0) return 0;
    return 1200 * (log(detected / target) / ln2);
  }
}

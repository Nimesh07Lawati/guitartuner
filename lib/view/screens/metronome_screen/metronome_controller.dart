import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guitartuner/utils/audio_service.dart';

class MetronomeController extends ChangeNotifier {
  int bpm = 120;
  int timeSignature = 4;
  int currentBeat = 0;
  bool isPlaying = false;

  final MetronomeAudioService _audioService = MetronomeAudioService();

  final Stopwatch _clock = Stopwatch();
  Timer? _schedulerTimer;

  Duration _beatInterval = Duration.zero;
  int _scheduledBeat = 0;

  // How often the scheduler polls the clock. `audioplayers` has no
  // sample-accurate "play at future time" API, so playback always starts
  // the instant `resume()` is called — there's no benefit to scheduling
  // beats ahead of time, only cost (a fixed early-trigger offset). Instead
  // we poll tightly and fire a beat exactly when it's due.
  static const Duration _tickInterval = Duration(milliseconds: 5);

  MetronomeController() {
    _recalculateInterval();
    _initializeAudio();
  }

  bool get isAudioLoaded => _audioService.isLoaded;
  Duration get beatInterval => _beatInterval;

  Future<void> _initializeAudio() async {
    await _audioService.initialize();
    notifyListeners();
  }

  void _recalculateInterval() {
    _beatInterval = Duration(microseconds: (60000000 / bpm).round());
  }

  void _scheduler() {
    final now = _clock.elapsed;

    // If a stall (GC pause, jank, etc.) put us more than a beat behind,
    // resync silently instead of firing a rapid burst of "catch-up" clicks.
    if (now - _nextBeatTime > _beatInterval) {
      final missedBeats =
          (now - _nextBeatTime).inMicroseconds ~/ _beatInterval.inMicroseconds;
      _nextBeatTime += _beatInterval * missedBeats;
      _scheduledBeat += missedBeats;
    }

    while (_nextBeatTime <= now) {
      _playScheduledBeat();
      _nextBeatTime += _beatInterval;
      _scheduledBeat++;
    }
  }

  Duration _nextBeatTime = Duration.zero;

  void _playScheduledBeat() {
    final isFirstBeat = _scheduledBeat % timeSignature == 0;
    currentBeat = (_scheduledBeat % timeSignature) + 1;

    if (isFirstBeat) {
      _audioService.playFirstBeat();
    } else {
      _audioService.playFollowUpBeat();
    }

    notifyListeners();
  }

  void start() {
    if (!isAudioLoaded || isPlaying) return;

    isPlaying = true;
    currentBeat = 0;
    _scheduledBeat = 0;

    _clock.reset();
    _clock.start();

    _nextBeatTime = Duration.zero;

    // Scheduler runs frequently but lightly
    _schedulerTimer = Timer.periodic(_tickInterval, (_) {
      _scheduler();
    });

    notifyListeners();
  }

  void stop() {
    if (!isPlaying) return;

    isPlaying = false;

    _schedulerTimer?.cancel();
    _schedulerTimer = null;

    _clock.stop();
    _clock.reset();

    currentBeat = 0;

    _audioService.stopAll();

    notifyListeners();
  }

  void incrementBpm() {
    bpm = (bpm + 1).clamp(40, 240);
    _recalculateInterval();
    notifyListeners();
  }

  void decrementBpm() {
    bpm = (bpm - 1).clamp(40, 240);
    _recalculateInterval();
    notifyListeners();
  }

  void setTimeSignature(int value) {
    if (value > 0 && value <= 16) {
      timeSignature = value;
      notifyListeners();
    }
  }

  void disposeController() {
    _schedulerTimer?.cancel();
    _audioService.dispose();
  }
}

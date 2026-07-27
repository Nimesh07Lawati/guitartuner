import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MetronomeController extends ChangeNotifier {
  int bpm = 120;
  int timeSignature = 4;
  int currentBeat = 0;
  bool isPlaying = false;

  // Two separate pools: one for the accented first beat, one for the
  // regular follow-up beats. Each pool is pre-loaded with its own asset
  // so there's no source-swapping latency at playback time.
  final List<AudioPlayer> _firstBeatPool = [];
  final List<AudioPlayer> _followUpBeatPool = [];
  int _firstBeatPoolIndex = 0;
  int _followUpPoolIndex = 0;
  static const int _poolSize = 6;

  final Stopwatch _clock = Stopwatch();
  Timer? _schedulerTimer;

  Duration _beatInterval = Duration.zero;
  int _scheduledBeat = 0;
  bool _isAudioLoaded = false;

  // Lookahead scheduling window
  static const Duration _scheduleAheadTime = Duration(milliseconds: 50);

  MetronomeController() {
    _recalculateInterval();
    _initializePlayerPools();
  }

  bool get isAudioLoaded => _isAudioLoaded;

  Future<void> _initializePlayerPools() async {
    try {
      for (int i = 0; i < _poolSize; i++) {
        final firstBeatPlayer = AudioPlayer();
        await firstBeatPlayer.setPlayerMode(PlayerMode.lowLatency);
        await firstBeatPlayer.setReleaseMode(ReleaseMode.stop);
        await firstBeatPlayer.setSource(AssetSource('audio/first_beat.wav'));
        await firstBeatPlayer.setVolume(1.0);
        _firstBeatPool.add(firstBeatPlayer);

        final followUpPlayer = AudioPlayer();
        await followUpPlayer.setPlayerMode(PlayerMode.lowLatency);
        await followUpPlayer.setReleaseMode(ReleaseMode.stop);
        await followUpPlayer.setSource(AssetSource('audio/follow_up_beat.wav'));
        await followUpPlayer.setVolume(1.0);
        _followUpBeatPool.add(followUpPlayer);
      }

      _isAudioLoaded = true;
      notifyListeners();
    } catch (_) {
      _isAudioLoaded = false;
      notifyListeners();
    }
  }

  void _recalculateInterval() {
    _beatInterval = Duration(microseconds: (60000000 / bpm).round());
  }

  // 🔥 STUDIO-STYLE SCHEDULER
  void _scheduler() {
    final now = _clock.elapsed;

    while (_nextBeatTime <= now + _scheduleAheadTime) {
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
      final player = _firstBeatPool[_firstBeatPoolIndex];
      _firstBeatPoolIndex = (_firstBeatPoolIndex + 1) % _poolSize;
      player.stop();
      player.resume();
    } else {
      final player = _followUpBeatPool[_followUpPoolIndex];
      _followUpPoolIndex = (_followUpPoolIndex + 1) % _poolSize;
      player.stop();
      player.resume();
    }

    notifyListeners();
  }

  void start() {
    if (!_isAudioLoaded || isPlaying) return;

    isPlaying = true;
    currentBeat = 0;
    _scheduledBeat = 0;

    _clock.reset();
    _clock.start();

    _nextBeatTime = Duration.zero;

    // Scheduler runs frequently but lightly
    _schedulerTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
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

    for (var player in _firstBeatPool) {
      player.stop();
    }
    for (var player in _followUpBeatPool) {
      player.stop();
    }

    notifyListeners();
  }

  void incrementBpm() {
    bpm = (bpm + 5).clamp(40, 240);
    _recalculateInterval();
    notifyListeners();
  }

  void decrementBpm() {
    bpm = (bpm - 5).clamp(40, 240);
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
    for (var player in _firstBeatPool) {
      player.dispose();
    }
    for (var player in _followUpBeatPool) {
      player.dispose();
    }
  }
}

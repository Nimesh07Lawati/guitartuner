import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MetronomeController extends ChangeNotifier {
  int bpm = 120;
  int timeSignature = 4;
  int currentBeat = 0;
  bool isPlaying = false;

  final List<AudioPlayer> _playerPool = [];
  int _currentPlayerIndex = 0;
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
    _initializePlayerPool();
  }

  bool get isAudioLoaded => _isAudioLoaded;

  Future<void> _initializePlayerPool() async {
    try {
      for (int i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();

        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource('audio/tick_wav.wav'));

        await player.setVolume(1.0);

        _playerPool.add(player);
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
    currentBeat = (_scheduledBeat % timeSignature) + 1;

    final player = _playerPool[_currentPlayerIndex];
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;

    player.stop();
    player.resume();

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

    for (var player in _playerPool) {
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
    for (var player in _playerPool) {
      player.dispose();
    }
  }
}

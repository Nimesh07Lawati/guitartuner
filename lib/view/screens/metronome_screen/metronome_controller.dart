import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/scheduler.dart';

class MetronomeController extends ChangeNotifier {
  int bpm = 120;
  int timeSignature = 4;
  int currentBeat = 0;
  bool isPlaying = false;

  final AudioPlayer _player = AudioPlayer();
  late Ticker _ticker;

  Duration _beatInterval = Duration.zero;
  Duration _totalElapsed = Duration.zero;
  int _nextBeatNumber = 0; // Which beat should fire next (0, 1, 2, ...)

  MetronomeController(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick);
    _loadAudio();
    _recalculateInterval();
  }

  Future<void> _loadAudio() async {
    await _player.setSource(AssetSource('audio/tick.mp3'));
    // CRITICAL: Use loop mode to keep audio engine ready
    await _player.setReleaseMode(ReleaseMode.loop);
    // Pre-load by seeking to start
    await _player.seek(Duration.zero);
  }

  void _recalculateInterval() {
    _beatInterval = Duration(microseconds: (60000000 / bpm).round());
  }

  void _onTick(Duration elapsed) {
    if (!isPlaying) return;

    _totalElapsed = elapsed; // Absolute time from start

    // Calculate which beat we SHOULD be on based on absolute time
    final expectedBeatTime = _beatInterval * _nextBeatNumber;

    if (_totalElapsed >= expectedBeatTime) {
      // Fire the beat
      _triggerBeat();
      _nextBeatNumber++; // Move to next beat
    }
  }

  void _triggerBeat() {
    currentBeat = (currentBeat % timeSignature) + 1;

    // CRITICAL: Restart from beginning for instant playback
    _player.seek(Duration.zero);
    _player.resume();

    notifyListeners();
  }

  void start() {
    if (isPlaying) return;
    isPlaying = true;
    currentBeat = 0;
    _nextBeatNumber = 0;
    _totalElapsed = Duration.zero;
    _ticker.start();
    notifyListeners();
  }

  void stop() {
    isPlaying = false;
    currentBeat = 0;
    _nextBeatNumber = 0;
    _ticker.stop();
    _player.pause();
    notifyListeners();
  }

  void incrementBpm() {
    if (bpm < 240) bpm += 5;
    _recalculateInterval();
    notifyListeners();
  }

  void decrementBpm() {
    if (bpm > 40) bpm -= 5;
    _recalculateInterval();
    notifyListeners();
  }

  void setTimeSignature(int value) {
    timeSignature = value;
    currentBeat = 0;
    notifyListeners();
  }

  void disposeController() {
    _ticker.dispose();
    _player.dispose();
  }
}

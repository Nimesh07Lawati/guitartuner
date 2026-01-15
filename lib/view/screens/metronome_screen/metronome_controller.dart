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
  Duration _elapsed = Duration.zero;

  MetronomeController(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick);
    _loadAudio();
    _recalculateInterval();
  }

  Future<void> _loadAudio() async {
    await _player.setSource(AssetSource('audio/tick.mp3'));
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  void _recalculateInterval() {
    _beatInterval = Duration(microseconds: (60000000 / bpm).round());
  }

  void _onTick(Duration delta) {
    if (!isPlaying) return;

    _elapsed += delta;

    if (_elapsed >= _beatInterval) {
      _elapsed -= _beatInterval;
      _triggerBeat();
    }
  }

  void _triggerBeat() {
    currentBeat = (currentBeat % timeSignature) + 1;
    _player.resume(); // already preloaded → minimal latency
    notifyListeners();
  }

  void start() {
    if (isPlaying) return;
    isPlaying = true;
    currentBeat = 0;
    _elapsed = Duration.zero;
    _ticker.start();
    notifyListeners();
  }

  void stop() {
    isPlaying = false;
    currentBeat = 0;
    _ticker.stop();
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

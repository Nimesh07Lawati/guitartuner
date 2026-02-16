import 'package:flutter/material.dart';
import 'dart:async';

class MetronomeController extends ChangeNotifier {
  Timer? _timer;
  int _bpm = 120;
  int _timeSignature = 4;
  int _currentBeat = 0;
  bool _isPlaying = false;
  final TickerProvider vsync;

  MetronomeController(this.vsync);

  int get bpm => _bpm;
  int get timeSignature => _timeSignature;
  int get currentBeat => _currentBeat;
  bool get isPlaying => _isPlaying;

  void incrementBpm() {
    if (_bpm < 240) {
      _bpm += 1;
      if (_isPlaying) {
        restart();
      }
      notifyListeners();
    }
  }

  void decrementBpm() {
    if (_bpm > 40) {
      _bpm -= 1;
      if (_isPlaying) {
        restart();
      }
      notifyListeners();
    }
  }

  void updateTimeSignature(int newSignature) {
    _timeSignature = newSignature;
    _currentBeat = 0;
    if (_isPlaying) {
      restart();
    }
    notifyListeners();
  }

  void start() {
    _isPlaying = true;
    _currentBeat = 1;
    startTimer();
    notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    _timer?.cancel();
    _currentBeat = 0;
    notifyListeners();
  }

  void restart() {
    stop();
    start();
  }

  void startTimer() {
    _timer?.cancel();
    final interval = 60000 / _bpm; // milliseconds per beat

    _timer = Timer.periodic(Duration(milliseconds: interval.round()), (timer) {
      _currentBeat = (_currentBeat % _timeSignature) + 1;
      notifyListeners();
    });
  }

  void disposeController() {
    _timer?.cancel();
    dispose();
  }
}

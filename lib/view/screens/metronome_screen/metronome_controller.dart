import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/scheduler.dart';

class MetronomeController extends ChangeNotifier {
  int bpm = 120;
  int timeSignature = 4;
  int currentBeat = 0;
  bool isPlaying = false;

  final List<AudioPlayer> _playerPool = [];
  int _currentPlayerIndex = 0;
  static const int _poolSize = 4;

  late Ticker _ticker;
  Duration _beatInterval = Duration.zero;
  Duration _startTime = Duration.zero;
  int _nextBeatNumber = 0;
  bool _isAudioLoaded = false;

  MetronomeController(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick);
    _recalculateInterval();
    _initializePlayerPool();
  }

  bool get isAudioLoaded => _isAudioLoaded;

  Future<void> _initializePlayerPool() async {
    try {
      debugPrint('🔄 Initializing audio player pool...');

      for (int i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();

        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource('audio/tick_wav.wav'));

        await player.setAudioContext(
          AudioContext(
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: [
                AVAudioSessionOptions.mixWithOthers,
                AVAudioSessionOptions.defaultToSpeaker,
              ],
            ),
            android: AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: false,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.none,
            ),
          ),
        );

        await player.setVolume(1.0);

        _playerPool.add(player);
        debugPrint('✅ Player ${i + 1}/$_poolSize initialized');
      }

      _isAudioLoaded = true;
      debugPrint('✅ Audio pool ready');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing audio pool: $e');
      _isAudioLoaded = false;
      notifyListeners();
    }
  }

  void _recalculateInterval() {
    _beatInterval = Duration(microseconds: (60000000 / bpm).round());
  }

  // 🔥 FIXED TIMING ENGINE
  void _onTick(Duration elapsed) {
    if (!isPlaying || !_isAudioLoaded) return;

    if (_startTime == Duration.zero) {
      _startTime = elapsed;
    }

    final timeSinceStart = elapsed - _startTime;

    // Calculate how many beats SHOULD have occurred
    final totalBeatsElapsed =
        (timeSinceStart.inMicroseconds / _beatInterval.inMicroseconds).floor();

    // Catch up if frames were delayed
    while (_nextBeatNumber <= totalBeatsElapsed) {
      _triggerBeat();
      _nextBeatNumber++;
    }
  }

  void _triggerBeat() {
    currentBeat = (_nextBeatNumber % timeSignature) + 1;

    final player = _playerPool[_currentPlayerIndex];
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;

    // 🔥 More stable than seek()
    player.stop();
    player.resume();

    notifyListeners();
  }

  void start() {
    if (!_isAudioLoaded) {
      debugPrint('❌ Cannot start - audio not loaded');
      return;
    }

    if (isPlaying) return;

    debugPrint('▶️ Starting metronome at $bpm BPM');

    isPlaying = true;
    currentBeat = 0;
    _nextBeatNumber = 0;
    _startTime = Duration.zero;

    _ticker.start();

    notifyListeners();
  }

  void stop() {
    if (!isPlaying) return;

    debugPrint('⏹️ Stopping metronome');

    isPlaying = false;
    currentBeat = 0;
    _nextBeatNumber = 0;
    _startTime = Duration.zero;

    _ticker.stop();

    for (var player in _playerPool) {
      player.stop();
    }

    notifyListeners();
  }

  void incrementBpm() {
    final wasPlaying = isPlaying;
    if (wasPlaying) stop();

    if (bpm < 240) {
      bpm += 5;
      _recalculateInterval();
      notifyListeners();
    }

    if (wasPlaying) {
      Future.delayed(const Duration(milliseconds: 100), () => start());
    }
  }

  void decrementBpm() {
    final wasPlaying = isPlaying;
    if (wasPlaying) stop();

    if (bpm > 40) {
      bpm -= 5;
      _recalculateInterval();
      notifyListeners();
    }

    if (wasPlaying) {
      Future.delayed(const Duration(milliseconds: 100), () => start());
    }
  }

  void setTimeSignature(int value) {
    if (value > 0 && value <= 16) {
      final wasPlaying = isPlaying;
      if (wasPlaying) stop();

      timeSignature = value;
      currentBeat = 0;

      notifyListeners();

      if (wasPlaying) {
        Future.delayed(const Duration(milliseconds: 100), () => start());
      }
    }
  }

  void disposeController() {
    _ticker.dispose();
    for (var player in _playerPool) {
      player.dispose();
    }
  }
}

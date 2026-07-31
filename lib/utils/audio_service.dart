import 'package:audioplayers/audioplayers.dart';

/// Handles loading and playback of metronome click sounds.
///
/// Uses a SINGLE click sample for both the accent and regular beats.
/// The accent (beat 1) is differentiated by playing it louder and at a
/// higher playback rate (which raises pitch), same trick real hardware
/// and software metronomes use — avoids the "out of sync" feel that
/// comes from mixing two unrelated audio files with different attack
/// transients/lengths.
class MetronomeAudioService {
  static const int poolSize = 6;

  // Accent (beat 1) tuning — louder and higher-pitched.
  static const double _accentVolume = 1.0;
  static const double _accentPlaybackRate = 1.35;

  // Regular follow-up beat tuning — quieter, natural pitch.
  static const double _regularVolume = 0.55;
  static const double _regularPlaybackRate = 1.0;

  final List<AudioPlayer> _accentPool = [];
  final List<AudioPlayer> _regularPool = [];
  int _accentPoolIndex = 0;
  int _regularPoolIndex = 0;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Configures the global audio context and loads both player pools.
  /// Call once before attempting playback.
  Future<void> initialize() async {
    try {
      // Metronome playback shouldn't request or react to audio focus —
      // focus churn across pooled players was cutting sound short.
      await AudioPlayer.global.setAudioContext(
        const AudioContext(
          android: AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
          ),
        ),
      );

      for (int i = 0; i < poolSize; i++) {
        final accentPlayer = AudioPlayer();
        await accentPlayer.setPlayerMode(PlayerMode.lowLatency);
        await accentPlayer.setReleaseMode(ReleaseMode.stop);
        await accentPlayer.setSource(AssetSource('audio/click.wav'));
        await accentPlayer.setVolume(_accentVolume);
        await accentPlayer.setPlaybackRate(_accentPlaybackRate);
        _accentPool.add(accentPlayer);

        final regularPlayer = AudioPlayer();
        await regularPlayer.setPlayerMode(PlayerMode.lowLatency);
        await regularPlayer.setReleaseMode(ReleaseMode.stop);
        await regularPlayer.setSource(AssetSource('audio/click.wav'));
        await regularPlayer.setVolume(_regularVolume);
        await regularPlayer.setPlaybackRate(_regularPlaybackRate);
        _regularPool.add(regularPlayer);
      }

      _isLoaded = true;
    } catch (_) {
      _isLoaded = false;
    }
  }

  /// Plays the accented downbeat — same sample, louder + higher pitch.
  void playFirstBeat() {
    if (!_isLoaded) return;
    final player = _accentPool[_accentPoolIndex];
    _accentPoolIndex = (_accentPoolIndex + 1) % poolSize;
    player.seek(Duration.zero);
    player.resume();
  }

  void playFollowUpBeat() {
    if (!_isLoaded) return;
    final player = _regularPool[_regularPoolIndex];
    _regularPoolIndex = (_regularPoolIndex + 1) % poolSize;
    player.seek(Duration.zero);
    player.resume();
  }

  /// Stops all currently playing/queued players in both pools.
  void stopAll() {
    for (var player in _accentPool) {
      player.stop();
    }
    for (var player in _regularPool) {
      player.stop();
    }
  }

  /// Releases all player resources. Call from the controller's dispose.
  void dispose() {
    for (var player in _accentPool) {
      player.dispose();
    }
    for (var player in _regularPool) {
      player.dispose();
    }
  }
}

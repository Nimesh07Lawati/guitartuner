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

  // Warm-up timings. SoundPool loads the sample asynchronously once
  // `setSource` returns, so give it a moment to finish before the muted
  // warm-up play, then let that play run briefly before stopping it.
  static const Duration _primeLoadDelay = Duration(milliseconds: 200);
  static const Duration _primePlayDelay = Duration(milliseconds: 200);

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
      //
      // usageType is deliberately `media`, not `assistanceSonification`:
      // Android maps ASSISTANCE_SONIFICATION to the legacy STREAM_SYSTEM
      // volume (the separate "system sounds" slider some OEMs expose,
      // e.g. Samsung/Xiaomi), which many users mute independently of
      // media volume. That silently killed metronome sound on those
      // devices while leaving it working everywhere else.
      await AudioPlayer.global.setAudioContext(
        const AudioContext(
          android: AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
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

      await _primePools();

      _isLoaded = true;
    } catch (_) {
      _isLoaded = false;
    }
  }

  /// Silently plays every pooled player once, so the native audio pipeline
  /// is already warmed up before the user taps Start.
  ///
  /// On Android, the first `resume()` on a fresh player carries extra
  /// startup latency (SoundPool/AudioTrack pipeline init) that later plays
  /// don't — and since playback round-robins across the whole pool, that
  /// "cold start" would otherwise recur across the first several beats
  /// after Start, not just the very first one.
  ///
  /// The warm-up runs at volume 0 so it's inaudible, which makes restoring
  /// the real volumes afterwards mandatory — hence the `finally`. Do NOT
  /// key the restore off `onPlayerComplete`: `PlayerMode.lowLatency` is
  /// backed by SoundPool on Android, which has no playback-completion
  /// callback at all, so that event never fires and the pool stays muted
  /// forever. `_isLoaded` is only set once this returns, so no real beat
  /// can be played while the pool is still muted.
  Future<void> _primePools() async {
    final players = [..._accentPool, ..._regularPool];
    try {
      await Future.wait(players.map((p) => p.setVolume(0)));
      await Future.delayed(_primeLoadDelay);
      await Future.wait(players.map((p) => p.resume()));
      await Future.delayed(_primePlayDelay);
      await Future.wait(players.map((p) => p.stop()));
    } catch (_) {
      // Warm-up is best-effort; failing it must never cost us playback.
    } finally {
      await _restoreVolumes();
    }
  }

  Future<void> _restoreVolumes() async {
    try {
      await Future.wait([
        for (final p in _accentPool) p.setVolume(_accentVolume),
        for (final p in _regularPool) p.setVolume(_regularVolume),
      ]);
    } catch (_) {
      // Ignore — nothing more we can do here.
    }
  }

  /// Retriggers a pooled player from the top of the sample.
  ///
  /// `stop()` before `resume()` is load-bearing — do NOT "optimise" it into
  /// a bare `resume()`, and do NOT go back to `seek(Duration.zero)`:
  ///
  /// * `resume()` alone is a no-op on a replay. It reaches
  ///   `WrappedPlayer.play()`, which is guarded by `if (!playing)`. Because
  ///   SoundPool never reports completion, `playing` is never cleared and
  ///   stays true forever after the first beat, so the guard rejects every
  ///   subsequent play.
  /// * `seek(Duration.zero)` took the SoundPool path of stopping the stream
  ///   and then calling `soundPool.resume()` on that same, now-freed stream
  ///   id. Reviving a stopped stream isn't something SoundPool guarantees:
  ///   it happened to work while slow tempos left the 32 stream slots idle,
  ///   but at high BPM the id got recycled into another player's beat before
  ///   the resume landed — which is why individual beats dropped out
  ///   intermittently, and only when the tempo was high.
  ///
  /// `stop()` instead runs pause → seek(0), which clears `playing` and nulls
  /// the stream id, so the following `resume()` passes the guard and starts
  /// a genuinely fresh stream. That also re-applies volume and rate at play
  /// time, since `SoundPoolPlayer.start()` passes them into `soundPool.play`.
  void _retrigger(AudioPlayer player) {
    player.stop();
    player.resume();
  }

  /// Plays the accented downbeat — same sample, louder + higher pitch.
  void playFirstBeat() {
    if (!_isLoaded) return;
    final player = _accentPool[_accentPoolIndex];
    _accentPoolIndex = (_accentPoolIndex + 1) % poolSize;
    _retrigger(player);
  }

  void playFollowUpBeat() {
    if (!_isLoaded) return;
    final player = _regularPool[_regularPoolIndex];
    _regularPoolIndex = (_regularPoolIndex + 1) % poolSize;
    _retrigger(player);
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

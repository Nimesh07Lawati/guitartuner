import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen>
    with SingleTickerProviderStateMixin {
  int _bpm = 120;
  bool _isPlaying = false;
  late AnimationController _animationController;
  late Animation<double> _swingAnimation;

  final List<int> _timeSignatures = [2, 3, 4, 6, 8];
  int _selectedTimeSignature = 4;
  int _currentBeat = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioLoaded = false;
  Timer? _metronomeTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _swingAnimation = Tween<double>(begin: -0.2, end: 0.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('audio/tick.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      setState(() => _isAudioLoaded = true);
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  void _playBeatSound() async {
    if (!_isAudioLoaded) return;
    try {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _startMetronome() {
    if (_isPlaying || !_isAudioLoaded) return;

    setState(() {
      _isPlaying = true;
      _currentBeat = 0;
    });

    final interval = Duration(milliseconds: (60000 / _bpm).round());

    // Play first beat instantly
    _triggerBeat();

    // Start periodic timer
    _metronomeTimer = Timer.periodic(interval, (timer) {
      _triggerBeat();
    });
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentBeat = 0;
    });
  }

  void _triggerBeat() {
    _playBeatSound();

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    setState(() {
      _currentBeat = (_currentBeat % _selectedTimeSignature) + 1;
    });
  }

  void _incrementBPM() {
    setState(() {
      if (_bpm < 240) _bpm += 5;
    });
    if (_isPlaying) {
      _stopMetronome();
      _startMetronome();
    }
  }

  void _decrementBPM() {
    setState(() {
      if (_bpm > 40) _bpm -= 5;
    });
    if (_isPlaying) {
      _stopMetronome();
      _startMetronome();
    }
  }

  Color _getBeatColor(int beatNumber) {
    if (!_isPlaying) return Colors.white.withOpacity(0.3);
    if (beatNumber == _currentBeat) {
      return beatNumber == 1 ? Colors.green : const Color(0xFFF27121);
    }
    return Colors.white.withOpacity(0.3);
  }

  @override
  void dispose() {
    _metronomeTimer?.cancel();
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: const Text(
          'Metronome',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8A2387), Color(0xFFF27121), Color(0xFFE94057)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(flex: 2, child: _buildBPMControls()),
            Expanded(flex: 3, child: _buildPendulumVisualizer()),
            SizedBox(height: 100, child: _buildTimeSignatureSelector()),
            SizedBox(height: 80, child: _buildControlButtons()),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // === UI Widgets ===

  Widget _buildBPMControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'BPM',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _decrementBPM,
                child: _roundButton(Icons.remove),
              ),
              const SizedBox(width: 20),
              Container(
                width: 110,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2387), Color(0xFFF27121)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '$_bpm',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _incrementBPM,
                child: _roundButton(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isAudioLoaded ? 'Audio Ready' : 'Loading Audio...',
            style: TextStyle(
              fontSize: 12,
              color: _isAudioLoaded ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(22.5),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildPendulumVisualizer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Beat indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_selectedTimeSignature, (index) {
              final beatNumber = index + 1;
              return Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: _getBeatColor(beatNumber),
                  shape: BoxShape.circle,
                  boxShadow: beatNumber == _currentBeat && _isPlaying
                      ? [
                          BoxShadow(
                            color: beatNumber == 1
                                ? Colors.green.withOpacity(0.6)
                                : const Color(0xFFF27121).withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$beatNumber',
                    style: TextStyle(
                      color: beatNumber == _currentBeat && _isPlaying
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          AnimatedBuilder(
            animation: _swingAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _swingAnimation.value,
                child: Container(
                  width: 4,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF8A2387),
                        Color(0xFFF27121),
                        Color(0xFFE94057),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 50,
            height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSignatureSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Time Signature',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _timeSignatures.map((signature) {
                final isSelected = signature == _selectedTimeSignature;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTimeSignature = signature;
                      _currentBeat = 0;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF8A2387),
                                Color(0xFFF27121),
                                Color(0xFFE94057),
                              ],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
                            ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$signature/4',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tap_and_play, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Tap Tempo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: _isPlaying ? _stopMetronome : _startMetronome,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: _isPlaying
                      ? const LinearGradient(
                          colors: [Color(0xFFE94057), Color(0xFF8A2387)],
                        )
                      : const LinearGradient(
                          colors: [
                            Color(0xFF8A2387),
                            Color(0xFFF27121),
                            Color(0xFFE94057),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isPlaying ? Icons.stop : Icons.play_arrow, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      _isPlaying ? 'Stop' : 'Start',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioLoaded = false;

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
      // Preload the audio file
      await _audioPlayer.setSource(AssetSource('audio/tick.mp3'));
      setState(() {
        _isAudioLoaded = true;
      });
    } catch (e) {
      print('Error loading audio: $e');
    }
  }

  void _playBeatSound() async {
    if (!_isAudioLoaded) return;

    try {
      // Create a new player instance for each beat to avoid latency
      final player = AudioPlayer();
      await player.setSource(AssetSource('audio/tick.mp3'));
      await player.resume();

      // Dispose the player after playing to avoid memory leaks
      player.onPlayerComplete.listen((event) {
        player.dispose();
      });
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _startMetronome() {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
      _currentBeat = 0;
    });

    _playBeat();
  }

  void _stopMetronome() {
    setState(() {
      _isPlaying = false;
      _currentBeat = 0;
    });
  }

  void _playBeat() {
    if (!_isPlaying) return;

    // Play sound
    _playBeatSound();

    // Animate the pendulum
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Update current beat with visual feedback
    setState(() {
      _currentBeat = (_currentBeat % _selectedTimeSignature) + 1;
    });

    // Schedule next beat
    final interval = Duration(milliseconds: (60000 / _bpm).round());
    Future.delayed(interval, _playBeat);
  }

  void _incrementBPM() {
    setState(() {
      if (_bpm < 240) _bpm += 5;
    });
  }

  void _decrementBPM() {
    setState(() {
      if (_bpm > 40) _bpm -= 5;
    });
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
              colors: [
                Color(0xFF8A2387), // Electric Purple
                Color(0xFFF27121), // Bright Orange
                Color(0xFFE94057), // Hot Pink
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // BPM Display and Controls - FIXED: Reduced flex and padding
            Expanded(flex: 2, child: _buildBPMControls()),

            // Pendulum Visualizer
            Expanded(flex: 3, child: _buildPendulumVisualizer()),

            // Time Signature Selector - FIXED: Reduced height and padding
            SizedBox(
              height: 100, // Fixed height instead of Expanded
              child: _buildTimeSignatureSelector(),
            ),

            // Control Buttons
            SizedBox(
              height: 80, // Fixed height instead of Expanded
              child: _buildControlButtons(),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildBPMControls() {
    return Container(
      margin: const EdgeInsets.all(16), // Reduced from 20
      padding: const EdgeInsets.all(16), // Reduced from 24
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'BPM',
            style: TextStyle(
              fontSize: 16, // Reduced from 18
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 12), // Reduced from 16
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrease BPM Button
              GestureDetector(
                onTap: _decrementBPM,
                child: Container(
                  width: 45, // Reduced from 50
                  height: 45, // Reduced from 50
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
                    ),
                    borderRadius: BorderRadius.circular(
                      22.5,
                    ), // Reduced from 25
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 20, // Reduced from 24
                  ),
                ),
              ),
              const SizedBox(width: 20), // Reduced from 24
              // BPM Display
              Container(
                width: 110, // Reduced from 120
                height: 70, // Reduced from 80
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2387), Color(0xFFF27121)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8A2387).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$_bpm',
                    style: const TextStyle(
                      fontSize: 32, // Reduced from 36
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20), // Reduced from 24
              // Increase BPM Button
              GestureDetector(
                onTap: _incrementBPM,
                child: Container(
                  width: 45, // Reduced from 50
                  height: 45, // Reduced from 50
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
                    ),
                    borderRadius: BorderRadius.circular(
                      22.5,
                    ), // Reduced from 25
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20, // Reduced from 24
                  ),
                ),
              ),
            ],
          ),
          // Audio status indicator
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

  Widget _buildPendulumVisualizer() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Reduced margins
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
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
                width: 35, // Reduced from 40
                height: 35, // Reduced from 40
                decoration: BoxDecoration(
                  color: _getBeatColor(beatNumber),
                  shape: BoxShape.circle,
                  boxShadow: beatNumber == _currentBeat && _isPlaying
                      ? [
                          BoxShadow(
                            color: beatNumber == 1
                                ? Colors.green.withOpacity(0.6)
                                : const Color(0xFFF27121).withOpacity(0.6),
                            blurRadius: 8, // Reduced from 10
                            spreadRadius: 1, // Reduced from 2
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
                      fontSize: 14, // Reduced from 16
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 30), // Reduced from 40
          // Pendulum
          AnimatedBuilder(
            animation: _swingAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _swingAnimation.value,
                child: Container(
                  width: 4,
                  height: 100, // Reduced from 120
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

          // Pendulum base
          Container(
            width: 50, // Reduced from 60
            height: 16, // Reduced from 20
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
              ),
              borderRadius: BorderRadius.circular(8), // Reduced from 10
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSignatureSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 2,
      ), // Reduced vertical margin further
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 12,
      ), // Reduced vertical padding
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Added this to minimize height
        children: [
          Text(
            'Time Signature',
            style: TextStyle(
              fontSize: 13, // Reduced from 14
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 6), // Reduced from 8
          SizedBox(
            height: 36, // Reduced from 40
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(_timeSignatures.length, (index) {
                final signature = _timeSignatures[index];
                final isSelected = signature == _selectedTimeSignature;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTimeSignature = signature;
                      _currentBeat = 0;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 5,
                    ), // Reduced from 6
                    width: 50, // Reduced from 55
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
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Reduced from 12
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8A2387).withOpacity(0.5),
                                blurRadius: 6, // Reduced from 8
                                offset: const Offset(0, 2), // Reduced from 3
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$signature/4',
                        style: TextStyle(
                          fontSize: 12, // Reduced from 14
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      margin: const EdgeInsets.all(16), // Reduced from 20
      child: Row(
        children: [
          // Tap Tempo Button
          Expanded(
            child: Container(
              height: 50, // Reduced from 60
              margin: const EdgeInsets.only(right: 8), // Reduced from 10
              child: ElevatedButton(
                onPressed: () {
                  // Tap tempo functionality would go here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Reduced from 15
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF8A2387).withOpacity(0.5),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
                    ),
                    borderRadius: BorderRadius.circular(12), // Reduced from 15
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tap_and_play, size: 18), // Reduced from 20
                      SizedBox(width: 6), // Reduced from 8
                      Text(
                        'Tap Tempo',
                        style: TextStyle(
                          fontSize: 12, // Reduced from 14
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Start/Stop Button
          Expanded(
            child: Container(
              height: 50, // Reduced from 60
              margin: const EdgeInsets.only(left: 8), // Reduced from 10
              child: ElevatedButton(
                onPressed: _isPlaying ? _stopMetronome : _startMetronome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Reduced from 15
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF8A2387).withOpacity(0.5),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _isPlaying
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFE94057), // Hot Pink for stop
                              Color(0xFF8A2387), // Electric Purple
                            ],
                          )
                        : const LinearGradient(
                            colors: [
                              Color(0xFF8A2387), // Electric Purple
                              Color(0xFFF27121), // Bright Orange
                              Color(0xFFE94057), // Hot Pink
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12), // Reduced from 15
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8A2387).withOpacity(0.4),
                        blurRadius: 8, // Reduced from 10
                        offset: const Offset(0, 3), // Reduced from 4
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isPlaying ? Icons.stop : Icons.play_arrow,
                        size: 20,
                      ), // Reduced from 24
                      const SizedBox(width: 6), // Reduced from 8
                      Text(
                        _isPlaying ? 'Stop' : 'Start',
                        style: const TextStyle(
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

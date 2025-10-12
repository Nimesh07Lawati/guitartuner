import 'dart:math';

import 'package:flutter/material.dart';

class CustomGuitarTuner extends StatefulWidget {
  const CustomGuitarTuner({super.key});

  @override
  State<CustomGuitarTuner> createState() => _CustomGuitarTunerState();
}

class _CustomGuitarTunerState extends State<CustomGuitarTuner> {
  final List<GuitarString> _guitarStrings = [
    GuitarString(name: 'E', frequency: 329.63),
    GuitarString(name: 'B', frequency: 246.94),
    GuitarString(name: 'G', frequency: 196.00),
    GuitarString(name: 'D', frequency: 146.83),
    GuitarString(name: 'A', frequency: 110.00),
    GuitarString(name: 'E', frequency: 82.41),
  ];

  int _selectedStringIndex = 0;
  double _currentCents = 0.0;
  bool _isTuning = false;

  // This would integrate with your audio processing logic
  void _startTuning() {
    setState(() {
      _isTuning = true;
    });
    // Start audio processing and frequency detection here
  }

  void _stopTuning() {
    setState(() {
      _isTuning = false;
    });
    // Stop audio processing here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          children: [
            // Frequency display card
            _buildFrequencyDisplay(),

            // Custom visual tuner
            Expanded(child: _buildCustomTunerDisplay()),

            // String selection
            _buildStringSelector(),

            // Tuning button
            _buildTuningButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyDisplay() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        children: [
          Text(
            'Target: ${_guitarStrings[_selectedStringIndex].name} (${_guitarStrings[_selectedStringIndex].frequency.toStringAsFixed(2)} Hz)',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Text(
            _isTuning
                ? '${_calculateCurrentFrequency().toStringAsFixed(2)} Hz'
                : '-- Hz',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTunerDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom tuner visualization
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.black.withOpacity(0.3),
            ),
            child: Stack(
              children: [
                // Background scale
                _buildTunerScale(),
                // Needle indicator
                _buildTunerNeedle(),
                // Center line
                Center(
                  child: Container(
                    height: double.infinity,
                    width: 2,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Tuning status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getTuningStatusColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getTuningStatusColor().withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              _getTuningStatus(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _getTuningStatusColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTunerScale() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE94057).withOpacity(0.6),
                  const Color(0xFFF27121).withOpacity(0.4),
                  Colors.green.withOpacity(0.6),
                  const Color(0xFFF27121).withOpacity(0.4),
                  const Color(0xFF8A2387).withOpacity(0.6),
                ],
                stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTunerNeedle() {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 100),
      alignment: Alignment(_currentCents / 50, 0),
      child: Container(
        width: 4,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStringSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
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
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(_guitarStrings.length, (index) {
          final isSelected = index == _selectedStringIndex;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedStringIndex = index;
              _currentCents = 0.0;
            }),
            child: Container(
              width: 60,
              height: 60,
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
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _guitarStrings[index].name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTuningButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isTuning ? _stopTuning : _startTuning,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: _isTuning
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
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_isTuning ? Icons.stop : Icons.music_note, size: 24),
              const SizedBox(width: 12),
              Text(
                _isTuning ? 'Stop Tuning' : 'Start Tuning',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  double _calculateCurrentFrequency() {
    return _guitarStrings[_selectedStringIndex].frequency *
        pow(2, _currentCents / 1200);
  }

  String _getTuningStatus() {
    if (!_isTuning) return 'Tap to Start Tuning';
    if (_currentCents.abs() < 5) return 'Perfect!';
    if (_currentCents < 0) return 'Too Low';
    return 'Too High';
  }

  Color _getTuningStatusColor() {
    if (!_isTuning) return Colors.grey;
    if (_currentCents.abs() < 5) return Colors.green;
    if (_currentCents.abs() < 15) return Colors.orange;
    return Colors.red;
  }
}

class GuitarString {
  final String name;
  final double frequency;

  GuitarString({required this.name, required this.frequency});
}

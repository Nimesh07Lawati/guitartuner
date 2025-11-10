import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../utils/audio_pitch_helper.dart';

class GuitarTunerScreen extends StatefulWidget {
  const GuitarTunerScreen({super.key});

  @override
  State<GuitarTunerScreen> createState() => _GuitarTunerScreenState();
}

class _GuitarTunerScreenState extends State<GuitarTunerScreen> {
  late AudioPitchHelper _audioHelper;

  final List<TuningMode> _tuningModes = [
    TuningMode(name: 'Standard', description: 'E-A-D-G-B-E'),
    TuningMode(name: 'Half Step Down', description: 'D#-G#-C#-F#-A#-D#'),
    TuningMode(name: 'Drop D', description: 'D-A-D-G-B-E'),
    TuningMode(name: 'Open G', description: 'D-G-D-G-B-D'),
  ];

  final List<GuitarString> _guitarStrings = [
    GuitarString(name: 'E', note: 'E', frequency: 82.41, stringNumber: 6),
    GuitarString(name: 'A', note: 'A', frequency: 110.00, stringNumber: 5),
    GuitarString(name: 'D', note: 'D', frequency: 146.83, stringNumber: 4),
    GuitarString(name: 'G', note: 'G', frequency: 196.00, stringNumber: 3),
    GuitarString(name: 'B', note: 'B', frequency: 246.94, stringNumber: 2),
    GuitarString(name: 'E', note: 'E', frequency: 329.63, stringNumber: 1),
  ];

  int _selectedStringIndex = 0;
  final int _selectedTuningModeIndex = 0;
  double _currentFrequency = 0.0;
  bool _isTuning = false;
  int? _autoDetectedStringIndex;

  @override
  void initState() {
    super.initState();
    _audioHelper = AudioPitchHelper(
      onFrequencyDetected: (freq) {
        setState(() {
          _currentFrequency = freq;
          // Auto-detect closest string
          _autoDetectString(freq);
        });
      },
      detectionThreshold: 0.7, // Increased for better accuracy
    );
  }

  @override
  void dispose() {
    _audioHelper.stop();
    _audioHelper.dispose();
    super.dispose();
  }

  // Auto-detect which string is being played
  void _autoDetectString(double frequency) {
    if (frequency <= 0) return;

    final frequencies = _guitarStrings.map((s) => s.frequency).toList();
    final closestFreq = AudioPitchHelper.findClosestFrequency(
      frequency,
      frequencies,
    );

    final index = _guitarStrings.indexWhere((s) => s.frequency == closestFreq);
    if (index != -1 && index != _autoDetectedStringIndex) {
      setState(() {
        _autoDetectedStringIndex = index;
      });
    }
  }

  // ------------------ Tuning Logic ------------------
  Future<void> _startTuning() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      await _audioHelper.start();
      setState(() => _isTuning = true);
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable microphone permission in settings.'),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied.')),
        );
      }
    }
  }

  Future<void> _stopTuning() async {
    await _audioHelper.stop();
    setState(() {
      _isTuning = false;
      _currentFrequency = 0.0;
      _autoDetectedStringIndex = null;
    });
  }

  double _getNeedleValue() {
    if (!_isTuning || _currentFrequency <= 0) return 0;

    // Use auto-detected string if available, otherwise use selected string
    final targetIndex = _autoDetectedStringIndex ?? _selectedStringIndex;
    final target = _guitarStrings[targetIndex].frequency;

    // Calculate cents difference
    final cents = AudioPitchHelper.centsDifference(_currentFrequency, target);

    // Apply slight smoothing to needle movement
    final clampedCents = cents.clamp(-50.0, 50.0);

    // For very small differences, snap to center for "perfect" tuning
    if (clampedCents.abs() < 1.0) {
      return 0.0;
    }

    return clampedCents;
  }

  String _getTuningStatus() {
    if (!_isTuning) return 'Tap to Start Tuning';
    if (_currentFrequency <= 0) return 'Listening...';

    final cents = _getNeedleValue().abs();
    if (cents < 2) return 'Perfect! 🎯';
    if (cents < 8) return 'Very Close';
    if (cents < 15) return 'Almost There';

    final targetIndex = _autoDetectedStringIndex ?? _selectedStringIndex;
    final target = _guitarStrings[targetIndex].frequency;

    if (_currentFrequency < target) {
      return 'Too Low ↓';
    }
    return 'Too High ↑';
  }

  Color _getTuningStatusColor() {
    if (!_isTuning) return Colors.grey;
    if (_currentFrequency <= 0) return Colors.orange;
    final cents = _getNeedleValue().abs();
    if (cents < 2) return Colors.green;
    if (cents < 8) return Colors.lightGreen;
    if (cents < 15) return Colors.orange;
    return Colors.red;
  }

  void _selectString(int index) {
    setState(() {
      _selectedStringIndex = index;
      _autoDetectedStringIndex = null; // Clear auto-detection
    });
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: const Text(
          'Guitar Tuner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8A2387), Color(0xFFF27121), Color(0xFFE94057)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTuningHeader(),
            _buildFrequencyDisplay(),
            Expanded(child: _buildRadialGauge()),
            _buildStringSelector(),
            _buildTuningButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTuningHeader() {
    final mode = _tuningModes[_selectedTuningModeIndex];
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Tuning',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              ),
              Text(
                mode.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                mode.description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTuningStatusColor(),
                  _getTuningStatusColor().withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getTuningStatus(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyDisplay() {
    if (!_isTuning) return const SizedBox.shrink();

    final targetIndex = _autoDetectedStringIndex ?? _selectedStringIndex;
    final target = _guitarStrings[targetIndex].frequency;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: _autoDetectedStringIndex != null
            ? Border.all(color: Colors.orange.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Column(
        children: [
          if (_autoDetectedStringIndex != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Auto-detected: ${_guitarStrings[_autoDetectedStringIndex!].name} (String ${_guitarStrings[_autoDetectedStringIndex!].stringNumber})',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Target',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  Text(
                    '${target.toStringAsFixed(2)} Hz',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade700),
              Column(
                children: [
                  Text(
                    'Current',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  Text(
                    _currentFrequency > 0
                        ? '${_currentFrequency.toStringAsFixed(2)} Hz'
                        : '-- Hz',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getTuningStatusColor(),
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade700),
              Column(
                children: [
                  Text(
                    'Cents',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  Text(
                    _currentFrequency > 0
                        ? '${_getNeedleValue().toStringAsFixed(1)}'
                        : '--',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getTuningStatusColor(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadialGauge() {
    final targetIndex = _autoDetectedStringIndex ?? _selectedStringIndex;
    final currentString = _guitarStrings[targetIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(maxHeight: 300),
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: -50,
            maximum: 50,
            showAxisLine: false,
            showTicks: true,
            ticksPosition: ElementsPosition.outside,
            minorTicksPerInterval: 4,
            showLabels: true,
            labelOffset: 15,
            axisLabelStyle: const GaugeTextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
            ranges: <GaugeRange>[
              GaugeRange(
                startValue: -50,
                endValue: -15,
                color: const Color(0xFFE94057),
                startWidth: 18,
                endWidth: 18,
              ),
              GaugeRange(
                startValue: -15,
                endValue: -8,
                color: const Color(0xFFF27121),
                startWidth: 18,
                endWidth: 18,
              ),
              GaugeRange(
                startValue: -8,
                endValue: -2,
                color: Colors.lightGreen,
                startWidth: 20,
                endWidth: 20,
              ),
              GaugeRange(
                startValue: -2,
                endValue: 2,
                color: Colors.green,
                startWidth: 24,
                endWidth: 24,
              ),
              GaugeRange(
                startValue: 2,
                endValue: 8,
                color: Colors.lightGreen,
                startWidth: 20,
                endWidth: 20,
              ),
              GaugeRange(
                startValue: 8,
                endValue: 15,
                color: const Color(0xFFF27121),
                startWidth: 18,
                endWidth: 18,
              ),
              GaugeRange(
                startValue: 15,
                endValue: 50,
                color: const Color(0xFF8A2387),
                startWidth: 18,
                endWidth: 18,
              ),
            ],
            pointers: <GaugePointer>[
              NeedlePointer(
                value: _getNeedleValue(),
                enableAnimation: true,
                animationDuration: 100, // Faster animation for better response
                animationType: AnimationType.ease,
                needleColor: Colors.white,
                needleLength: 0.65,
                lengthUnit: GaugeSizeUnit.factor,
                needleStartWidth: 1.5,
                needleEndWidth: 5,
                knobStyle: const KnobStyle(
                  knobRadius: 0.09,
                  color: Color(0xFFF27121),
                  borderColor: Colors.white,
                  borderWidth: 0.02,
                  sizeUnit: GaugeSizeUnit.factor,
                ),
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentString.name,
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: _autoDetectedStringIndex != null
                            ? Colors.orange
                            : Colors.white,
                      ),
                    ),
                    Text(
                      'String ${currentString.stringNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    if (_isTuning && _currentFrequency > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_getNeedleValue().abs().toStringAsFixed(1)} cents',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTuningStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                angle: 90,
                positionFactor: 0.5,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStringSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Select String',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(_guitarStrings.length, (i) {
                final s = _guitarStrings[i];
                final selected = i == _selectedStringIndex;
                final autoDetected = i == _autoDetectedStringIndex;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 70,
                  decoration: BoxDecoration(
                    gradient: autoDetected
                        ? const LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                          )
                        : selected
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
                      color: autoDetected
                          ? Colors.orange
                          : selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      width: autoDetected || selected ? 2 : 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () => _selectString(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: (selected || autoDetected)
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'String ${s.stringNumber}',
                            style: TextStyle(
                              fontSize: 10,
                              color: (selected || autoDetected)
                                  ? Colors.white70
                                  : Colors.white60,
                            ),
                          ),
                          Text(
                            '${s.frequency.toStringAsFixed(0)}Hz',
                            style: TextStyle(
                              fontSize: 9,
                              color: (selected || autoDetected)
                                  ? Colors.white60
                                  : Colors.white70,
                            ),
                          ),
                        ],
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

  Widget _buildTuningButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isTuning ? _stopTuning : _startTuning,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
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
}

class GuitarString {
  final String name;
  final String note;
  final double frequency;
  final int stringNumber;

  GuitarString({
    required this.name,
    required this.note,
    required this.frequency,
    required this.stringNumber,
  });
}

class TuningMode {
  final String name;
  final String description;

  TuningMode({required this.name, required this.description});
}

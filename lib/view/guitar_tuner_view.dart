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
    GuitarString(name: 'E', note: 'E', frequency: 329.63),
    GuitarString(name: 'B', note: 'B', frequency: 246.94),
    GuitarString(name: 'G', note: 'G', frequency: 196.00),
    GuitarString(name: 'D', note: 'D', frequency: 146.83),
    GuitarString(name: 'A', note: 'A', frequency: 110.00),
    GuitarString(name: 'E', note: 'E', frequency: 82.41),
  ];

  int _selectedStringIndex = 0;
  final int _selectedTuningModeIndex = 0;
  double _currentFrequency = 0.0;
  bool _isTuning = false;

  @override
  void initState() {
    super.initState();
    _audioHelper = AudioPitchHelper(
      onFrequencyDetected: (freq) {
        setState(() => _currentFrequency = freq);
      },
    );
  }

  @override
  void dispose() {
    _audioHelper.stop();
    super.dispose();
  }

  // ------------------ Tuning Logic ------------------
  Future<void> _startTuning() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      await _audioHelper.start();
      setState(() => _isTuning = true);
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable microphone permission in settings.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied.')),
      );
    }
  }

  Future<void> _stopTuning() async {
    await _audioHelper.stop();
    setState(() {
      _isTuning = false;
      _currentFrequency = 0.0;
    });
  }

  double _getNeedleValue() {
    if (!_isTuning) return 0;
    final target = _guitarStrings[_selectedStringIndex].frequency;
    return AudioPitchHelper.centsDifference(
      _currentFrequency,
      target,
    ).clamp(-50, 50);
  }

  String _getTuningStatus() {
    if (!_isTuning) return 'Tap to Start Tuning';
    if (_currentFrequency <= 0) return 'Listening...';

    final cents = _getNeedleValue().abs();
    if (cents < 5) return 'Perfect!';
    if (cents < 15) return 'Very Close';
    if (_currentFrequency < _guitarStrings[_selectedStringIndex].frequency) {
      return 'Too Low';
    }
    return 'Too High';
  }

  Color _getTuningStatusColor() {
    if (!_isTuning) return Colors.grey;
    if (_currentFrequency <= 0) return Colors.orange;
    final cents = _getNeedleValue().abs();
    if (cents < 5) return Colors.green;
    if (cents < 15) return Colors.orange;
    return Colors.red;
  }

  void _selectString(int index) {
    setState(() {
      _selectedStringIndex = index;
      _currentFrequency = 0.0;
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
              gradient: const LinearGradient(
                colors: [Color(0xFF8A2387), Color(0xFFF27121)],
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

  Widget _buildRadialGauge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(maxHeight: 300),
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: -50,
            maximum: 50,
            showAxisLine: false,
            showTicks: false,
            showLabels: true,
            axisLabelStyle: const GaugeTextStyle(
              fontSize: 12,
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
                endValue: -5,
                color: const Color(0xFFF27121),
                startWidth: 18,
                endWidth: 18,
              ),
              GaugeRange(
                startValue: -5,
                endValue: 5,
                color: Colors.green,
                startWidth: 22,
                endWidth: 22,
              ),
              GaugeRange(
                startValue: 5,
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
                animationDuration: 100,
                needleColor: Colors.white,
                needleLength: 0.6,
                lengthUnit: GaugeSizeUnit.factor,
                needleStartWidth: 1,
                needleEndWidth: 4,
                knobStyle: const KnobStyle(
                  knobRadius: 0.08,
                  color: Color(0xFFF27121),
                  sizeUnit: GaugeSizeUnit.factor,
                ),
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
            height: 70,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(_guitarStrings.length, (i) {
                final s = _guitarStrings[i];
                final selected = i == _selectedStringIndex;
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: selected
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
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      width: selected ? 2 : 1,
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s.frequency.toStringAsFixed(0)}Hz',
                            style: TextStyle(
                              fontSize: 10,
                              color: selected ? Colors.white : Colors.white60,
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

  GuitarString({
    required this.name,
    required this.note,
    required this.frequency,
  });
}

class TuningMode {
  final String name;
  final String description;

  TuningMode({required this.name, required this.description});
}

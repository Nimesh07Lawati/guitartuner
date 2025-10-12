import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GuitarTunerScreen extends StatefulWidget {
  const GuitarTunerScreen({super.key});

  @override
  State<GuitarTunerScreen> createState() => _GuitarTunerScreenState();
}

class _GuitarTunerScreenState extends State<GuitarTunerScreen> {
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
  int _selectedTuningModeIndex = 0;
  double _currentFrequency = 0.0;
  bool _isTuning = false;

  void _startTuning() {
    setState(() {
      _isTuning = true;
    });
    _simulateFrequencyDetection();
  }

  void _stopTuning() {
    setState(() {
      _isTuning = false;
    });
  }

  void _simulateFrequencyDetection() {
    if (!_isTuning) return;

    final targetFreq = _guitarStrings[_selectedStringIndex].frequency;
    // Simulate realistic frequency variations
    final simulatedFreq =
        targetFreq + (DateTime.now().millisecond % 20 - 10) * 0.3;

    setState(() {
      _currentFrequency = simulatedFreq;
    });

    // Continue simulation
    Future.delayed(
      const Duration(milliseconds: 100),
      _simulateFrequencyDetection,
    );
  }

  void _selectString(int index) {
    setState(() {
      _selectedStringIndex = index;
      _currentFrequency = 0.0;
    });
  }

  void _showTuningModeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Select Tuning Mode',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _tuningModes.length,
              itemBuilder: (context, index) {
                final tuningMode = _tuningModes[index];
                final isSelected = index == _selectedTuningModeIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF8A2387), Color(0xFFF27121)],
                          )
                        : LinearGradient(
                            colors: [
                              const Color(0xFF2D2D2D).withOpacity(0.8),
                              const Color(0xFF1A1A1A).withOpacity(0.8),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      tuningMode.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      tuningMode.description,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedTuningModeIndex = index;
                      });
                      Navigator.of(context).pop();
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFFF27121)),
              ),
            ),
          ],
        );
      },
    );
  }

  double _getNeedleValue() {
    if (!_isTuning) return 0;

    final targetFreq = _guitarStrings[_selectedStringIndex].frequency;
    final diff = _currentFrequency - targetFreq;
    // Normalize difference to range [-10, 10] for gauge display
    return diff.clamp(-10, 10);
  }

  String _getTuningStatus() {
    if (!_isTuning) return 'Tap to Start Tuning';

    final needleValue = _getNeedleValue().abs();
    if (needleValue < 1) return 'Perfect!';
    if (needleValue < 3) return 'Very Close';
    if (_currentFrequency < _guitarStrings[_selectedStringIndex].frequency)
      return 'Too Low';
    return 'Too High';
  }

  Color _getTuningStatusColor() {
    if (!_isTuning) return Colors.grey;

    final needleValue = _getNeedleValue().abs();
    if (needleValue < 1) return Colors.green;
    if (needleValue < 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414), // Near Black background
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 24),
            onPressed: _showTuningModeDialog,
            tooltip: 'Tuning Options',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tuning Mode Display
            Container(
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Text(
                        _tuningModes[_selectedTuningModeIndex].name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _tuningModes[_selectedTuningModeIndex].description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
            ),

            // Radial Gauge Tuner
            Expanded(child: _buildRadialGauge()),

            // String Selection (Horizontal Scrollable)
            _buildStringSelector(),

            // Tuning Button
            _buildTuningButton(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRadialGauge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(
        maxHeight: 300, // Reduced from 350 to prevent overflow
      ),
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: -10,
            maximum: 10,
            interval: 2,
            showAxisLine: false,
            showTicks: false,
            showLabels: true,
            axisLabelStyle: const GaugeTextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            ranges: <GaugeRange>[
              // Too Low range
              GaugeRange(
                startValue: -10,
                endValue: -3,
                color: const Color(0xFFE94057), // Hot Pink
                startWidth: 18,
                endWidth: 18,
              ),
              // Close range (Orange)
              GaugeRange(
                startValue: -3,
                endValue: -1,
                color: const Color(0xFFF27121), // Bright Orange
                startWidth: 18,
                endWidth: 18,
              ),
              // Perfect range (Green)
              GaugeRange(
                startValue: -1,
                endValue: 1,
                color: Colors.green,
                startWidth: 22,
                endWidth: 22,
              ),
              // Close range (Orange)
              GaugeRange(
                startValue: 1,
                endValue: 3,
                color: const Color(0xFFF27121), // Bright Orange
                startWidth: 18,
                endWidth: 18,
              ),
              // Too High range
              GaugeRange(
                startValue: 3,
                endValue: 10,
                color: const Color(0xFF8A2387), // Electric Purple
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
                  color: Color(0xFFF27121), // Orange
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
              children: List.generate(_guitarStrings.length, (index) {
                final guitarString = _guitarStrings[index];
                final isSelected = index == _selectedStringIndex;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF8A2387),
                              Color(0xFFF27121),
                              Color(0xFFE94057),
                            ],
                            stops: [0.0, 0.5, 1.0],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
                          ),
                    borderRadius: BorderRadius.circular(15),
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
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () => _selectString(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            guitarString.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${guitarString.frequency.toStringAsFixed(0)}Hz',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white : Colors.white60,
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
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
          shadowColor: const Color(0xFF8A2387).withOpacity(0.5),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: _isTuning
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
                    stops: [0.0, 0.5, 1.0],
                  ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A2387).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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

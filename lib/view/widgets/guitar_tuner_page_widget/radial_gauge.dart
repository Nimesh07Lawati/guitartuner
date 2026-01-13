import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../../models/guitar_string.dart';

class TunerRadialGauge extends StatelessWidget {
  final double needleValue;
  final GuitarString string;
  final Color statusColor;
  final bool autoDetected;

  const TunerRadialGauge({
    super.key,
    required this.needleValue,
    required this.string,
    required this.statusColor,
    required this.autoDetected,
  });

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: -50,
          maximum: 50,
          showAxisLine: false,
          ranges: _ranges(),
          pointers: [
            NeedlePointer(
              value: needleValue,
              enableAnimation: true,
              animationDuration: 100,
              needleColor: Colors.white,
              knobStyle: const KnobStyle(
                color: Color(0xFFF27121),
                borderColor: Colors.white,
                borderWidth: 0.02,
              ),
            ),
          ],
          annotations: [
            GaugeAnnotation(
              angle: 90,
              positionFactor: 0.5,
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    string.name,
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: autoDetected ? Colors.orange : Colors.white,
                    ),
                  ),
                  Text(
                    'String ${string.stringNumber}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<GaugeRange> _ranges() => [
    GaugeRange(startValue: -50, endValue: -15, color: const Color(0xFFE94057)),
    GaugeRange(startValue: -15, endValue: -8, color: const Color(0xFFF27121)),
    GaugeRange(startValue: -8, endValue: -2, color: Colors.lightGreen),
    GaugeRange(startValue: -2, endValue: 2, color: Colors.green),
    GaugeRange(startValue: 2, endValue: 8, color: Colors.lightGreen),
    GaugeRange(startValue: 8, endValue: 15, color: const Color(0xFFF27121)),
    GaugeRange(startValue: 15, endValue: 50, color: const Color(0xFF8A2387)),
  ];
}

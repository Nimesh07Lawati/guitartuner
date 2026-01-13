import 'package:flutter/material.dart';
import '../../../../models/guitar_string.dart';

class FrequencyDisplay extends StatelessWidget {
  final bool isTuning;
  final double currentFrequency;
  final double targetFrequency;
  final double cents;
  final Color statusColor;
  final GuitarString currentString;
  final bool autoDetected;

  const FrequencyDisplay({
    super.key,
    required this.isTuning,
    required this.currentFrequency,
    required this.targetFrequency,
    required this.cents,
    required this.statusColor,
    required this.currentString,
    required this.autoDetected,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTuning) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: autoDetected
            ? Border.all(color: Colors.orange.withOpacity(0.6), width: 2)
            : null,
      ),
      child: Column(
        children: [
          if (autoDetected)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Auto-detected: ${currentString.name} (String ${currentString.stringNumber})',
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
              _buildColumn(
                'Target',
                '${targetFrequency.toStringAsFixed(2)} Hz',
                Colors.white,
              ),
              _divider(),
              _buildColumn(
                'Current',
                currentFrequency > 0
                    ? '${currentFrequency.toStringAsFixed(2)} Hz'
                    : '-- Hz',
                statusColor,
              ),
              _divider(),
              _buildColumn(
                'Cents',
                currentFrequency > 0 ? cents.toStringAsFixed(1) : '--',
                statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 30, color: Colors.grey.shade700);
}

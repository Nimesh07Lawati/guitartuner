import 'package:flutter/material.dart';
import '../../../../models/guitar_string.dart';

class StringSelector extends StatelessWidget {
  final List<GuitarString> strings;
  final int selectedIndex;
  final int? autoDetectedIndex;
  final ValueChanged<int> onSelect;

  const StringSelector({
    super.key,
    required this.strings,
    required this.selectedIndex,
    required this.autoDetectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: strings.length,
        itemBuilder: (_, i) {
          final s = strings[i];
          final selected = i == selectedIndex;
          final auto = i == autoDetectedIndex;

          return GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: auto
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
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'String ${s.stringNumber}',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                  Text(
                    '${s.frequency.toStringAsFixed(0)}Hz',
                    style: const TextStyle(fontSize: 9, color: Colors.white60),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

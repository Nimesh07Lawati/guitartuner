import 'guitar_string.dart';

class TuningMode {
  final String name;
  final String description;
  final List<GuitarString> strings;

  const TuningMode({
    required this.name,
    required this.description,
    required this.strings,
  });

  // 🎸 STANDARD TUNING
  static const standard = TuningMode(
    name: "Standard",
    description: "E A D G B E",
    strings: [
      GuitarString(name: 'E', note: 'E', frequency: 82.41, stringNumber: 6),
      GuitarString(name: 'A', note: 'A', frequency: 110.00, stringNumber: 5),
      GuitarString(name: 'D', note: 'D', frequency: 146.83, stringNumber: 4),
      GuitarString(name: 'G', note: 'G', frequency: 196.00, stringNumber: 3),
      GuitarString(name: 'B', note: 'B', frequency: 246.94, stringNumber: 2),
      GuitarString(name: 'E', note: 'E', frequency: 329.63, stringNumber: 1),
    ],
  );

  // 🎸 DROP D
  static const dropD = TuningMode(
    name: "Drop D",
    description: "D A D G B E",
    strings: [
      GuitarString(name: 'D', note: 'D', frequency: 73.42, stringNumber: 6),
      GuitarString(name: 'A', note: 'A', frequency: 110.00, stringNumber: 5),
      GuitarString(name: 'D', note: 'D', frequency: 146.83, stringNumber: 4),
      GuitarString(name: 'G', note: 'G', frequency: 196.00, stringNumber: 3),
      GuitarString(name: 'B', note: 'B', frequency: 246.94, stringNumber: 2),
      GuitarString(name: 'E', note: 'E', frequency: 329.63, stringNumber: 1),
    ],
  );

  static const List<TuningMode> allModes = [standard, dropD];
}

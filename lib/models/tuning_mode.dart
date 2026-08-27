import 'guitar_string.dart';

/// A named set of six target pitches, low string (6) to high (1).
///
/// All frequencies are equal temperament at A4 = 440Hz, rounded to 2dp.
/// Strings are always listed 6 -> 1 so index 0 is the lowest string, which
/// is what [StringSelector] and the auto-detect index both assume.
class TuningMode {
  final String name;
  final String description;
  final List<GuitarString> strings;

  const TuningMode({
    required this.name,
    required this.description,
    required this.strings,
  });

  /// Lowest target in this tuning. Used to sanity-check that the detector's
  /// accepted frequency range actually covers every mode we ship.
  double get lowestFrequency =>
      strings.map((s) => s.frequency).reduce((a, b) => a < b ? a : b);

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

  // 🎸 HALF STEP DOWN (Eb standard) — every string down one semitone.
  static const halfStepDown = TuningMode(
    name: "Half Step Down",
    description: "Eb Ab Db Gb Bb Eb",
    strings: [
      GuitarString(name: 'Eb', note: 'Eb', frequency: 77.78, stringNumber: 6),
      GuitarString(name: 'Ab', note: 'Ab', frequency: 103.83, stringNumber: 5),
      GuitarString(name: 'Db', note: 'Db', frequency: 138.59, stringNumber: 4),
      GuitarString(name: 'Gb', note: 'Gb', frequency: 185.00, stringNumber: 3),
      GuitarString(name: 'Bb', note: 'Bb', frequency: 233.08, stringNumber: 2),
      GuitarString(name: 'Eb', note: 'Eb', frequency: 311.13, stringNumber: 1),
    ],
  );

  // 🎸 FULL STEP DOWN (D standard) — every string down two semitones.
  static const fullStepDown = TuningMode(
    name: "Full Step Down",
    description: "D G C F A D",
    strings: [
      GuitarString(name: 'D', note: 'D', frequency: 73.42, stringNumber: 6),
      GuitarString(name: 'G', note: 'G', frequency: 98.00, stringNumber: 5),
      GuitarString(name: 'C', note: 'C', frequency: 130.81, stringNumber: 4),
      GuitarString(name: 'F', note: 'F', frequency: 174.61, stringNumber: 3),
      GuitarString(name: 'A', note: 'A', frequency: 220.00, stringNumber: 2),
      GuitarString(name: 'D', note: 'D', frequency: 293.66, stringNumber: 1),
    ],
  );

  // 🎸 DROP D — standard with only the 6th string down a full step.
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

  // 🎸 DROP C — full step down, then the 6th string dropped again.
  static const dropC = TuningMode(
    name: "Drop C",
    description: "C G C F A D",
    strings: [
      GuitarString(name: 'C', note: 'C', frequency: 65.41, stringNumber: 6),
      GuitarString(name: 'G', note: 'G', frequency: 98.00, stringNumber: 5),
      GuitarString(name: 'C', note: 'C', frequency: 130.81, stringNumber: 4),
      GuitarString(name: 'F', note: 'F', frequency: 174.61, stringNumber: 3),
      GuitarString(name: 'A', note: 'A', frequency: 220.00, stringNumber: 2),
      GuitarString(name: 'D', note: 'D', frequency: 293.66, stringNumber: 1),
    ],
  );

  // 🎸 OPEN G — open strings sound a G major chord.
  static const openG = TuningMode(
    name: "Open G",
    description: "D G D G B D",
    strings: [
      GuitarString(name: 'D', note: 'D', frequency: 73.42, stringNumber: 6),
      GuitarString(name: 'G', note: 'G', frequency: 98.00, stringNumber: 5),
      GuitarString(name: 'D', note: 'D', frequency: 146.83, stringNumber: 4),
      GuitarString(name: 'G', note: 'G', frequency: 196.00, stringNumber: 3),
      GuitarString(name: 'B', note: 'B', frequency: 246.94, stringNumber: 2),
      GuitarString(name: 'D', note: 'D', frequency: 293.66, stringNumber: 1),
    ],
  );

  // 🎸 OPEN D — open strings sound a D major chord.
  static const openD = TuningMode(
    name: "Open D",
    description: "D A D F# A D",
    strings: [
      GuitarString(name: 'D', note: 'D', frequency: 73.42, stringNumber: 6),
      GuitarString(name: 'A', note: 'A', frequency: 110.00, stringNumber: 5),
      GuitarString(name: 'D', note: 'D', frequency: 146.83, stringNumber: 4),
      GuitarString(name: 'F#', note: 'F#', frequency: 185.00, stringNumber: 3),
      GuitarString(name: 'A', note: 'A', frequency: 220.00, stringNumber: 2),
      GuitarString(name: 'D', note: 'D', frequency: 293.66, stringNumber: 1),
    ],
  );

  // 🎸 DADGAD — modal open tuning, neither major nor minor.
  static const dadgad = TuningMode(
    name: "DADGAD",
    description: "D A D G A D",
    strings: [
      GuitarString(name: 'D', note: 'D', frequency: 73.42, stringNumber: 6),
      GuitarString(name: 'A', note: 'A', frequency: 110.00, stringNumber: 5),
      GuitarString(name: 'D', note: 'D', frequency: 146.83, stringNumber: 4),
      GuitarString(name: 'G', note: 'G', frequency: 196.00, stringNumber: 3),
      GuitarString(name: 'A', note: 'A', frequency: 220.00, stringNumber: 2),
      GuitarString(name: 'D', note: 'D', frequency: 293.66, stringNumber: 1),
    ],
  );

  /// Ordered roughly by how commonly they're used, so the picker reads
  /// sensibly top to bottom.
  static const List<TuningMode> allModes = [
    standard,
    halfStepDown,
    fullStepDown,
    dropD,
    dropC,
    openG,
    openD,
    dadgad,
  ];
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guitartuner/models/tuning_mode.dart';
import 'package:guitartuner/utils/audio_pitch_helper.dart';

/// Equal-temperament reference, A4 = 440Hz. Recomputed here rather than
/// imported so the test is an independent check on the hand-written tables,
/// not a restatement of them.
const _notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
const _flatToSharp = {'Db': 'C#', 'Eb': 'D#', 'Gb': 'F#', 'Ab': 'G#', 'Bb': 'A#'};

double _expected(String noteName, int octave) {
  final name = _flatToSharp[noteName] ?? noteName;
  final semitonesFromA4 =
      _notes.indexOf(name) + 12 * octave - (_notes.indexOf('A') + 12 * 4);
  return 440.0 * pow(2, semitonesFromA4 / 12);
}

void main() {
  group('every shipped tuning', () {
    for (final mode in TuningMode.allModes) {
      test('${mode.name} is well formed', () {
        expect(mode.strings.length, 6, reason: 'a guitar has six strings');

        // Index 0 must be the lowest string - StringSelector, the auto-detect
        // index and changeTuningMode's reset to 0 all depend on this order.
        expect(
          mode.strings.map((s) => s.stringNumber),
          [6, 5, 4, 3, 2, 1],
          reason: 'strings must run low (6) to high (1)',
        );

        final freqs = mode.strings.map((s) => s.frequency).toList();
        for (var i = 1; i < freqs.length; i++) {
          expect(
            freqs[i],
            greaterThan(freqs[i - 1]),
            reason: 'string ${6 - i} should be higher than the one below it',
          );
        }
      });

      test('${mode.name} sits inside the detector range', () {
        // The bug this guards: Drop C's low C2 is 65.41Hz and the floor used
        // to be 65.0, so a low string that was even slightly flat got thrown
        // away as noise. Require a full semitone of headroom either side so
        // an out-of-tune string still registers.
        const semitone = 1.05946;

        expect(
          mode.lowestFrequency / semitone,
          greaterThan(AudioPitchHelper.minValidFrequency),
          reason:
              '${mode.name} low string (${mode.lowestFrequency}Hz) has no room '
              'to read flat above the ${AudioPitchHelper.minValidFrequency}Hz floor',
        );

        final highest = mode.strings.last.frequency;
        expect(
          highest * semitone,
          lessThan(AudioPitchHelper.maxValidFrequency),
          reason: '${mode.name} high string has no room to read sharp',
        );
      });

      test('${mode.name} description matches its strings', () {
        expect(
          mode.description.split(' '),
          mode.strings.map((s) => s.name).toList(),
          reason: 'the header text must match the actual targets',
        );
      });
    }
  });

  test('frequencies are correct equal temperament', () {
    // Spot-check every distinct target against the computed reference.
    const octaves = {
      'Standard': [2, 2, 3, 3, 3, 4],
      'Half Step Down': [2, 2, 3, 3, 3, 4],
      'Full Step Down': [2, 2, 3, 3, 3, 4],
      'Drop D': [2, 2, 3, 3, 3, 4],
      'Drop C': [2, 2, 3, 3, 3, 4],
      'Open G': [2, 2, 3, 3, 3, 4],
      'Open D': [2, 2, 3, 3, 3, 4],
      'DADGAD': [2, 2, 3, 3, 3, 4],
    };

    for (final mode in TuningMode.allModes) {
      final oct = octaves[mode.name]!;
      for (var i = 0; i < mode.strings.length; i++) {
        final s = mode.strings[i];
        expect(
          s.frequency,
          closeTo(_expected(s.name, oct[i]), 0.01),
          reason: '${mode.name} string ${s.stringNumber} (${s.name})',
        );
      }
    }
  });

  group('auto-detect', () {
    test('snaps an exact target to its own string in every tuning', () {
      for (final mode in TuningMode.allModes) {
        final targets = mode.strings.map((s) => s.frequency).toList();

        for (final s in mode.strings) {
          final closest =
              AudioPitchHelper.findClosestFrequency(s.frequency, targets);
          expect(
            closest,
            s.frequency,
            reason: '${mode.name}: ${s.name} should match itself',
          );
        }
      }
    });

    test('no tuning has duplicate targets', () {
      // findClosestFrequency returns a frequency and the controller maps it
      // back with indexWhere, so two strings sharing a frequency would make
      // the higher one unreachable.
      for (final mode in TuningMode.allModes) {
        final freqs = mode.strings.map((s) => s.frequency).toList();
        expect(
          freqs.toSet().length,
          freqs.length,
          reason: '${mode.name} has a duplicated target frequency',
        );
      }
    });
  });

  group('cents', () {
    test('is zero at pitch and signed correctly', () {
      expect(AudioPitchHelper.centsDifference(440, 440), closeTo(0, 0.001));
      expect(AudioPitchHelper.centsDifference(880, 440), closeTo(1200, 0.001));
      expect(AudioPitchHelper.centsDifference(220, 440), closeTo(-1200, 0.001));
    });
  });
}

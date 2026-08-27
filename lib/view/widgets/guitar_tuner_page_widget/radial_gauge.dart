import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../models/guitar_string.dart';

/// Radial tuner dial, drawn by a single [CustomPainter].
///
/// Replaces the previous `SfRadialGauge`. That widget built roughly a dozen
/// separate render objects (one per `GaugeRange`, plus the needle and a
/// widget-hosting annotation), all of which re-laid-out every time `cents`
/// changed — which for a live tuner is every audio frame. This paints the
/// same picture with one render object and no layout pass at all.
///
/// The constructor signature is deliberately unchanged so this drops
/// straight into `GuitarTunerScreen` with no call-site edits.
class TunerRadialGauge extends StatefulWidget {
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
  State<TunerRadialGauge> createState() => _TunerRadialGaugeState();
}

class _TunerRadialGaugeState extends State<TunerRadialGauge>
    with SingleTickerProviderStateMixin {
  /// How long the needle takes to settle on a new reading. Long enough to
  /// damp the jitter inherent in pitch detection, short enough that the
  /// dial still feels like it's tracking the string in real time.
  static const Duration _settleDuration = Duration(milliseconds: 140);

  late final AnimationController _controller;
  late Animation<double> _needle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _settleDuration);
    _needle = AlwaysStoppedAnimation(widget.needleValue);
  }

  @override
  void didUpdateWidget(TunerRadialGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.needleValue != oldWidget.needleValue) {
      // Start from where the needle physically is, not from the previous
      // target — otherwise a reading that arrives mid-flight makes the
      // needle jump back to the old value before setting off again.
      _needle = Tween<double>(
        begin: _needle.value,
        end: widget.needleValue,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The needle repaints ~60x/sec while settling; the boundary keeps that
    // from dirtying the rest of the tuner screen.
    // A painter's TextStyles get no theme inheritance — whatever font the
    // rest of the app is using has to be handed to it explicitly, or the
    // dial silently renders in the platform default while everything around
    // it uses the themed face.
    final fontFamily = DefaultTextStyle.of(context).style.fontFamily ??
        Theme.of(context).textTheme.bodyMedium?.fontFamily;

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _TunerGaugePainter(
          needle: _needle,
          noteName: widget.string.name,
          stringNumber: widget.string.stringNumber,
          statusColor: widget.statusColor,
          autoDetected: widget.autoDetected,
          fontFamily: fontFamily,
        ),
      ),
    );
  }
}

class _Zone {
  final double from;
  final double to;
  final Color color;

  const _Zone(this.from, this.to, this.color);
}

class _TunerGaugePainter extends CustomPainter {
  _TunerGaugePainter({
    required this.needle,
    required this.noteName,
    required this.stringNumber,
    required this.statusColor,
    required this.autoDetected,
    required this.fontFamily,
  }) : super(repaint: needle);

  /// Drives repaints directly, bypassing the widget rebuild entirely.
  final Animation<double> needle;
  final String noteName;
  final int stringNumber;
  final Color statusColor;
  final bool autoDetected;
  final String? fontFamily;

  static const double _maxCents = 50;
  static const double _trackWidth = 22;

  // The dial is the top half of a circle: canvas angles run clockwise from
  // due-right, so pi is due-left and a pi sweep arrives at due-right having
  // passed through straight-up. Straight-up is therefore dead-in-tune.
  static const double _startAngle = math.pi;
  static const double _sweep = math.pi;

  /// Exponent applied to the normalised offset. Below 1 it stretches the
  /// small deviations across more of the arc: the last couple of cents are
  /// the whole point of a tuner, but on a linear +/-50 scale they occupy a
  /// few unreadable pixels. At 0.6, a 2-cent error swings the needle about
  /// 15% of the way out instead of 4%.
  static const double _centreExpansion = 0.6;

  static const List<_Zone> _zones = [
    _Zone(-50, -15, Color(0xFFE94057)),
    _Zone(-15, -8, Color(0xFFF27121)),
    _Zone(-8, -2, Colors.lightGreen),
    _Zone(-2, 2, Colors.green),
    _Zone(2, 8, Colors.lightGreen),
    _Zone(8, 15, Color(0xFFF27121)),
    _Zone(15, 50, Color(0xFF8A2387)),
  ];

  static const List<double> _tickCents = [-50, -15, -8, -2, 2, 8, 15, 50];

  static double _position(double cents) {
    final t = (cents / _maxCents).clamp(-1.0, 1.0);
    final magnitude = math.pow(t.abs(), _centreExpansion).toDouble();
    return t.isNegative ? -magnitude : magnitude;
  }

  static double _angle(double cents) =>
      _startAngle + (_position(cents) + 1) / 2 * _sweep;

  static Offset _unit(double angle) => Offset(math.cos(angle), math.sin(angle));

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width / 2 - _trackWidth, size.height * 0.58);
    if (radius <= 0) return;

    // Pivot sits below centre so the top semicircle fills the box.
    final centre = Offset(size.width / 2, size.height / 2 + radius * 0.4);

    _paintZones(canvas, centre, radius);
    _paintTicks(canvas, centre, radius);
    _paintFlatSharpMarks(canvas, centre, radius);
    _paintDeviationArc(canvas, centre, radius);
    _paintLabels(canvas, centre, radius);
    _paintMarker(canvas, centre, radius);
  }

  void _paintZones(Canvas canvas, Offset centre, double radius) {
    final rect = Rect.fromCircle(center: centre, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _trackWidth;

    for (final zone in _zones) {
      final from = _angle(zone.from);
      final to = _angle(zone.to);
      canvas.drawArc(rect, from, to - from, false, paint..color = zone.color);
    }
  }

  void _paintTicks(Canvas canvas, Offset centre, double radius) {
    final outer = radius - _trackWidth / 2 - 5;
    final tick = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final cents in _tickCents) {
      final dir = _unit(_angle(cents));
      canvas.drawLine(centre + dir * (outer - 10), centre + dir * outer, tick);
    }

    // Dead centre gets a longer, brighter tick — it's the target.
    final dir = _unit(_angle(0));
    canvas.drawLine(
      centre + dir * (outer - 18),
      centre + dir * outer,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Words rather than the ♭/♯ glyphs: U+266D and U+266F aren't in Roboto,
  /// so they render as tofu wherever the device has no fallback font that
  /// covers them. "FLAT"/"SHARP" also spell out the direction for anyone
  /// who doesn't read music notation.
  void _paintFlatSharpMarks(Canvas canvas, Offset centre, double radius) {
    final style = TextStyle(
      fontSize: 11,
      color: Colors.white54,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      fontFamily: fontFamily,
    );
    final inset = radius - _trackWidth - 20;

    for (final entry in const [(-50.0, 'FLAT'), (50.0, 'SHARP')]) {
      final label = _text(entry.$2, style);
      final at = centre + _unit(_angle(entry.$1)) * inset;
      label.paint(
        canvas,
        Offset(at.dx - label.width / 2, at.dy - label.height / 2),
      );
    }
  }

  void _paintLabels(Canvas canvas, Offset centre, double radius) {
    final note = _text(
      noteName,
      TextStyle(
        fontSize: (radius * 0.42).clamp(28.0, 56.0),
        fontWeight: FontWeight.bold,
        color: autoDetected ? Colors.orange : Colors.white,
        fontFamily: fontFamily,
      ),
    );
    final caption = _text(
      'String $stringNumber',
      TextStyle(fontSize: 14, color: Colors.grey, fontFamily: fontFamily),
    );

    const gap = 4.0;
    final blockHeight = note.height + gap + caption.height;
    final top = centre.dy - radius * 0.45 - blockHeight / 2;

    note.paint(canvas, Offset(centre.dx - note.width / 2, top));
    caption.paint(
      canvas,
      Offset(centre.dx - caption.width / 2, top + note.height + gap),
    );
  }

  /// A thin arc sweeping from dead-centre out to the current reading, so the
  /// size and direction of the error read at a glance even before you find
  /// the marker.
  void _paintDeviationArc(Canvas canvas, Offset centre, double radius) {
    final from = _angle(0);
    final to = _angle(needle.value);
    if ((to - from).abs() < 0.001) return;

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius - _trackWidth - 14),
      from,
      to - from,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = statusColor,
    );
  }

  /// The reading itself: a marker riding just inside the coloured track,
  /// pointing out at the current offset.
  ///
  /// This replaced a full-length pivot needle. At 0 cents that needle
  /// pointed straight up, directly through the note letter in the middle of
  /// the dial — and since the letter is the only note readout while idle
  /// (`FrequencyDisplay` collapses to nothing when not tuning), the letter
  /// is what had to stay. A marker confined to the outer band never crosses
  /// it, at any tempo of needle movement.
  void _paintMarker(Canvas canvas, Offset centre, double radius) {
    final dir = _unit(_angle(needle.value));
    final normal = Offset(-dir.dy, dir.dx);

    final tipRadius = radius - _trackWidth / 2 - 3;
    final baseRadius = tipRadius - radius * 0.13;
    final halfWidth = normal * (radius * 0.055);

    final tip = centre + dir * tipRadius;
    final baseLeft = centre + dir * baseRadius + halfWidth;
    final baseRight = centre + dir * baseRadius - halfWidth;

    final marker = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..close();

    // Dark outline first, so the white marker stays legible on top of any
    // of the seven zone colours it can sit over.
    canvas.drawPath(
      marker,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF141414),
    );
    canvas.drawPath(marker, Paint()..color = Colors.white);
  }

  TextPainter _text(String value, TextStyle style) => TextPainter(
    text: TextSpan(text: value, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  // The needle value is deliberately absent here: it arrives via the
  // `repaint` listenable, which schedules repaints without a rebuild, so
  // shouldRepaint is never consulted for it.
  @override
  bool shouldRepaint(_TunerGaugePainter old) =>
      old.noteName != noteName ||
      old.stringNumber != stringNumber ||
      old.statusColor != statusColor ||
      old.autoDetected != autoDetected ||
      old.fontFamily != fontFamily;
}

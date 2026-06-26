import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../models/category.dart';
import '../theme.dart';
import '../util/time_utils.dart';

class DonutSegment {
  DonutSegment(this.def, this.minutes);
  final CategoryDef def;
  final int minutes;
}

/// Hollow 24h ring. Each category is an arc sized by its total minutes that
/// day; the unlogged remainder is a faint track. Division ticks reach outward
/// with a small tag naming each section.
///
/// When [onBoundaryDrag*] callbacks are supplied, the boundary between two
/// adjacent segments can be dragged to move the handoff time between them.
class DayDonut extends StatefulWidget {
  const DayDonut({
    super.key,
    required this.segments,
    required this.totalMin,
    required this.centerLabel,
    this.onBoundaryDragStart,
    this.onBoundaryDragUpdate,
    this.onBoundaryDragEnd,
  });

  final List<DonutSegment> segments;
  final int totalMin;
  final String centerLabel;

  /// Called with the index of the segment to the LEFT of the grabbed boundary,
  /// or null if the touch didn't land on a draggable boundary.
  final void Function(int leftSegmentIndex)? onBoundaryDragStart;

  /// Signed minutes moved since drag start (+ grows the left segment).
  final void Function(int deltaMinutes)? onBoundaryDragUpdate;
  final VoidCallback? onBoundaryDragEnd;

  @override
  State<DayDonut> createState() => _DayDonutState();
}

class _DayDonutState extends State<DayDonut> {
  static const double _ringWidth = 24;
  int? _dragLeftIndex;
  double _dragStartAngle = 0;

  String _subLabel(AppL10n l) {
    final h = widget.totalMin ~/ 60;
    final m = widget.totalMin % 60;
    return l.totalLogged(h, m);
  }

  bool get _interactive => widget.onBoundaryDragStart != null;

  /// Geometry shared with the painter so hit-testing matches what's drawn.
  ({Offset center, double radius, double denom, List<double> boundaries})
      _geometry(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 64;
    final denom = math.max(widget.totalMin, 1440).toDouble();
    const start = -math.pi / 2;
    final boundaries = <double>[];
    var angle = start;
    for (final seg in widget.segments) {
      if (seg.minutes <= 0) continue;
      boundaries.add(angle); // start of this segment
      angle += (seg.minutes / denom) * 2 * math.pi;
    }
    boundaries.add(angle); // final boundary
    return (center: center, radius: radius, denom: denom, boundaries: boundaries);
  }

  void _onPanStart(DragStartDetails d, Size size) {
    final g = _geometry(size);
    final local = d.localPosition;
    final v = local - g.center;
    final dist = v.distance;
    if ((dist - g.radius).abs() > _ringWidth * 1.8) return; // not on the ring
    var touch = math.atan2(v.dy, v.dx);
    // Find the nearest INTERIOR boundary (index 1..n-1 maps to left segment i-1).
    int? best;
    double bestDelta = 0.25; // ~14° threshold
    for (var i = 1; i < g.boundaries.length - 1; i++) {
      final diff = _angleDiff(touch, g.boundaries[i]).abs();
      if (diff < bestDelta) {
        bestDelta = diff;
        best = i - 1; // left segment index
        _dragStartAngle = touch;
      }
    }
    if (best != null) {
      _dragLeftIndex = best;
      widget.onBoundaryDragStart!(best);
    }
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (_dragLeftIndex == null) return;
    final g = _geometry(size);
    final v = d.localPosition - g.center;
    final touch = math.atan2(v.dy, v.dx);
    final delta = _angleDiff(touch, _dragStartAngle);
    final deltaMin = (delta / (2 * math.pi) * g.denom).round();
    widget.onBoundaryDragUpdate?.call(deltaMin);
  }

  void _onPanEnd() {
    if (_dragLeftIndex == null) return;
    _dragLeftIndex = null;
    widget.onBoundaryDragEnd?.call();
  }

  /// Smallest signed angle a-b in (-π, π].
  double _angleDiff(double a, double b) {
    var d = a - b;
    while (d > math.pi) d -= 2 * math.pi;
    while (d < -math.pi) d += 2 * math.pi;
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 420.0);
        final dim = Size(size, size * 0.96);
        Widget paint = CustomPaint(
          size: dim,
          painter: _DonutPainter(
            segments: widget.segments,
            totalMin: widget.totalMin,
            centerLabel: widget.centerLabel,
            centerSub: _subLabel(l),
            labelFor: (def) => def.displayLabel(l),
            textDirection: Directionality.of(context),
            showHandles: _interactive,
            palette: context.c,
          ),
        );
        if (_interactive) {
          paint = GestureDetector(
            onPanStart: (d) => _onPanStart(d, dim),
            onPanUpdate: (d) => _onPanUpdate(d, dim),
            onPanEnd: (_) => _onPanEnd(),
            onPanCancel: _onPanEnd,
            child: paint,
          );
        }
        return Center(
          child: SizedBox(width: dim.width, height: dim.height, child: paint),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.totalMin,
    required this.centerLabel,
    required this.centerSub,
    required this.labelFor,
    required this.textDirection,
    required this.palette,
    this.showHandles = false,
  });

  final List<DonutSegment> segments;
  final int totalMin;
  final String centerLabel;
  final String centerSub;
  final String Function(CategoryDef) labelFor;
  final TextDirection textDirection;
  final AppPalette palette;
  final bool showHandles;

  static const double _ringWidth = 24;
  static const double _tickGap = 3;
  static const double _tickLen = 9;
  double _canvasWidth = 0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Leave room for outside labels.
    final radius = math.min(size.width, size.height) / 2 - 64;
    _canvasWidth = size.width;
    final ringRect = Rect.fromCircle(center: center, radius: radius);
    const startBase = -math.pi / 2; // 12 o'clock
    const full = 2 * math.pi;

    // Faint full-day track.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringWidth
      ..color = palette.surfaceAlt;
    canvas.drawArc(ringRect, 0, full, false, track);

    if (totalMin <= 0) {
      _drawCenter(canvas, center);
      return;
    }

    final denom = math.max(totalMin, 1440); // 24h reference
    double angle = startBase;
    final boundaries = <double>[];

    for (final seg in segments) {
      if (seg.minutes <= 0) continue;
      final sweep = (seg.minutes / denom) * full;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ringWidth
        ..strokeCap = StrokeCap.butt
        ..color = seg.def.color;
      canvas.drawArc(ringRect, angle, sweep, false, paint);
      boundaries.add(angle);
      // Label at mid-angle for segments big enough to read.
      if (seg.minutes >= 12) {
        _drawLabel(canvas, center, radius, angle + sweep / 2,
            labelFor(seg.def), formatDuration(seg.minutes), seg.def.color);
      }
      angle += sweep;
    }
    boundaries.add(angle); // final boundary

    // Division ticks reaching outward.
    final tickPaint = Paint()
      ..color = palette.inkFaint
      ..strokeWidth = 1.4;
    for (final b in boundaries) {
      final p1 = center + Offset(math.cos(b), math.sin(b)) * (radius + _ringWidth / 2 + _tickGap);
      final p2 = center + Offset(math.cos(b), math.sin(b)) * (radius + _ringWidth / 2 + _tickGap + _tickLen);
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Draggable handles on interior boundaries.
    if (showHandles && boundaries.length > 2) {
      final fill = Paint()..color = Colors.white;
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = palette.accentStrong;
      for (var i = 1; i < boundaries.length - 1; i++) {
        final c = center +
            Offset(math.cos(boundaries[i]), math.sin(boundaries[i])) * radius;
        canvas.drawCircle(c, 6, fill);
        canvas.drawCircle(c, 6, ring);
      }
    }

    _drawCenter(canvas, center);
  }

  void _drawCenter(Canvas canvas, Offset center) {
    final title = TextPainter(
      text: TextSpan(
        text: centerLabel,
        style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w700, color: palette.ink),
      ),
      textDirection: textDirection,
    )..layout();
    title.paint(canvas, center - Offset(title.width / 2, title.height / 2 + 8));

    final sub = TextPainter(
      text: TextSpan(
        text: centerSub,
        style: TextStyle(fontSize: 12.5, color: palette.inkSoft),
      ),
      textDirection: textDirection,
    )..layout();
    sub.paint(canvas, center - Offset(sub.width / 2, sub.height / 2 - 16));
  }

  void _drawLabel(Canvas canvas, Offset center, double radius, double mid,
      String name, String dur, Color color) {
    final dir = Offset(math.cos(mid), math.sin(mid));
    final anchor =
        center + dir * (radius + _ringWidth / 2 + _tickGap + _tickLen + 4);
    final onRight = math.cos(mid) >= 0;
    final align = onRight ? TextAlign.left : TextAlign.right;

    // Name over duration keeps each label narrow so it fits on phones.
    final tp = TextPainter(
      text: TextSpan(children: [
        TextSpan(
            text: name,
            style: TextStyle(
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color: palette.ink)),
        TextSpan(
            text: '\n$dur',
            style: TextStyle(
                fontSize: 10, height: 1.15, color: palette.inkSoft)),
      ]),
      textDirection: textDirection,
      textAlign: align,
    )..layout(maxWidth: 86);

    var dx = onRight ? anchor.dx : anchor.dx - tp.width;
    // Keep the label fully inside the canvas so nothing is clipped.
    dx = dx.clamp(4.0, math.max(4.0, _canvasWidth - tp.width - 4));
    final dy = anchor.dy - tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.totalMin != totalMin ||
      old.centerLabel != centerLabel ||
      old.centerSub != centerSub ||
      old.showHandles != showHandles ||
      old.palette != palette ||
      !_sameSegments(old.segments, segments);

  bool _sameSegments(List<DonutSegment> a, List<DonutSegment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].def.key != b[i].def.key ||
          a[i].def.color != b[i].def.color ||
          a[i].minutes != b[i].minutes) {
        return false;
      }
    }
    return true;
  }
}

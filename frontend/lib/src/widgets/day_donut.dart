import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../models/category.dart';
import '../theme.dart';
import '../util/time_utils.dart';

class DonutSegment {
  DonutSegment(this.category, this.minutes);
  final TimeCategory category;
  final int minutes;
}

/// Hollow 24h ring. Each category is an arc sized by its total minutes that
/// day; the unlogged remainder is a faint track. Division ticks reach outward
/// with a small tag naming each section.
class DayDonut extends StatelessWidget {
  const DayDonut({
    super.key,
    required this.segments,
    required this.totalMin,
    required this.centerLabel,
  });

  final List<DonutSegment> segments;
  final int totalMin;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 420.0);
        return Center(
          child: SizedBox(
            width: size,
            height: size * 0.96,
            child: CustomPaint(
              painter: _DonutPainter(
                segments: segments,
                totalMin: totalMin,
                centerLabel: centerLabel,
                centerSub: _subLabel(l),
                labelFor: (c) => c.label(l),
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        );
      },
    );
  }

  String _subLabel(AppL10n l) {
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return l.totalLogged(h, m);
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
  });

  final List<DonutSegment> segments;
  final int totalMin;
  final String centerLabel;
  final String centerSub;
  final String Function(TimeCategory) labelFor;
  final TextDirection textDirection;

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
      ..color = AppColors.surfaceAlt;
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
        ..color = seg.category.color;
      canvas.drawArc(ringRect, angle, sweep, false, paint);
      boundaries.add(angle);
      // Label at mid-angle for segments big enough to read.
      if (seg.minutes >= 12) {
        _drawLabel(canvas, center, radius, angle + sweep / 2,
            labelFor(seg.category), formatDuration(seg.minutes), seg.category.color);
      }
      angle += sweep;
    }
    boundaries.add(angle); // final boundary

    // Division ticks reaching outward.
    final tickPaint = Paint()
      ..color = AppColors.inkFaint
      ..strokeWidth = 1.4;
    for (final b in boundaries) {
      final p1 = center + Offset(math.cos(b), math.sin(b)) * (radius + _ringWidth / 2 + _tickGap);
      final p2 = center + Offset(math.cos(b), math.sin(b)) * (radius + _ringWidth / 2 + _tickGap + _tickLen);
      canvas.drawLine(p1, p2, tickPaint);
    }

    _drawCenter(canvas, center);
  }

  void _drawCenter(Canvas canvas, Offset center) {
    final title = TextPainter(
      text: TextSpan(
        text: centerLabel,
        style: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
      textDirection: textDirection,
    )..layout();
    title.paint(canvas, center - Offset(title.width / 2, title.height / 2 + 8));

    final sub = TextPainter(
      text: TextSpan(
        text: centerSub,
        style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
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
            style: const TextStyle(
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
        TextSpan(
            text: '\n$dur',
            style: const TextStyle(
                fontSize: 10, height: 1.15, color: AppColors.inkSoft)),
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
      !_sameSegments(old.segments, segments);

  bool _sameSegments(List<DonutSegment> a, List<DonutSegment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].category != b[i].category || a[i].minutes != b[i].minutes) {
        return false;
      }
    }
    return true;
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DonutSlice {
  const DonutSlice(this.value, this.color);
  final double value;
  final Color color;
}

/// Anneau de répartition, dessiné à l'apparition (balayage ease-out).
class Donut extends StatelessWidget {
  const Donut({
    super.key,
    required this.slices,
    this.size = 150,
    this.thickness = 18,
    this.center,
    this.highlight,
  });

  final List<DonutSlice> slices;
  final double size;
  final double thickness;
  final Widget? center;

  /// Index de la part mise en avant (les autres s'estompent).
  final int? highlight;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Motion.easeOut,
      builder: (context, t, child) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _DonutPainter(slices, thickness, t, highlight),
          child: Center(child: child),
        ),
      ),
      child: center,
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.thickness, this.t, this.highlight);

  final List<DonutSlice> slices;
  final double thickness;
  final double t;
  final int? highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, x) => s + x.value);
    if (total <= 0) return;
    final rect =
        Offset(thickness / 2, thickness / 2) &
        Size(size.width - thickness, size.height - thickness);
    const gap = 0.035;
    var start = -math.pi / 2;
    final sweepTotal = 2 * math.pi * t;
    for (var i = 0; i < slices.length; i++) {
      final s = slices[i];
      final sweep = (s.value / total) * sweepTotal;
      if (sweep <= gap) {
        start += sweep;
        continue;
      }
      final dim = highlight != null && highlight != i;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight == i ? thickness + 4 : thickness
        ..strokeCap = StrokeCap.round
        ..color = dim ? s.color.withValues(alpha: 0.25) : s.color;
      canvas.drawArc(rect, start + gap / 2, sweep - gap, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.t != t || old.highlight != highlight || old.slices != slices;
}

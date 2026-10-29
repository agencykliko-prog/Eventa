import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/eventa_colors.dart';

/// Histogramme simple avec étiquettes.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    this.height = 180,
    this.format,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    final hi = values.reduce(math.max);
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Motion.easeOut,
        builder: (context, t, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: Tooltip(
                  message:
                      '${labels[i]} · ${format?.call(values[i]) ?? values[i].toStringAsFixed(0)}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: (height - 22) * values[i] / hi * t,
                        decoration: BoxDecoration(
                          color: i == values.length - 1
                              ? color
                              : color.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        maxLines: 1,
                        style: context.text.labelSmall?.copyWith(
                          color: Confetti.inkFaint,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

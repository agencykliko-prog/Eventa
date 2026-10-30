import 'package:flutter/material.dart';

import '../theme/eventa_colors.dart';

/// Point qui pulse : donnée en temps réel.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.label = 'Direct'});

  final String label;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 12,
          // Redessin limité au point lui-même, sans reconstruction.
          child: RepaintBoundary(
            child: CustomPaint(painter: _PulsePainter(_c, Confetti.success)),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          widget.label,
          style: context.text.labelSmall?.copyWith(color: Confetti.success),
        ),
      ],
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.anim, this.color) : super(repaint: anim);
  final Animation<double> anim;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      3 + t * 3,
      Paint()..color = color.withValues(alpha: (1 - t) * 0.4),
    );
    canvas.drawCircle(c, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulsePainter old) =>
      old.anim != anim || old.color != color;
}

import 'package:flutter/material.dart';

import '../theme/eventa_colors.dart';

/// Monogramme Eventa : quatre confettis aux couleurs des modules
/// (tâches, budget, prestataires, équipe) sur une tuile encre.
class EventaMark extends StatelessWidget {
  const EventaMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final g = size * 0.1;
    Widget dot(Color c, double r) => Container(
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(size * r),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: Confetti.ink,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: dot(Confetti.violet, 0.2)),
                SizedBox(width: g),
                Expanded(child: dot(Confetti.lagoon, 0.06)),
              ],
            ),
          ),
          SizedBox(height: g),
          Expanded(
            child: Row(
              children: [
                Expanded(child: dot(Confetti.mango, 0.06)),
                SizedBox(width: g),
                Expanded(child: dot(Confetti.coral, 0.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EventaWordmark extends StatelessWidget {
  const EventaWordmark({super.key, this.size = 22, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EventaMark(size: size * 1.25),
        SizedBox(width: size * 0.4),
        Text(
          'eventa',
          style: TextStyle(
            fontFamily: 'RedHatDisplay',
            fontSize: size,
            fontWeight: FontWeight.w700,
            letterSpacing: -size * 0.05,
            color: color ?? Confetti.ink,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// Drapeau ivoirien dessiné (pas d'emoji).
class CiFlag extends StatelessWidget {
  const CiFlag({super.key, this.width = 22});

  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: width,
        height: width * 2 / 3,
        child: const Row(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFFF77F00))),
            Expanded(child: ColoredBox(color: Colors.white)),
            Expanded(child: ColoredBox(color: Color(0xFF009E60))),
          ],
        ),
      ),
    );
  }
}

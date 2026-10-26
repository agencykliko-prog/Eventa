import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/eventa_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/ui.dart';
import '../../../events/domain/models.dart';

/// Carte budget. Hiérarchie : le budget total d'abord, en grand ; puis
/// l'allocation (payé, engagé, disponible) sur une seule barre.
class BudgetOverview extends StatelessWidget {
  const BudgetOverview({
    super.key,
    required this.event,
    this.onTap,
    this.onEditTarget,
  });

  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onEditTarget;

  @override
  Widget build(BuildContext context) {
    final c = context.eventa.budget;
    final over = event.committed > event.targetBudget;
    return Panel(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Budget total',
                style: context.text.labelMedium?.copyWith(
                  color: Confetti.inkMuted,
                ),
              ),
              const Spacer(),
              if (onEditTarget != null)
                Pressable(
                  onTap: onEditTarget,
                  semanticLabel: 'Modifier le budget total',
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.edit,
                        size: 14,
                        color: Confetti.coralDeep,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Modifier',
                        style: context.text.labelMedium?.copyWith(
                          color: Confetti.coralDeep,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: fcfa(event.targetBudget).replaceAll(' FCFA', ''),
                style: context.text.displaySmall?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                children: [
                  TextSpan(
                    text: ' FCFA',
                    style: context.text.titleMedium?.copyWith(
                      color: Confetti.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          BudgetBar(event: event),
          const SizedBox(height: 14),
          Row(
            children: [
              _Figure(color: c.deep, label: 'Dépensé', value: event.paid),
              _Figure(color: c.base, label: 'Engagé', value: event.committed),
              _Figure(
                color: over ? Confetti.danger : const Color(0xFFD9D4E4),
                label: over ? 'Dépassement' : 'Disponible',
                value: event.available.abs(),
                strong: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.color,
    required this.label,
    required this.value,
    this.strong = false,
  });

  final Color color;
  final String label;
  final int value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.text.labelSmall?.copyWith(
                  color: Confetti.inkMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            fcfaCompact(value),
            style: (strong ? context.text.titleMedium : context.text.titleSmall)
                ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

/// Barre unique : dépensé (foncé), engagé non payé (moyen), le reste vide.
class BudgetBar extends StatelessWidget {
  const BudgetBar({super.key, required this.event, this.height = 10});

  final Event event;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.eventa.budget;
    final scale = math.max(event.targetBudget, event.committed).toDouble();
    final paid = scale == 0 ? 0.0 : event.paid / scale;
    final committed = scale == 0 ? 0.0 : event.committed / scale;
    final over = event.committed > event.targetBudget;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Motion.easeOut,
      builder: (context, t, _) => LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          return ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Confetti.lavender),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: w * committed * t,
                    child: ColoredBox(color: over ? Confetti.danger : c.base),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: w * paid * t,
                    child: ColoredBox(color: c.deep),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/widgets/ui.dart';

/// Page d'une section de l'espace pro : retour, titre, description.
class ProPage extends StatelessWidget {
  const ProPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.action,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Bouton rond en haut à droite (ajout, export…).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.home),
                ),
                const Spacer(),
                ?action,
              ],
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: context.text.bodyMedium?.copyWith(
                      color: Confetti.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Indicateur compact : valeur et libellé, teinte de module.
class ProStat extends StatelessWidget {
  const ProStat({
    super.key,
    required this.label,
    required this.value,
    required this.hue,
    this.icon,
    this.caption,
  });

  final String label;
  final String value;
  final Hue hue;
  final IconData? icon;
  final String? caption;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          IconTile(icon: icon!, hue: hue, size: 32),
          const SizedBox(height: 10),
        ],
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Text(
          label,
          maxLines: 2,
          style: context.text.labelSmall?.copyWith(
            color: Confetti.inkMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            style: context.text.labelSmall?.copyWith(color: hue.text),
          ),
      ],
    ),
  );
}

/// Grille d'indicateurs : 2 colonnes sur mobile, 4 au-delà.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final n = box.maxWidth >= 600 ? 4 : 2;
      final w = (box.maxWidth - 8 * (n - 1)) / n;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    },
  );
}

/// Ligne « libellé : valeur » des fiches de détail.
class InfoLine extends StatelessWidget {
  const InfoLine(this.label, this.value, {super.key, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: context.text.bodyMedium?.copyWith(color: Confetti.inkMuted),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: strong ? context.text.titleMedium : context.text.titleSmall,
          ),
        ),
      ],
    ),
  );
}

/// Petite pastille d'accent « en attente » pour les compteurs.
String plural(int n, String one, String many) => (n > 1 ? many : one).trf([n]);

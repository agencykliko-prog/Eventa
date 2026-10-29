import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/ui.dart';

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

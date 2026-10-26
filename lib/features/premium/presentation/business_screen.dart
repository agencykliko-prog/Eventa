import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/ui.dart';
import '../../commerce/data/catalog.dart';

/// Offre SaaS indépendante pour les professionnels, et espaces sponsorisés.
class BusinessScreen extends StatelessWidget {
  const BusinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  onTap: () => context.pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            NightPanel(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Tag(
                    label: 'Business / Creator',
                    hue: Hue.gold,
                    solid: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Votre agence événementielle, dans une seule app.',
                    style: context.text.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Clients, devis, contrats, facturation et équipe. En marque blanche, '
                    'avec API et automatisations.',
                    style: context.text.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text.rich(
                    TextSpan(
                      text: 'À partir de ',
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                      children: [
                        TextSpan(
                          text: '29 900 FCFA',
                          style: context.text.headlineSmall?.copyWith(
                            color: Confetti.gold,
                          ),
                        ),
                        const TextSpan(text: ' / mois'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PillButton(
                    label: 'Demander une démo',
                    tone: ButtonTone.gold,
                    trailingIcon: AppIcons.forward,
                    onPressed: () => toast(
                      context,
                      'Demande envoyée, un conseiller vous rappelle sous 24 h',
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Pour qui'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in Catalog.businessAudience)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Confetti.line),
                    ),
                    child: Text(a, style: context.text.labelMedium),
                  ),
              ],
            ),
            const SectionTitle('Tout est inclus'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              padding: EdgeInsets.zero,
              children: [
                for (final (i, (icon, label))
                    in Catalog.businessFeatures.indexed)
                  Entrance(
                    index: i,
                    child: Panel(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      radius: 16,
                      child: Row(
                        children: [
                          IconTile(icon: icon, hue: Hue.violet, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: context.text.labelMedium,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SectionTitle('Publicité Premium'),
            Text(
              'Réservée aux professionnels : gagnez en visibilité auprès des '
              'organisateurs qui préparent leur événement.',
              style: context.text.bodyMedium?.copyWith(
                color: context.eventa.muted,
              ),
            ),
            const SizedBox(height: 14),
            for (final (s, desc) in Catalog.adFormats)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const IconTile(
                        icon: AppIcons.megaphone,
                        hue: Hue.mango,
                        size: 40,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.label, style: context.text.titleSmall),
                            const SizedBox(height: 2),
                            Text(desc, style: context.text.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            PillButton(
              label: 'Booster ma visibilité',
              icon: AppIcons.rocket,
              tone: ButtonTone.dark,
              onPressed: () => toast(
                context,
                'Un conseiller Publicité vous contacte bientôt',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

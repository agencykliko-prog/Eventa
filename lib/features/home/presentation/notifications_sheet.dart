import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/widgets/ui.dart';
import '../../auth/presentation/session_provider.dart';

Future<void> showNotificationsSheet(BuildContext context) =>
    showEventaSheet<void>(context, builder: (_) => const _Notifications());

class _Notifications extends ConsumerWidget {
  const _Notifications();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creator = ref.watch(profileProvider).isCreator;
    final items = creator
        ? [
            (
              AppIcons.inbox,
              Hue.mango,
              'Nouvelle demande de devis'.tr,
              'Awa Traoré · Mariage du 7 déc.'.tr,
              'il y a 35 min'.tr,
            ),
            (
              AppIcons.checkCircle,
              Hue.lagoon,
              'Prestation confirmée'.tr,
              'Baby shower de Mariam · acompte reçu'.tr,
              'hier',
            ),
            (
              AppIcons.star,
              Hue.violet,
              'Nouvel avis 5 étoiles'.tr,
              'Fondation Lumière'.tr,
              'il y a 3 j'.tr,
            ),
          ]
        : [
            (
              AppIcons.file,
              Hue.mango,
              'Devis reçu'.tr,
              'Studio Lumière · valable 7 jours'.tr,
              'il y a 1 h'.tr,
            ),
            (
              AppIcons.coins,
              Hue.lagoon,
              'Paiement à venir'.tr,
              'Solde Lagune Sound demain'.tr,
              'il y a 3 h'.tr,
            ),
            (
              AppIcons.guests,
              Hue.coral,
              '+8 réponses RSVP'.tr,
              'Mariage Awa & Kouassi'.tr,
              'aujourd’hui'.tr,
            ),
            (
              AppIcons.reminder,
              Hue.violet,
              'Rappel'.tr,
              'Valider le menu de dégustation à 11:00'.tr,
              'aujourd’hui'.tr,
            ),
          ];
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Text('Notifications'.tr, style: context.text.headlineSmall),
        const SizedBox(height: 12),
        for (final (i, (icon, hue, title, caption, ago)) in items.indexed) ...[
          if (i > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                IconTile(icon: icon, hue: hue, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.titleSmall),
                      Text(caption, style: context.text.bodySmall),
                    ],
                  ),
                ),
                Text(
                  ago,
                  style: context.text.labelSmall?.copyWith(
                    color: Confetti.inkFaint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

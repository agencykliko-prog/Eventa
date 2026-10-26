import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ui.dart';
import '../../commerce/data/catalog.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/presentation/payment_sheet.dart';

/// Exécute [onUnlocked] si la fonctionnalité est débloquée, sinon ouvre
/// le paywall. Après souscription, l'action reprend d'elle-même.
Future<void> requirePremium(
  BuildContext context,
  WidgetRef ref, {
  required PremiumFeature feature,
  String? eventId,
  required VoidCallback onUnlocked,
}) async {
  if (ref.read(featureUnlockedProvider((feature, eventId)))) {
    onUnlocked();
    return;
  }
  final ok = await showEventaSheet<bool>(
    context,
    dark: true,
    builder: (_) => _Paywall(feature: feature),
  );
  if (ok == true && context.mounted) onUnlocked();
}

class _Paywall extends ConsumerWidget {
  const _Paywall({required this.feature});

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = feature.minPlan;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Confetti.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(feature.icon, color: Confetti.gold, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            feature.label,
            style: context.text.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Disponible dès l’abonnement ${plan.label}. Sans engagement, '
            'résiliable à tout moment.',
            style: context.text.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          for (final f in Catalog.planFeatures[plan]!)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.checkCircle,
                    size: 18,
                    color: Confetti.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: context.text.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          PillButton(
            label: 'Passer à ${plan.label} · ${fcfa(plan.price)}/mois',
            tone: ButtonTone.gold,
            onPressed: () async {
              final r = await showPaymentSheet(
                context,
                title: 'Abonnement ${plan.label}',
                payee: 'Eventa',
                options: [PayOption('Mensuel', plan.price)],
                onPay: (amount, method) {
                  ref.read(planProvider.notifier).subscribe(plan);
                  return Receipt(
                    ref: receiptRef(),
                    label: 'Abonnement ${plan.label}',
                    amount: amount,
                    method: method,
                    date: DateTime.now(),
                    payee: 'Eventa',
                  );
                },
              );
              if (r != null && context.mounted) Navigator.of(context).pop(true);
            },
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                context.push(Routes.premium);
              },
              child: Text(
                'Comparer les offres et les packs',
                style: context.text.labelMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

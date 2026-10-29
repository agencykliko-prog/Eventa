import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/data/catalog.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/presentation/payment_sheet.dart';

/// Abonnements Organisateur : Azur, Signature, Privilège.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  Receipt _receipt(String label, int amount, PayMethod m) => Receipt(
    ref: receiptRef(),
    label: label,
    amount: amount,
    method: m,
    date: DateTime.now(),
    payee: 'Calandix'.tr,
  );

  Future<void> _subscribe(Plan p) async {
    final r = await showPaymentSheet(
      context,
      title: 'Abonnement {0}'.trf([p.label]),
      payee: 'Calandix'.tr,
      options: [PayOption('Mensuel'.tr, p.price)],
      onPay: (amount, m) {
        ref.read(planProvider.notifier).subscribe(p);
        return _receipt('Abonnement {0}'.trf([p.label]), amount, m);
      },
    );
    if (r != null && mounted) {
      toast(context, 'Bienvenue dans {0}'.trf([p.label]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Confetti.ink,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: AppIcons.close,
                      background: Confetti.night,
                      foreground: Colors.white,
                      tooltip: 'Fermer',
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    PremiumBadge(label: 'Calandix Premium'.tr, onDark: true),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organisez comme\nun professionnel.'.tr,
                      style: context.text.displaySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'IA, coffre-fort, collaboration illimitée. Sans engagement, résiliable à tout moment.'
                          .tr,
                      style: context.text.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              sliver: SliverToBoxAdapter(child: _plans()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _plans() {
    final current = ref.watch(planProvider);
    return Column(
      key: const ValueKey('plans'),
      children: [
        for (final (i, p) in [
          Plan.azur,
          Plan.signature,
          Plan.privilege,
        ].indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Entrance(
              index: i,
              child: _PlanCard(
                plan: p,
                current: current == p,
                highlight: p == Plan.signature,
                onTap: current == p ? null : () => _subscribe(p),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.current,
    required this.highlight,
    required this.onTap,
  });

  final Plan plan;
  final bool current;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final features = Catalog.planFeatures[plan]!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight ? Colors.white : Confetti.night,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight ? Colors.white : Confetti.nightLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: plan.hue.base,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                plan.label.toUpperCase(),
                style: context.text.labelMedium?.copyWith(
                  letterSpacing: 1.2,
                  color: highlight ? Confetti.inkFixed : Colors.white,
                ),
              ),
              const Spacer(),
              if (highlight && !current)
                Tag(label: 'Le plus choisi'.tr, hue: Hue.coral, solid: true),
              if (current)
                Tag(label: 'Votre offre'.tr, hue: Hue.lagoon, solid: true),
            ],
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              text: fcfa(plan.price).replaceAll(' FCFA', ''),
              style: context.text.headlineMedium?.copyWith(
                color: highlight ? Confetti.inkFixed : Colors.white,
              ),
              children: [
                TextSpan(
                  text: '  FCFA / mois'.tr,
                  style: context.text.bodySmall?.copyWith(
                    color: highlight ? const Color(0xFF645A7C) : Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    AppIcons.check,
                    size: 16,
                    color: highlight ? Confetti.coral : Confetti.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f.tr,
                      style: context.text.bodyMedium?.copyWith(
                        color: highlight
                            ? Confetti.inkFixed
                            : Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          PillButton(
            label: current
                ? 'Offre active'.tr
                : 'Choisir {0}'.trf([plan.label]),
            tone: highlight ? ButtonTone.primary : ButtonTone.light,
            height: 48,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

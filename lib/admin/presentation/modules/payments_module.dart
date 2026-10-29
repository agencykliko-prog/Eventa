import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/ui.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Paiements : transactions, commissions, remboursements, rapprochements.
class PaymentsModule extends ConsumerStatefulWidget {
  const PaymentsModule({super.key});

  @override
  ConsumerState<PaymentsModule> createState() => _PaymentsModuleState();
}

class _PaymentsModuleState extends ConsumerState<PaymentsModule> {
  TxKind? _kind;
  TxStatus? _status;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(adminProvider);
    final txs = s.transactions;
    final list = txs
        .where((t) => _kind == null || t.kind == _kind)
        .where((t) => _status == null || t.status == _status)
        .take(40)
        .toList();
    final pending = txs.where((t) => !t.reconciled).length;
    final byMethod = <String, int>{};
    for (final t in txs.where(
      (t) => t.kind == TxKind.payment && t.status == TxStatus.success,
    )) {
      byMethod[t.method] = (byMethod[t.method] ?? 0) + t.amount;
    }
    final methods = byMethod.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(
          title: 'Paiements',
          subtitle: 'Transactions en temps réel, commissions, remboursements et rapprochement avec les opérateurs.',
          actions: [
            AdminButton(
              label: 'Rapprocher ($pending)',
              icon: AppIcons.checkCircle,
              onPressed: pending == 0
                  ? null
                  : () {
                      if (!guard(context, ref, AdminPermission.payments)) {
                        return;
                      }
                      ref.read(adminProvider.notifier).reconcileAll();
                      toast(
                        context,
                        'Relevés Wave, Orange, MTN, Moov et cartes rapprochés',
                      );
                    },
            ),
          ],
        ),
        ResponsiveGrid(
          minTile: 200,
          children: [
            KpiCard(
              icon: AppIcons.coins,
              hue: Hue.lagoon,
              label: 'Volume du jour',
              value: fcfa(s.volumeToday),
              caption: 'Paiements et abonnements réussis',
              live: true,
            ),
            KpiCard(
              icon: AppIcons.chartUp,
              hue: Hue.gold,
              label: 'Commissions du jour',
              value: fcfa(s.revenueToday),
              caption: 'Nettes des remboursements',
            ),
            KpiCard(
              icon: AppIcons.refresh,
              hue: Hue.coral,
              label: 'Remboursements',
              value: fcfa(s.refundsToday),
              caption: 'Aujourd’hui',
            ),
            KpiCard(
              icon: AppIcons.timer,
              hue: pending > 5 ? Hue.mango : Hue.violet,
              label: 'À rapprocher',
              value: '$pending',
              caption:
                  '${txs.where((t) => t.status == TxStatus.failed).length} échecs à relancer',
            ),
          ],
        ),
        const BlockTitle('Répartition par moyen de paiement'),
        Panel(
          child: Column(
            children: [
              for (final e in methods)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(e.key, style: context.text.titleSmall),
                      ),
                      Expanded(
                        child: Meter(
                          value: e.value / methods.first.value,
                          color: Confetti.violet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        child: Text(
                          fcfaCompact(e.value),
                          textAlign: TextAlign.right,
                          style: context.text.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        BlockTitle('Transactions', trailing: const LiveDot()),
        FilterChips<TxKind>(
          values: const [null, ...TxKind.values],
          selected: _kind,
          labelOf: (k) => k?.label ?? 'Tous types',
          onChanged: (k) => setState(() => _kind = k),
        ),
        const SizedBox(height: 8),
        FilterChips<TxStatus>(
          values: const [null, ...TxStatus.values],
          selected: _status,
          labelOf: (k) => k?.label ?? 'Tous statuts',
          counts: (k) => txs.where((t) => k == null || t.status == k).length,
          onChanged: (k) => setState(() => _status = k),
        ),
        const SizedBox(height: 12),
        AdminTable(
          columns: const [
            AdminColumn('Transaction', flex: 4),
            AdminColumn('Moyen'),
            AdminColumn('Montant', numeric: true),
            AdminColumn('Commission', numeric: true),
            AdminColumn('Statut', numeric: true),
          ],
          rows: [
            for (final t in list)
              [
                TwoLines(
                  '${t.kind.label} · ${t.party}',
                  '${t.ref} · ${timeOf(t.at)}${t.reconciled ? ' · rapproché' : ''}',
                ),
                Text(t.method, style: context.text.bodyMedium),
                Text(
                  fcfa(t.amount),
                  style: context.text.titleSmall?.copyWith(
                    color: t.amount < 0 ? Confetti.danger : null,
                  ),
                ),
                Text(fcfa(t.commission), style: context.text.bodyMedium),
                StatusPill(t.status.label, hueOf(t.status)),
              ],
          ],
          onTap: (i) => _detail(context, list[i]),
        ),
      ],
    );
  }

  void _detail(BuildContext context, Transaction t) {
    showEventaSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(t.ref, style: ctx.text.headlineSmall)),
                StatusPill(t.status.label, hueOf(t.status)),
              ],
            ),
            const SizedBox(height: 10),
            for (final (k, v) in [
              ('Type', t.kind.label),
              ('Partie', t.party),
              ('Moyen', t.method),
              ('Date', '${mediumDate(t.at)} · ${timeOf(t.at)}'),
              ('Montant', fcfa(t.amount)),
              ('Part plateforme', fcfa(t.commission)),
              ('Rapprochement', t.reconciled ? 'Rapproché' : 'En attente'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(k, style: ctx.text.bodySmall),
                    ),
                    Expanded(child: Text(v, style: ctx.text.titleSmall)),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            if (t.status == TxStatus.failed)
              AdminButton(
                label: 'Relancer le paiement',
                icon: AppIcons.refresh,
                onPressed: () {
                  if (!guard(ctx, ref, AdminPermission.payments)) return;
                  ref.read(adminProvider.notifier).retry(t.ref);
                  Navigator.of(ctx).pop();
                  toast(context, 'Paiement ${t.ref} relancé avec succès');
                },
              )
            else if (t.status == TxStatus.success &&
                (t.kind == TxKind.payment || t.kind == TxKind.subscription))
              AdminButton(
                label: 'Rembourser ${fcfa(t.amount)}',
                icon: AppIcons.refresh,
                tone: ButtonTone.primary,
                onPressed: () {
                  if (!guard(ctx, ref, AdminPermission.payments)) return;
                  ref.read(adminProvider.notifier).refund(t.ref);
                  Navigator.of(ctx).pop();
                  toast(context, 'Remboursement émis vers ${t.method}');
                },
              ),
          ],
        ),
      ),
    );
  }
}

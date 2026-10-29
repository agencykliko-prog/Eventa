import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/ui.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Réservations : commandes, changements, annulations et litiges.
class BookingsModule extends ConsumerStatefulWidget {
  const BookingsModule({super.key});

  @override
  ConsumerState<BookingsModule> createState() => _BookingsModuleState();
}

class _BookingsModuleState extends ConsumerState<BookingsModule> {
  OrderStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(adminProvider).orders;
    final list = orders
        .where((o) => _filter == null || o.status == _filter)
        .toList();
    int count(OrderStatus s) => orders.where((o) => o.status == s).length;
    final active = orders
        .where(
          (o) =>
              o.status == OrderStatus.confirmed ||
              o.status == OrderStatus.changed,
        )
        .fold(0, (s, o) => s + o.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminHeader(
          title: 'Réservations',
          subtitle: 'Suivi des commandes entre organisateurs et prestataires, des changements, annulations et litiges.',
        ),
        ResponsiveGrid(
          minTile: 200,
          children: [
            KpiCard(
              icon: AppIcons.calendarCheck,
              hue: Hue.lagoon,
              label: 'En cours',
              value: fcfa(active),
              caption:
                  '${count(OrderStatus.confirmed) + count(OrderStatus.changed)} réservations',
            ),
            KpiCard(
              icon: AppIcons.warning,
              hue: Hue.coral,
              label: 'Litiges ouverts',
              value: '${count(OrderStatus.dispute)}',
              caption: 'Délai cible de résolution : 72 h',
              onTap: () => setState(() => _filter = OrderStatus.dispute),
            ),
            KpiCard(
              icon: AppIcons.edit,
              hue: Hue.mango,
              label: 'Modifiées',
              value: '${count(OrderStatus.changed)}',
              caption: 'Changement de date, de volume ou d’options',
            ),
            KpiCard(
              icon: AppIcons.close,
              hue: Hue.ink,
              label: 'Taux d’annulation',
              value:
                  '${(count(OrderStatus.cancelled) / orders.length * 100).toStringAsFixed(0)} %',
              caption: 'Sur les réservations de la période',
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilterChips<OrderStatus>(
          values: const [null, ...OrderStatus.values],
          selected: _filter,
          labelOf: (s) => s?.label ?? 'Toutes',
          counts: (s) => s == null ? orders.length : count(s),
          onChanged: (s) => setState(() => _filter = s),
        ),
        const SizedBox(height: 12),
        AdminTable(
          columns: const [
            AdminColumn('Réservation', flex: 4),
            AdminColumn('Client → prestataire', flex: 4),
            AdminColumn('Date'),
            AdminColumn('Montant', numeric: true),
            AdminColumn('Statut', numeric: true),
          ],
          rows: [
            for (final o in list)
              [
                TwoLines(o.ref, o.event),
                TwoLines(o.client, o.vendor),
                Text(mediumDate(o.date), style: context.text.bodyMedium),
                Text(fcfa(o.amount), style: context.text.titleSmall),
                StatusPill(o.status.label, hueOf(o.status)),
              ],
          ],
          onTap: (i) => _detail(context, list[i]),
          empty: 'Aucune réservation dans ce filtre',
        ),
      ],
    );
  }

  void _detail(BuildContext context, Order o) {
    showEventaSheet<void>(
      context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Row(
            children: [
              Expanded(child: Text(o.ref, style: ctx.text.headlineSmall)),
              StatusPill(o.status.label, hueOf(o.status)),
            ],
          ),
          Text('${o.event} · ${mediumDate(o.date)}', style: ctx.text.bodySmall),
          const SizedBox(height: 12),
          Text(
            '${o.client} → ${o.vendor} · ${fcfa(o.amount)}',
            style: ctx.text.titleSmall,
          ),
          if (o.dispute != null && o.status == OrderStatus.dispute) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Confetti.coralTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Litige : ${o.dispute}',
                style: ctx.text.bodyMedium?.copyWith(color: Confetti.coralDeep),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text('Historique', style: ctx.text.titleSmall),
          const SizedBox(height: 6),
          for (final h in ['Réservation créée', ...o.history])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 10),
                    child: Icon(
                      AppIcons.checkCircle,
                      size: 12,
                      color: Confetti.inkFaint,
                    ),
                  ),
                  Expanded(child: Text(h, style: ctx.text.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: 14),
          if (o.status == OrderStatus.dispute)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, pct) in [
                  ('Rembourser 100 %', 100),
                  ('Rembourser 50 %', 50),
                  ('Clore sans remboursement', 0),
                ])
                  AdminButton(
                    label: label,
                    tone: pct == 100 ? ButtonTone.primary : ButtonTone.ghost,
                    onPressed: () {
                      if (!guard(ctx, ref, AdminPermission.bookings)) return;
                      ref
                          .read(adminProvider.notifier)
                          .resolveDispute(o.ref, refundPercent: pct);
                      Navigator.of(ctx).pop();
                      toast(
                        context,
                        'Litige ${o.ref} résolu, les deux parties sont prévenues',
                      );
                    },
                  ),
              ],
            )
          else if (o.status == OrderStatus.confirmed ||
              o.status == OrderStatus.changed)
            AdminButton(
              label: 'Annuler la réservation',
              icon: AppIcons.close,
              tone: ButtonTone.ghost,
              onPressed: () {
                if (!guard(ctx, ref, AdminPermission.bookings)) return;
                ref.read(adminProvider.notifier).cancelOrder(o.ref);
                Navigator.of(ctx).pop();
                toast(context, 'Réservation ${o.ref} annulée');
              },
            ),
        ],
      ),
    );
  }
}

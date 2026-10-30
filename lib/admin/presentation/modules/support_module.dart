import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/ui.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';
import '../../../ui/dataviz/dataviz.dart';

/// Service client : tickets, attribution et suivi de résolution.
class SupportModule extends ConsumerStatefulWidget {
  const SupportModule({super.key});

  @override
  ConsumerState<SupportModule> createState() => _SupportModuleState();
}

class _SupportModuleState extends ConsumerState<SupportModule> {
  TicketStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(adminProvider);
    final tickets = s.tickets;
    final list =
        tickets.where((t) => _filter == null || t.status == _filter).toList()
          ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    final open = tickets.where((t) => t.status != TicketStatus.resolved);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminHeader(
          title: 'Service client',
          subtitle: 'Demandes reçues par WhatsApp, e-mail, téléphone et dans l’app. Attribuez, répondez, suivez la résolution.',
        ),
        KpiGrid(
          minTile: 200,
          children: [
            KpiCard(
              icon: AppIcons.inbox,
              hue: Hue.violet,
              label: 'Tickets ouverts',
              value: '${open.length}',
              caption:
                  '${open.where((t) => t.assignee == null).length} non attribués',
            ),
            KpiCard(
              icon: AppIcons.warning,
              hue: Hue.coral,
              label: 'Urgents',
              value:
                  '${open.where((t) => t.priority == TicketPriority.urgent).length}',
              caption: 'Réponse attendue sous 1 h',
            ),
            KpiCard(
              icon: AppIcons.timer,
              hue: Hue.lagoon,
              label: 'Première réponse',
              value: '42 min',
              caption: 'Médiane sur 7 jours',
              trend: -8.0,
            ),
            KpiCard(
              icon: AppIcons.star,
              hue: Hue.gold,
              label: 'Satisfaction',
              value: '4,6 / 5',
              caption: 'Après résolution',
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilterChips<TicketStatus>(
          values: const [null, ...TicketStatus.values],
          selected: _filter,
          labelOf: (v) => v?.label ?? 'Tous',
          counts: (v) =>
              tickets.where((t) => v == null || t.status == v).length,
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 12),
        AdminTable(
          columns: const [
            AdminColumn('Ticket', flex: 4),
            AdminColumn('Priorité'),
            AdminColumn('Canal'),
            AdminColumn('Attribué à', flex: 2),
            AdminColumn('Statut', numeric: true),
          ],
          rows: [
            for (final t in list)
              [
                TwoLines(
                  t.subject,
                  '${t.id} · ${t.from} · ${since(t.created)}',
                ),
                StatusPill(t.priority.label, hueOf(t.priority)),
                Text(t.channel, style: context.text.bodyMedium),
                Text(
                  t.assignee ?? 'Non attribué',
                  style: context.text.bodyMedium?.copyWith(
                    color: t.assignee == null ? Confetti.danger : null,
                  ),
                ),
                StatusPill(t.status.label, hueOf(t.status)),
              ],
          ],
          onTap: (i) => _detail(context, list[i].id),
        ),
      ],
    );
  }

  void _detail(BuildContext context, String id) {
    final reply = TextEditingController();
    showEventaSheet<void>(
      context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final s = ref.watch(adminProvider);
          final t = s.tickets.firstWhere((x) => x.id == id);
          final n = ref.read(adminProvider.notifier);
          final agents = s.team
              .where(
                (m) =>
                    s.permissions[m.role]?.contains(AdminPermission.support) ??
                    false,
              )
              .toList();
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(t.subject, style: ctx.text.headlineSmall),
                  ),
                  StatusPill(t.status.label, hueOf(t.status)),
                ],
              ),
              Text(
                '${t.id} · ${t.from} · ${t.channel} · priorité ${t.priority.label.toLowerCase()}',
                style: ctx.text.bodySmall,
              ),
              const SizedBox(height: 14),
              for (final (i, m) in t.messages.indexed)
                Align(
                  alignment: i.isEven
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: i.isEven ? Confetti.lavender : Confetti.ink,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      m,
                      style: ctx.text.bodyMedium?.copyWith(
                        color: i.isEven ? Confetti.ink : Confetti.onInk,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              const FieldLabel('Attribuer à'),
              FilterChips<String>(
                values: [for (final a in agents) a.name],
                selected: t.assignee,
                labelOf: (v) => v!,
                onChanged: (v) {
                  if (guard(ctx, ref, AdminPermission.support)) {
                    n.assign(t.id, v!);
                  }
                },
              ),
              if (t.status != TicketStatus.resolved) ...[
                const SizedBox(height: 14),
                AppField(
                  label: 'Réponse',
                  controller: reply,
                  hint: 'Votre message au client…',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminButton(
                      label: 'Répondre',
                      icon: AppIcons.send,
                      tone: ButtonTone.ghost,
                      onPressed: () {
                        if (!guard(ctx, ref, AdminPermission.support)) return;
                        if (reply.text.trim().isEmpty) return;
                        n.reply(t.id, reply.text.trim());
                        reply.clear();
                      },
                    ),
                    AdminButton(
                      label: 'Répondre et résoudre',
                      icon: AppIcons.checkCircle,
                      onPressed: () {
                        if (!guard(ctx, ref, AdminPermission.support)) return;
                        n.reply(
                          t.id,
                          reply.text.trim().isEmpty
                              ? 'Votre demande est résolue. Merci de votre confiance !'
                              : reply.text.trim(),
                          resolve: true,
                        );
                        Navigator.of(ctx).pop();
                        toast(context, 'Ticket ${t.id} résolu');
                      },
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

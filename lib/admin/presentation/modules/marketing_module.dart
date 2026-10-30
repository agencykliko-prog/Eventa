import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/ui.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';
import '../../../ui/dataviz/dataviz.dart';

/// Marketing & fidélisation : codes promo, campagnes, parrainage, notifications.
class MarketingModule extends ConsumerWidget {
  const MarketingModule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(adminProvider);
    final n = ref.read(adminProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(
          title: 'Marketing & fidélisation',
          subtitle: 'Codes promotionnels, campagnes multicanal, parrainage et notifications.',
          actions: [
            AdminButton(
              label: 'Code promo',
              icon: AppIcons.add,
              tone: ButtonTone.ghost,
              onPressed: () {
                if (guard(context, ref, AdminPermission.marketing)) {
                  _newPromo(context, ref);
                }
              },
            ),
            AdminButton(
              label: 'Nouvelle campagne',
              icon: AppIcons.megaphone,
              onPressed: () {
                if (guard(context, ref, AdminPermission.marketing)) {
                  _newCampaign(context, ref);
                }
              },
            ),
          ],
        ),
        KpiGrid(
          minTile: 200,
          children: [
            KpiCard(
              icon: AppIcons.ticket,
              hue: Hue.coral,
              label: 'Codes utilisés',
              value: '${s.promos.fold(0, (a, p) => a + p.uses)}',
              caption: '${s.promos.where((p) => p.active).length} codes actifs',
            ),
            KpiCard(
              icon: AppIcons.megaphone,
              hue: Hue.violet,
              label: 'Messages envoyés',
              value: '${s.campaigns.fold(0, (a, c) => a + c.sent)}',
              caption: 'Toutes campagnes confondues',
            ),
            KpiCard(
              icon: AppIcons.userPlus,
              hue: Hue.lagoon,
              label: 'Parrainages',
              value: '386',
              caption: '5 000 FCFA offerts au parrain et au filleul',
              trend: 18.4,
            ),
            KpiCard(
              icon: AppIcons.chartUp,
              hue: Hue.gold,
              label: 'Conversions',
              value: '${s.campaigns.fold(0, (a, c) => a + c.conversions)}',
              caption: 'Réservations ou abonnements attribués',
            ),
          ],
        ),
        const BlockTitle('Codes promotionnels'),
        AdminTable(
          columns: const [
            AdminColumn('Code', flex: 3),
            AdminColumn('Remise'),
            AdminColumn('Utilisation', flex: 3),
            AdminColumn('Expire'),
            AdminColumn('Actif', numeric: true),
          ],
          rows: [
            for (final p in s.promos)
              [
                TwoLines(p.code, p.label),
                Text('-${p.percent} %', style: context.text.titleSmall),
                Row(
                  children: [
                    Expanded(
                      child: Meter(
                        value: p.uses / p.limit,
                        color: Confetti.coral,
                        height: 6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${p.uses}/${p.limit}',
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
                Text(mediumDate(p.expires), style: context.text.bodySmall),
                Switch(
                  value: p.active,
                  onChanged: (_) {
                    if (guard(context, ref, AdminPermission.marketing)) {
                      n.togglePromo(p.code);
                    }
                  },
                ),
              ],
          ],
        ),
        const BlockTitle('Campagnes'),
        KpiGrid(
          minTile: 300,
          max: 2,
          children: [
            for (final c in s.campaigns)
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: TwoLines(c.name, c.audience)),
                        StatusPill(c.status.label, hueOf(c.status)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: [
                        Tag(
                          label: c.channel,
                          hue: Hue.violet,
                          icon: c.channel == 'WhatsApp'
                              ? AppIcons.whatsapp
                              : c.channel == 'E-mail'
                              ? AppIcons.mail
                              : AppIcons.bell,
                        ),
                        if (c.sent > 0)
                          Tag(label: '${c.sent} envois', hue: Hue.ink),
                        if (c.openRate > 0)
                          Tag(
                            label:
                                '${(c.openRate * 100).round()} % d’ouverture',
                            hue: Hue.lagoon,
                          ),
                        if (c.conversions > 0)
                          Tag(
                            label: '${c.conversions} conversions',
                            hue: Hue.gold,
                          ),
                      ],
                    ),
                    if (c.status == CampaignStatus.draft ||
                        c.status == CampaignStatus.scheduled) ...[
                      const SizedBox(height: 12),
                      AdminButton(
                        label: 'Lancer maintenant',
                        icon: AppIcons.send,
                        onPressed: () {
                          if (!guard(context, ref, AdminPermission.marketing)) {
                            return;
                          }
                          n.launchCampaign(c.id);
                          toast(context, 'Campagne « ${c.name} » lancée');
                        },
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
        const BlockTitle('Parrainage et notifications automatiques'),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, (title, caption)) in [
                (
                  'Programme de parrainage',
                  'Lien unique partagé par WhatsApp · 5 000 FCFA de crédit',
                ),
                (
                  'Relance des devis en attente',
                  'Notification à J+2 si aucun devis n’est accepté',
                ),
                ('Rappel d’acompte', 'Push et SMS 48 h avant l’échéance'),
                (
                  'Anniversaire de l’événement',
                  'Message un an après, avec code de fidélité',
                ),
              ].indexed) ...[
                if (i > 0) const Divider(height: 1),
                _AutoRow(title: title, caption: caption),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _newPromo(BuildContext context, WidgetRef ref) {
    final code = TextEditingController();
    final label = TextEditingController();
    final pct = TextEditingController(text: '10');
    final limit = TextEditingController(text: '500');
    showEventaSheet<void>(
      context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Text('Nouveau code promo', style: ctx.text.headlineSmall),
          const SizedBox(height: 14),
          AppField(
            label: 'Code',
            controller: code,
            hint: 'NOEL26',
            autofocus: true,
            formatters: [UpperCaseText()],
          ),
          const SizedBox(height: 12),
          AppField(label: 'Description', controller: label),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppField(
                  label: 'Remise',
                  controller: pct,
                  suffixText: '%',
                  keyboard: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppField(
                  label: 'Utilisations max',
                  controller: limit,
                  keyboard: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PillButton(
            label: 'Créer le code',
            tone: ButtonTone.dark,
            onPressed: () {
              if (code.text.trim().isEmpty) return;
              ref
                  .read(adminProvider.notifier)
                  .addPromo(
                    PromoCode(
                      code: code.text.trim().toUpperCase(),
                      label: label.text.trim().isEmpty
                          ? 'Code promotionnel'
                          : label.text.trim(),
                      percent: (int.tryParse(pct.text) ?? 10).clamp(1, 90),
                      uses: 0,
                      limit: int.tryParse(limit.text) ?? 500,
                      expires: DateTime.now().add(const Duration(days: 60)),
                    ),
                  );
              Navigator.of(ctx).pop();
              toast(context, 'Code ${code.text.trim().toUpperCase()} créé');
            },
          ),
        ],
      ),
    );
  }

  void _newCampaign(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    var channel = 'WhatsApp';
    var audience = 'Tous les organisateurs';
    showEventaSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Text('Nouvelle campagne', style: ctx.text.headlineSmall),
            const SizedBox(height: 14),
            AppField(label: 'Nom', controller: name, autofocus: true),
            const SizedBox(height: 12),
            const FieldLabel('Canal'),
            FilterChips<String>(
              values: const ['WhatsApp', 'Push', 'E-mail', 'SMS'],
              selected: channel,
              labelOf: (v) => v!,
              onChanged: (v) => set(() => channel = v!),
            ),
            const SizedBox(height: 12),
            const FieldLabel('Audience'),
            FilterChips<String>(
              values: const [
                'Tous les organisateurs',
                'Organisateurs Découverte',
                'Creators',
                'Inactifs depuis 30 j',
              ],
              selected: audience,
              labelOf: (v) => v!,
              onChanged: (v) => set(() => audience = v!),
            ),
            const SizedBox(height: 16),
            PillButton(
              label: 'Enregistrer en brouillon',
              tone: ButtonTone.dark,
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                ref
                    .read(adminProvider.notifier)
                    .addCampaign(
                      Campaign(
                        id: 'K${DateTime.now().millisecondsSinceEpoch}',
                        name: name.text.trim(),
                        channel: channel,
                        audience: audience,
                        status: CampaignStatus.draft,
                      ),
                    );
                Navigator.of(ctx).pop();
                toast(context, 'Campagne enregistrée en brouillon');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoRow extends StatefulWidget {
  const _AutoRow({required this.title, required this.caption});
  final String title;
  final String caption;

  @override
  State<_AutoRow> createState() => _AutoRowState();
}

class _AutoRowState extends State<_AutoRow> {
  bool _on = true;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: TwoLines(widget.title, widget.caption)),
        Switch(value: _on, onChanged: (v) => setState(() => _on = v)),
      ],
    ),
  );
}

/// Met le texte saisi en capitales (codes promo).
class UpperCaseText extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

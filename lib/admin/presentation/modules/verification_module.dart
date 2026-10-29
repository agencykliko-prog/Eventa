import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/ui.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Vérification des prestataires : profil, pièces et décision.
class VerificationModule extends ConsumerStatefulWidget {
  const VerificationModule({super.key});

  @override
  ConsumerState<VerificationModule> createState() => _VerificationState();
}

class _VerificationState extends ConsumerState<VerificationModule> {
  VerifyStatus? _filter = VerifyStatus.pending;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(adminProvider).checks;
    final list = all.where((c) => _filter == null || c.status == _filter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminHeader(
          title: 'Vérification des prestataires',
          subtitle: 'Contrôle des profils, pièces justificatives et informations professionnelles avant publication.',
        ),
        FilterChips<VerifyStatus>(
          values: const [null, ...VerifyStatus.values],
          selected: _filter,
          labelOf: (s) => s?.label ?? 'Tous',
          counts: (s) => all.where((c) => s == null || c.status == s).length,
          onChanged: (s) => setState(() => _filter = s),
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Panel(
            child: Text(
              'Aucun dossier dans cette file.',
              style: context.text.bodyMedium,
            ),
          ),
        ResponsiveGrid(
          minTile: 380,
          max: 2,
          children: [for (final c in list) _CheckCard(check: c)],
        ),
      ],
    );
  }
}

class _CheckCard extends ConsumerWidget {
  const _CheckCard({required this.check});

  final VendorCheck check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(adminProvider.notifier);
    final c = check;
    final complete = c.validDocs == c.docs.length;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: TwoLines(c.business, '${c.id} · ${c.owner}')),
              StatusPill(c.status.label, hueOf(c.status)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Tag(label: c.category, hue: Hue.violet),
              Tag(label: c.zone, hue: Hue.ink, icon: AppIcons.place),
              Tag(
                label: c.rccm ?? 'RCCM absent',
                hue: c.rccm == null ? Hue.coral : Hue.lagoon,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Dossier déposé le ${mediumDate(c.submitted)}',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 12),
          Meter(
            value: c.validDocs / c.docs.length,
            color: complete ? Confetti.lagoon : Confetti.mango,
            height: 6,
          ),
          const SizedBox(height: 4),
          Text(
            '${c.validDocs}/${c.docs.length} pièces conformes',
            style: context.text.labelSmall?.copyWith(color: Confetti.inkMuted),
          ),
          const SizedBox(height: 8),
          for (final (i, d) in c.docs.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(AppIcons.file, size: 17, color: Confetti.inkMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(d.name, style: context.text.bodyMedium)),
                  if (d.status == DocStatus.submitted &&
                      c.status != VerifyStatus.approved) ...[
                    _DocAction(
                      icon: AppIcons.check,
                      tooltip: 'Conforme',
                      hue: Hue.lagoon,
                      onTap: () {
                        if (guard(context, ref, AdminPermission.verification)) {
                          n.setDoc(c.id, i, DocStatus.valid);
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    _DocAction(
                      icon: AppIcons.close,
                      tooltip: 'Non conforme',
                      hue: Hue.coral,
                      onTap: () {
                        if (guard(context, ref, AdminPermission.verification)) {
                          n.setDoc(c.id, i, DocStatus.invalid);
                        }
                      },
                    ),
                  ] else
                    StatusPill(d.status.label, hueOf(d.status)),
                ],
              ),
            ),
          if (c.comment != null) ...[
            const SizedBox(height: 6),
            Text(
              'Commentaire : ${c.comment}',
              style: context.text.bodySmall?.copyWith(
                color: Confetti.violetText,
              ),
            ),
          ],
          if (c.status == VerifyStatus.pending ||
              c.status == VerifyStatus.info) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AdminButton(
                  label: 'Approuver',
                  icon: AppIcons.verified,
                  onPressed: complete
                      ? () {
                          if (!guard(
                            context,
                            ref,
                            AdminPermission.verification,
                          )) {
                            return;
                          }
                          n.decide(c.id, VerifyStatus.approved);
                          toast(
                            context,
                            '${c.business} vérifié : badge attribué et fiche publiée',
                          );
                        }
                      : null,
                ),
                AdminButton(
                  label: 'Demander des infos',
                  icon: AppIcons.message,
                  tone: ButtonTone.ghost,
                  onPressed: () => _comment(
                    context,
                    ref,
                    VerifyStatus.info,
                    'Demander des compléments',
                  ),
                ),
                AdminButton(
                  label: 'Refuser',
                  icon: AppIcons.close,
                  tone: ButtonTone.ghost,
                  onPressed: () => _comment(
                    context,
                    ref,
                    VerifyStatus.rejected,
                    'Motif du refus',
                  ),
                ),
              ],
            ),
            if (!complete)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'L’approbation exige toutes les pièces conformes.',
                  style: context.text.bodySmall,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _comment(
    BuildContext context,
    WidgetRef ref,
    VerifyStatus st,
    String title,
  ) async {
    if (!guard(context, ref, AdminPermission.verification)) return;
    final c = TextEditingController();
    final text = await showEventaSheet<String>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: ctx.text.headlineSmall),
            const SizedBox(height: 12),
            AppField(
              label: 'Message envoyé au prestataire',
              controller: c,
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 14),
            PillButton(
              label: 'Envoyer',
              tone: ButtonTone.dark,
              onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
            ),
          ],
        ),
      ),
    );
    if (text == null) return;
    ref
        .read(adminProvider.notifier)
        .decide(check.id, st, comment: text.isEmpty ? null : text);
    if (context.mounted) toast(context, 'Message envoyé à ${check.business}');
  }
}

class _DocAction extends StatelessWidget {
  const _DocAction({
    required this.icon,
    required this.tooltip,
    required this.hue,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Hue hue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RoundIconButton(
    icon: icon,
    tooltip: tooltip,
    size: 30,
    background: hue.tint,
    foreground: hue.text,
    onTap: onTap,
  );
}

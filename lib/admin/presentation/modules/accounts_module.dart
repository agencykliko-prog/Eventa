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

/// Gestion des comptes : créer, modifier, suspendre et rétablir.
class AccountsModule extends ConsumerStatefulWidget {
  const AccountsModule({super.key});

  @override
  ConsumerState<AccountsModule> createState() => _AccountsModuleState();
}

class _AccountsModuleState extends ConsumerState<AccountsModule> {
  String _q = '';
  AccountKind? _kind;
  AccountStatus? _status;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(adminProvider).accounts;
    final q = _q.toLowerCase();
    final list = all
        .where((a) => _kind == null || a.kind == _kind)
        .where((a) => _status == null || a.status == _status)
        .where(
          (a) =>
              q.isEmpty ||
              a.name.toLowerCase().contains(q) ||
              a.email.toLowerCase().contains(q) ||
              a.id.toLowerCase().contains(q),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(
          title: 'Gestion des comptes',
          subtitle: 'Clients et professionnels. Toute modification est tracée dans le journal d’audit.',
          actions: [
            AdminButton(
              label: 'Créer un compte',
              icon: AppIcons.userPlus,
              onPressed: () {
                if (guard(context, ref, AdminPermission.accounts)) {
                  _edit(context, null);
                }
              },
            ),
          ],
        ),
        AdminSearch(
          hint: 'Rechercher un nom, un e-mail, un identifiant…',
          onChanged: (v) => setState(() => _q = v),
        ),
        const SizedBox(height: 10),
        FilterChips<AccountKind>(
          values: const [null, ...AccountKind.values],
          selected: _kind,
          labelOf: (k) => k?.label ?? 'Tous',
          counts: (k) => all.where((a) => k == null || a.kind == k).length,
          onChanged: (k) => setState(() => _kind = k),
        ),
        const SizedBox(height: 8),
        FilterChips<AccountStatus>(
          values: const [null, ...AccountStatus.values],
          selected: _status,
          labelOf: (s) => s?.label ?? 'Tous statuts',
          counts: (s) => all.where((a) => s == null || a.status == s).length,
          onChanged: (s) => setState(() => _status = s),
        ),
        const SizedBox(height: 14),
        AdminTable(
          columns: const [
            AdminColumn('Compte', flex: 4),
            AdminColumn('Type'),
            AdminColumn('Ville'),
            AdminColumn('Statut'),
            AdminColumn('Volume', numeric: true),
            AdminColumn('Dernière visite', numeric: true),
          ],
          rows: [
            for (final a in list)
              [
                TwoLines(a.name, '${a.id} · ${a.email}'),
                Text(a.kind.label, style: context.text.bodyMedium),
                Text(a.city, style: context.text.bodyMedium),
                StatusPill(a.status.label, hueOf(a.status)),
                Text(fcfaCompact(a.volume), style: context.text.titleSmall),
                Text(since(a.lastSeen), style: context.text.bodySmall),
              ],
          ],
          onTap: (i) => _detail(context, list[i]),
          empty: 'Aucun compte ne correspond à la recherche',
        ),
      ],
    );
  }

  void _detail(BuildContext context, Account a) {
    showEventaSheet<void>(
      context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final acc = ref
              .watch(adminProvider)
              .accounts
              .firstWhere((x) => x.id == a.id);
          final n = ref.read(adminProvider.notifier);
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(acc.name, style: ctx.text.headlineSmall),
                  ),
                  StatusPill(acc.status.label, hueOf(acc.status)),
                ],
              ),
              Text('${acc.id} · ${acc.kind.label}', style: ctx.text.bodySmall),
              const SizedBox(height: 14),
              for (final (k, v) in [
                ('E-mail', acc.email),
                ('Téléphone', acc.phone),
                ('Ville', acc.city),
                ('Inscription', mediumDate(acc.joined)),
                (
                  acc.kind == AccountKind.creator
                      ? 'Prestations'
                      : 'Événements',
                  '${acc.events}',
                ),
                (
                  acc.kind == AccountKind.creator ? 'Encaissé' : 'Payé',
                  fcfa(acc.volume),
                ),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(k, style: ctx.text.bodySmall),
                      ),
                      Expanded(child: Text(v, style: ctx.text.titleSmall)),
                    ],
                  ),
                ),
              if (acc.note != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Confetti.coralTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Note interne : ${acc.note}',
                    style: ctx.text.bodySmall?.copyWith(
                      color: Confetti.coralDeep,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminButton(
                    label: 'Modifier',
                    icon: AppIcons.edit,
                    tone: ButtonTone.ghost,
                    onPressed: () {
                      if (!guard(ctx, ref, AdminPermission.accounts)) return;
                      Navigator.of(ctx).pop();
                      _edit(context, acc);
                    },
                  ),
                  if (acc.status == AccountStatus.suspended ||
                      acc.status == AccountStatus.pending)
                    AdminButton(
                      label: acc.status == AccountStatus.pending
                          ? 'Activer'
                          : 'Rétablir',
                      icon: AppIcons.checkCircle,
                      onPressed: () {
                        if (!guard(ctx, ref, AdminPermission.accounts)) return;
                        n.setAccountStatus(acc.id, AccountStatus.active);
                        toast(context, 'Compte ${acc.name} rétabli');
                      },
                    ),
                  if (acc.status != AccountStatus.suspended)
                    AdminButton(
                      label: 'Suspendre',
                      icon: AppIcons.lock,
                      tone: ButtonTone.primary,
                      onPressed: () async {
                        if (!guard(ctx, ref, AdminPermission.accounts)) return;
                        final reason = await _askReason(ctx);
                        if (reason == null) return;
                        n.setAccountStatus(
                          acc.id,
                          AccountStatus.suspended,
                          reason: reason,
                        );
                        if (context.mounted) {
                          toast(context, 'Compte ${acc.name} suspendu');
                        }
                      },
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _askReason(BuildContext context) {
    final c = TextEditingController();
    return showEventaSheet<String>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Motif de suspension', style: ctx.text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Le titulaire est prévenu par e-mail. Le motif reste visible de l’équipe.',
              style: ctx.text.bodySmall,
            ),
            const SizedBox(height: 14),
            AppField(
              label: 'Motif',
              controller: c,
              hint: 'Ex. fraude au paiement, annulations répétées…',
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 14),
            PillButton(
              label: 'Confirmer la suspension',
              onPressed: () => Navigator.of(ctx)
                  .pop(c.text.trim().isEmpty ? 'Non précisé' : c.text.trim()),
            ),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context, Account? a) {
    final name = TextEditingController(text: a?.name);
    final email = TextEditingController(text: a?.email);
    final phone = TextEditingController(text: a?.phone);
    final city = TextEditingController(text: a?.city ?? 'Abidjan');
    var kind = a?.kind ?? AccountKind.organizer;
    final form = GlobalKey<FormState>();
    showEventaSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Form(
          key: form,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Text(
                a == null ? 'Nouveau compte' : 'Modifier le compte',
                style: ctx.text.headlineSmall,
              ),
              const SizedBox(height: 14),
              if (a == null) ...[
                FilterChips<AccountKind>(
                  values: AccountKind.values,
                  selected: kind,
                  labelOf: (k) => k!.label,
                  onChanged: (k) => set(() => kind = k!),
                ),
                const SizedBox(height: 12),
              ],
              AppField(
                label: 'Nom',
                controller: name,
                validator: Validators.required,
              ),
              const SizedBox(height: 12),
              AppField(
                label: 'E-mail',
                controller: email,
                keyboard: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              AppField(label: 'Téléphone', controller: phone),
              const SizedBox(height: 12),
              AppField(label: 'Ville', controller: city),
              const SizedBox(height: 16),
              PillButton(
                label: a == null ? 'Créer le compte' : 'Enregistrer',
                tone: ButtonTone.dark,
                onPressed: () {
                  if (!form.currentState!.validate()) return;
                  final n = ref.read(adminProvider.notifier);
                  if (a == null) {
                    n.createAccount(
                      Account(
                        id: 'U-${1200 + ref.read(adminProvider).accounts.length}',
                        name: name.text.trim(),
                        email: email.text.trim(),
                        phone: phone.text.trim(),
                        city: city.text.trim(),
                        kind: kind,
                        status: kind == AccountKind.creator
                            ? AccountStatus.pending
                            : AccountStatus.active,
                        joined: DateTime.now(),
                        lastSeen: DateTime.now(),
                      ),
                    );
                  } else {
                    n.updateAccount(
                      a.copyWith(
                        name: name.text.trim(),
                        email: email.text.trim(),
                        phone: phone.text.trim(),
                        city: city.text.trim(),
                      ),
                    );
                  }
                  Navigator.of(ctx).pop();
                  toast(
                    context,
                    a == null ? 'Compte créé' : 'Compte mis à jour',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

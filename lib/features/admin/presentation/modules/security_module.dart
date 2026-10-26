import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/eventa_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/avatars.dart';
import '../../../../core/widgets/ui.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Paramètres & sécurité : équipe, rôles, permissions, audit, paramètres.
class SecurityModule extends ConsumerWidget {
  const SecurityModule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(adminProvider);
    final n = ref.read(adminProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminHeader(
          title: 'Paramètres & sécurité',
          subtitle: 'Équipe, rôles et permissions, journal d’audit et paramètres de la plateforme.',
        ),
        const BlockTitle('Équipe'),
        AdminTable(
          columns: const [
            AdminColumn('Membre', flex: 4),
            AdminColumn('Rôle', flex: 3),
            AdminColumn('Double authentification', flex: 2),
          ],
          rows: [
            for (final m in s.team)
              [
                Row(
                  children: [
                    Avatar(
                      initials: m.name.split(' ').map((p) => p[0]).join(),
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    Flexible(child: TwoLines(m.name, m.email)),
                  ],
                ),
                PopupMenuButton<AdminRole>(
                  tooltip: 'Changer le rôle',
                  color: Confetti.surface,
                  onSelected: (r) {
                    if (guard(context, ref, AdminPermission.security)) {
                      n.setMemberRole(m.id, r);
                    }
                  },
                  itemBuilder: (_) => [
                    for (final r in AdminRole.values)
                      PopupMenuItem(value: r, child: Text(r.label)),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Tag(label: m.role.label, hue: Hue.violet),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        AppIcons.chevronDown,
                        size: 13,
                        color: Confetti.inkMuted,
                      ),
                    ],
                  ),
                ),
                m.twoFactor
                    ? StatusPill('Activée', Hue.lagoon)
                    : StatusPill('À activer', Hue.coral),
              ],
          ],
        ),
        const BlockTitle('Rôles et permissions'),
        Panel(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(110),
              columnWidths: const {0: FixedColumnWidth(250)},
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  children: [
                    const SizedBox(),
                    for (final r in AdminRole.values)
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          r.label,
                          textAlign: TextAlign.center,
                          style: context.text.labelSmall,
                        ),
                      ),
                  ],
                ),
                for (final p in AdminPermission.values)
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Confetti.line)),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(p.label, style: context.text.bodyMedium),
                      ),
                      for (final r in AdminRole.values)
                        Checkbox(
                          value: s.permissions[r]?.contains(p) ?? false,
                          activeColor: Confetti.violet,
                          onChanged: r == AdminRole.superAdmin
                              ? null
                              : (_) {
                                  if (guard(
                                    context,
                                    ref,
                                    AdminPermission.security,
                                  )) {
                                    n.togglePermission(r, p);
                                  }
                                },
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Le rôle Super administrateur garde tous les droits et ne peut pas être restreint.',
          style: context.text.bodySmall,
        ),
        const BlockTitle('Paramètres de la plateforme'),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, e) in s.settings.entries.indexed) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.key, style: context.text.titleSmall),
                      ),
                      if (e.key == 'Mode maintenance' && e.value)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Tag(
                            label: 'App fermée',
                            hue: Hue.coral,
                            solid: true,
                          ),
                        ),
                      Switch(
                        value: e.value,
                        onChanged: (_) {
                          if (guard(context, ref, AdminPermission.security)) {
                            n.toggleSetting(e.key);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        BlockTitle(
          'Journal d’audit',
          trailing: Text(
            '${s.audit.length} entrées',
            style: context.text.labelMedium?.copyWith(color: Confetti.inkMuted),
          ),
        ),
        AdminTable(
          columns: const [
            AdminColumn('Action', flex: 3),
            AdminColumn('Cible', flex: 4),
            AdminColumn('Par', flex: 2),
            AdminColumn('Quand', numeric: true),
          ],
          rows: [
            for (final a in s.audit.take(30))
              [
                Text(a.action, style: context.text.titleSmall),
                Text(
                  a.target,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium,
                ),
                Text(a.actor, style: context.text.bodySmall),
                Text(
                  '${since(a.at)} · ${timeOf(a.at)}',
                  style: context.text.bodySmall,
                ),
              ],
          ],
        ),
      ],
    );
  }
}

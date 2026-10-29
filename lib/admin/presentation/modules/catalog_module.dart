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
import '../../../ui/dataviz/dataviz.dart';

/// Catalogue : catégories, sous-catégories, annonces et contenus.
class CatalogModule extends ConsumerStatefulWidget {
  const CatalogModule({super.key});

  @override
  ConsumerState<CatalogModule> createState() => _CatalogModuleState();
}

class _CatalogModuleState extends ConsumerState<CatalogModule> {
  ListingStatus? _filter;

  /// Contenus éditoriaux de l'app (démo locale).
  final _contents = <(String, String, bool)>[
    ('Bannière d’accueil', 'Saison des mariages · jusqu’au 31 décembre', true),
    (
      'Guide « Budget de mariage à Abidjan »',
      'Article · 6 min de lecture',
      true,
    ),
    ('Questions fréquentes', '24 questions · mise à jour il y a 3 j', true),
    ('Conditions générales', 'Version 1.0 · en relecture juridique', false),
  ];

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(adminProvider);
    final listings = s.listings
        .where((l) => _filter == null || l.status == _filter)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(
          title: 'Gestion du catalogue',
          subtitle: 'Catégories et sous-catégories visibles dans Explorer, annonces des prestataires et contenus éditoriaux.',
          actions: [
            AdminButton(
              label: 'Nouvelle catégorie',
              icon: AppIcons.add,
              onPressed: () {
                if (guard(context, ref, AdminPermission.catalog)) {
                  _editCategory(context, null);
                }
              },
            ),
          ],
        ),
        const BlockTitle('Catégories'),
        KpiGrid(
          minTile: 300,
          max: 3,
          children: [
            for (final c in s.categories)
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TwoLines(c.name, '${c.listings} annonces'),
                        ),
                        Switch(
                          value: c.visible,
                          onChanged: (_) {
                            if (guard(context, ref, AdminPermission.catalog)) {
                              ref
                                  .read(adminProvider.notifier)
                                  .toggleCategory(c.id);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final sub in c.subcategories)
                          Tag(label: sub, hue: Hue.ink),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.visible ? 'Visible dans Explorer' : 'Masquée',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            if (guard(context, ref, AdminPermission.catalog)) {
                              _editCategory(context, c);
                            }
                          },
                          icon: Icon(
                            AppIcons.edit,
                            size: 15,
                            color: Confetti.ink,
                          ),
                          label: Text(
                            'Modifier',
                            style: context.text.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        BlockTitle(
          'Annonces',
          trailing: Text(
            '${s.listings.where((l) => l.reports > 0).length} signalées',
            style: context.text.labelMedium?.copyWith(color: Confetti.danger),
          ),
        ),
        FilterChips<ListingStatus>(
          values: const [null, ...ListingStatus.values],
          selected: _filter,
          labelOf: (v) => v?.label ?? 'Toutes',
          counts: (v) =>
              s.listings.where((l) => v == null || l.status == v).length,
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 12),
        AdminTable(
          columns: const [
            AdminColumn('Annonce', flex: 4),
            AdminColumn('Catégorie'),
            AdminColumn('Prix', numeric: true),
            AdminColumn('Signalements', numeric: true),
            AdminColumn('Statut', numeric: true),
          ],
          rows: [
            for (final l in listings)
              [
                Row(
                  children: [
                    Flexible(child: TwoLines(l.title, '${l.id} · ${l.vendor}')),
                    if (l.sponsored) ...[
                      const SizedBox(width: 6),
                      Tag(label: 'Sponsorisée', hue: Hue.gold),
                    ],
                  ],
                ),
                Text(l.category, style: context.text.bodyMedium),
                Text(fcfa(l.price), style: context.text.titleSmall),
                Text(
                  '${l.reports}',
                  style: context.text.titleSmall?.copyWith(
                    color: l.reports > 0 ? Confetti.danger : Confetti.inkFaint,
                  ),
                ),
                StatusPill(l.status.label, hueOf(l.status)),
              ],
          ],
          onTap: (i) => _listing(context, listings[i]),
        ),
        const BlockTitle('Contenus éditoriaux'),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, (title, caption, on)) in _contents.indexed) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(AppIcons.file, size: 19, color: Confetti.inkMuted),
                      const SizedBox(width: 12),
                      Expanded(child: TwoLines(title, caption)),
                      Text(
                        on ? 'Publié' : 'Brouillon',
                        style: context.text.labelSmall,
                      ),
                      Switch(
                        value: on,
                        onChanged: (v) {
                          if (!guard(context, ref, AdminPermission.catalog)) {
                            return;
                          }
                          setState(() => _contents[i] = (title, caption, v));
                          ref
                              .read(adminProvider.notifier)
                              .note(
                                v ? 'Contenu publié' : 'Contenu dépublié',
                                title,
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _listing(BuildContext context, Listing l) {
    showEventaSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.title, style: ctx.text.headlineSmall),
            Text(
              '${l.vendor} · ${l.category} · ${fcfa(l.price)}',
              style: ctx.text.bodySmall,
            ),
            if (l.reports > 0) ...[
              const SizedBox(height: 10),
              Text(
                '${l.reports} signalement(s) : informations trompeuses ou prestation non honorée.',
                style: ctx.text.bodySmall?.copyWith(color: Confetti.danger),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (l.status != ListingStatus.published)
                  AdminButton(
                    label: 'Publier',
                    icon: AppIcons.checkCircle,
                    onPressed: () => _set(ctx, l, ListingStatus.published),
                  ),
                if (l.status != ListingStatus.hidden)
                  AdminButton(
                    label: 'Masquer',
                    icon: AppIcons.eyeOff,
                    tone: ButtonTone.ghost,
                    onPressed: () => _set(ctx, l, ListingStatus.hidden),
                  ),
                if (l.status != ListingStatus.review)
                  AdminButton(
                    label: 'Remettre en revue',
                    icon: AppIcons.refresh,
                    tone: ButtonTone.ghost,
                    onPressed: () => _set(ctx, l, ListingStatus.review),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _set(BuildContext ctx, Listing l, ListingStatus st) {
    if (!guard(ctx, ref, AdminPermission.catalog)) return;
    ref.read(adminProvider.notifier).setListing(l.id, st);
    Navigator.of(ctx).pop();
    toast(context, '${l.title} : ${st.label.toLowerCase()}');
  }

  void _editCategory(BuildContext context, CatalogCategory? c) {
    final name = TextEditingController(text: c?.name);
    final subs = TextEditingController(text: c?.subcategories.join(', '));
    showEventaSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              c == null ? 'Nouvelle catégorie' : 'Modifier ${c.name}',
              style: ctx.text.headlineSmall,
            ),
            const SizedBox(height: 14),
            AppField(label: 'Nom', controller: name, autofocus: c == null),
            const SizedBox(height: 12),
            AppField(
              label: 'Sous-catégories (séparées par des virgules)',
              controller: subs,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            PillButton(
              label: 'Enregistrer',
              tone: ButtonTone.dark,
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                final list = subs.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                ref
                    .read(adminProvider.notifier)
                    .saveCategory(
                      c?.copyWith(
                            name: name.text.trim(),
                            subcategories: list,
                          ) ??
                          CatalogCategory(
                            id: 'c${DateTime.now().millisecondsSinceEpoch}',
                            name: name.text.trim(),
                            subcategories: list,
                            listings: 0,
                          ),
                    );
                Navigator.of(ctx).pop();
                toast(context, 'Catégorie enregistrée');
              },
            ),
          ],
        ),
      ),
    );
  }
}

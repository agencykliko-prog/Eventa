import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/ui.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../premium/presentation/paywall.dart';

/// Coffre-fort numérique : contrats, devis, factures, photos… 100 Mo
/// offerts à tous les organisateurs, davantage avec un abonnement.
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  VaultFolder? _folder;

  /// Ajoute un document si l'espace le permet ; sinon propose plus d'espace.
  void _upload(BuildContext context, int sizeKb) {
    final plan = ref.read(planProvider);
    final used = ref.read(vaultProvider).fold<int>(0, (s, d) => s + d.sizeKb);
    void add() {
      ref
          .read(vaultProvider.notifier)
          .add(
            VaultDoc(
              name: 'Scan {0}.pdf'.trf([shortDate(DateTime.now())]),
              folder: _folder ?? VaultFolder.documents,
              sizeKb: sizeKb,
              date: DateTime.now(),
            ),
          );
      toast(context, 'Document chiffré et ajouté'.tr, icon: AppIcons.lock);
    }

    if (used + sizeKb <= plan.vaultMb * 1024) {
      add();
      return;
    }
    requirePremium(
      context,
      ref,
      feature: PremiumFeature.vault,
      onUnlocked: add,
    );
  }

  String _size(int kb) => kb >= 1024
      ? '{0} Mo'.trf([(kb / 1024).toStringAsFixed(1).replaceAll('.', ',')])
      : '{0} Ko'.trf([kb]);

  void _docActions(BuildContext context, VaultDoc d) {
    showEventaSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(d.name, style: ctx.text.titleMedium, maxLines: 2),
            const SizedBox(height: 16),
            PillButton(
              label: 'Télécharger'.tr,
              icon: AppIcons.download,
              tone: ButtonTone.dark,
              onPressed: () {
                Navigator.of(ctx).pop();
                toast(
                  context,
                  'Téléchargement de « {0} »'.trf([d.name]),
                  icon: AppIcons.download,
                );
              },
            ),
            const SizedBox(height: 8),
            PillButton(
              label: 'Partager avec un collaborateur'.tr,
              icon: AppIcons.share,
              tone: ButtonTone.ghost,
              onPressed: () {
                Navigator.of(ctx).pop();
                toast(
                  context,
                  'Lien sécurisé copié (valable 24 h)'.tr,
                  icon: AppIcons.lock,
                );
              },
            ),
            const SizedBox(height: 8),
            PillButton(
              label: 'Supprimer'.tr,
              icon: AppIcons.trash,
              tone: ButtonTone.ghost,
              onPressed: () {
                ref.read(vaultProvider.notifier).remove(d);
                Navigator.of(ctx).pop();
                toast(context, 'Document supprimé'.tr, icon: AppIcons.trash);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(vaultProvider);
    final shown = docs
        .where((d) => _folder == null || d.folder == _folder)
        .toList();
    final usedKb = docs.fold<int>(0, (s, d) => s + d.sizeKb);
    final plan = ref.watch(planProvider);
    final quotaKb = plan.vaultMb * 1024;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  onTap: () => context.pop(),
                ),
                const Spacer(),
                RoundIconButton(
                  icon: AppIcons.upload,
                  tooltip: 'Ajouter un document',
                  onTap: () => _upload(context, 310),
                ),
              ],
            ),
            const SizedBox(height: 16),
            NightPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconTile(icon: AppIcons.lock, hue: Hue.gold, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coffre-fort'.tr,
                              style: context.text.headlineSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Chiffré de bout en bout'.tr,
                              style: context.text.bodySmall?.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PremiumBadge(label: plan.label, onDark: true),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        '{0} documents'.trf([docs.length]),
                        style: context.text.labelMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '{0} sur {1}'.trf([_size(usedKb), plan.vaultLabel]),
                        style: context.text.labelMedium?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Meter(
                    value: (usedKb / quotaKb).clamp(0.02, 1.0),
                    color: Confetti.gold,
                    track: Confetti.nightLine,
                    height: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              padding: EdgeInsets.zero,
              children: [
                for (final (i, f) in VaultFolder.values.indexed)
                  Entrance(
                    index: i,
                    child: Pressable(
                      onTap: () =>
                          setState(() => _folder = _folder == f ? null : f),
                      child: AnimatedContainer(
                        duration: Motion.fast,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _folder == f ? Confetti.ink : Confetti.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _folder == f ? Confetti.ink : Confetti.line,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              f.icon,
                              size: 22,
                              color: _folder == f
                                  ? Confetti.gold
                                  : Confetti.violetText,
                            ),
                            const Spacer(),
                            Text(
                              f.label,
                              maxLines: 2,
                              style: context.text.labelMedium?.copyWith(
                                color: _folder == f
                                    ? Confetti.onInk
                                    : Confetti.ink,
                              ),
                            ),
                            Text(
                              '${docs.where((d) => d.folder == f).length}',
                              style: context.text.labelSmall?.copyWith(
                                color: _folder == f
                                    ? Colors.white60
                                    : Confetti.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SectionTitle(_folder?.label ?? 'Récents'.tr),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Aucun document ici pour l’instant.'.tr,
                        style: context.text.bodySmall,
                      ),
                    ),
                  for (final (i, d) in shown.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          IconTile(
                            icon: d.folder.icon,
                            hue: Hue.violet,
                            size: 38,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.name,
                                  style: context.text.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${mediumDate(d.date)} · ${_size(d.sizeKb)}',
                                  style: context.text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          RoundIconButton(
                            icon: AppIcons.more,
                            size: 34,
                            tooltip: 'Actions',
                            onTap: () => _docActions(context, d),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

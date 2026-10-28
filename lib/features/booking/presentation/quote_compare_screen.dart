import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ui.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../events/domain/models.dart';
import '../../marketplace/data/vendor_media.dart';

// ─── Comparateur de devis ───────────────────────────────────────────────
// Les devis reçus pour un même événement et une même catégorie de
// prestataire, côte à côte : total, acompte, validité, note et détail des
// lignes. Le choix renvoie vers la réservation, où l'on accepte les
// conditions.

/// Devis d'une même catégorie, du moins cher au plus cher.
@immutable
class QuoteGroup {
  const QuoteGroup(this.category, this.offers);
  final VendorCategory category;
  final List<Booking> offers;

  Booking get cheapest => offers.first;

  /// Écart entre le devis le plus cher et le moins cher.
  int get spread => offers.last.quote!.total - offers.first.quote!.total;

  /// Une offre de la catégorie est déjà réservée.
  Booking? get chosen => offers
      .where((b) => b.step.index >= BookingStep.reserved.index)
      .firstOrNull;
}

/// Catégories d'un événement ayant reçu au moins un devis.
final quoteGroupsProvider = Provider.family<List<QuoteGroup>, String>((
  ref,
  eventId,
) {
  final byCategory = <VendorCategory, List<Booking>>{};
  for (final b in ref.watch(bookingsProvider)) {
    if (b.eventId != eventId || b.archived || b.quote == null) continue;
    byCategory.putIfAbsent(b.vendor.category, () => []).add(b);
  }
  return [
    for (final e in byCategory.entries)
      QuoteGroup(
        e.key,
        e.value..sort((a, b) => a.quote!.total.compareTo(b.quote!.total)),
      ),
  ]..sort((a, b) {
    // Les catégories les plus disputées d'abord, puis l'ordre du catalogue.
    final n = b.offers.length.compareTo(a.offers.length);
    return n != 0 ? n : a.category.index.compareTo(b.category.index);
  });
});

/// Autres devis de la même catégorie pour le même événement.
final rivalQuotesProvider = Provider.family<int, String>((ref, bookingId) {
  final b = ref.watch(bookingProvider(bookingId));
  if (b == null) return 0;
  final group = ref
      .watch(quoteGroupsProvider(b.eventId))
      .where((g) => g.category == b.vendor.category)
      .firstOrNull;
  return group == null
      ? 0
      : group.offers.where((x) => x.id != bookingId).length;
});

class QuoteCompareScreen extends ConsumerWidget {
  const QuoteCompareScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(quoteGroupsProvider(eventId));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.event(eventId)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparer les devis'.tr,
                    style: context.text.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Les devis reçus côte à côte, par type de prestataire.'.tr,
                    style: context.text.bodyMedium?.copyWith(
                      color: Confetti.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Panel(
                  child: Text(
                    'Aucun devis reçu pour cet événement. Demandez un devis à au moins deux prestataires d’une même catégorie pour les comparer.'
                        .tr,
                    style: context.text.bodyMedium,
                  ),
                ),
              ),
            for (final g in groups) _Group(group: g),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.group});
  final QuoteGroup group;

  @override
  Widget build(BuildContext context) {
    final g = group;
    final chosen = g.chosen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          g.category.label,
          action: '{0} devis'.trf([g.offers.length]),
        ),
        if (g.offers.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              chosen != null
                  ? '{0} est réservé.'.trf([chosen.vendor.name])
                  : '{0} écart entre le moins cher et le plus cher.'.trf([
                      fcfa(g.spread),
                    ]),
              style: context.text.bodySmall?.copyWith(color: Confetti.inkMuted),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Demandez un autre devis dans cette catégorie pour comparer.'.tr,
              style: context.text.bodySmall?.copyWith(color: Confetti.inkMuted),
            ),
          ),
        LayoutBuilder(
          builder: (context, box) {
            // Sur grand écran, les devis se partagent la largeur ; sur
            // mobile, ils défilent à l'horizontale.
            const minW = 260.0;
            final fits = g.offers.length * minW + (g.offers.length - 1) * 12;
            final cards = [
              for (final b in g.offers)
                _Offer(
                  booking: b,
                  cheapest: g.offers.length > 1 && b.id == g.cheapest.id,
                  locked: chosen != null && chosen.id != b.id,
                ),
            ];
            if (fits <= box.maxWidth) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, c) in cards.indexed) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: c),
                    ],
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, c) in cards.indexed) ...[
                      if (i > 0) const SizedBox(width: 12),
                      SizedBox(width: minW, child: c),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Offer extends StatelessWidget {
  const _Offer({
    required this.booking,
    required this.cheapest,
    required this.locked,
  });

  final Booking booking;
  final bool cheapest;

  /// Une autre offre de la catégorie est déjà réservée.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final q = b.quote!;
    final v = b.vendor;
    final reserved = b.step.index >= BookingStep.reserved.index;
    final expired = !reserved && q.validUntil.isBefore(DateTime.now());
    final muted = context.text.bodySmall?.copyWith(color: Confetti.inkMuted);

    Widget line(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: muted)),
          Text(value, style: context.text.labelMedium?.copyWith(color: color)),
        ],
      ),
    );

    return Panel(
      key: ValueKey('offer-${b.id}'),
      padding: const EdgeInsets.all(14),
      color: cheapest && !locked ? Confetti.lagoonTint : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VendorPhoto(
                  v.image,
                  width: 40,
                  height: 40,
                  cacheWidth: 120,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    Row(
                      children: [
                        Icon(AppIcons.star, size: 12, color: Confetti.gold),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '{0} · {1} avis'.trf([
                              v.rating.toStringAsFixed(1).replaceAll('.', ','),
                              v.reviews,
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (reserved)
                Tag(
                  label: 'Réservé'.tr,
                  hue: Hue.violet,
                  icon: AppIcons.calendarCheck,
                ),
              if (cheapest)
                Tag(label: 'Le moins cher'.tr, hue: Hue.lagoon, solid: true),
              if (v.verified)
                Tag(
                  label: 'Vérifié'.tr,
                  hue: Hue.violet,
                  icon: AppIcons.verified,
                ),
              if (expired) Tag(label: 'Expiré'.tr, hue: Hue.coral),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fcfa(q.total),
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          line(
            'Acompte ({0} %)'.trf([(q.depositRate * 100).round()]),
            fcfa(q.deposit),
          ),
          line('Frais de service'.tr, fcfa(q.fees)),
          line(
            'Valable jusqu’au'.tr,
            shortDate(q.validUntil),
            color: expired ? Confetti.coralDeep : null,
          ),
          line('Répond en'.tr, v.responseTime),
          const Divider(height: 18),
          for (final l in q.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l.optional ? '{0} (option)'.trf([l.label]) : l.label,
                      style: context.text.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(fcfaCompact(l.amount), style: context.text.labelSmall),
                ],
              ),
            ),
          const Spacer(),
          const SizedBox(height: 12),
          PillButton(
            key: ValueKey('choose-${b.id}'),
            label: reserved ? 'Voir la réservation'.tr : 'Choisir ce devis'.tr,
            tone: reserved || cheapest ? ButtonTone.primary : ButtonTone.ghost,
            height: 42,
            onPressed: locked || expired
                ? null
                : () => context.push(Routes.booking(b.id)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/i18n/tr.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/eventa_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/ui.dart';
import '../../../events/domain/models.dart';

String priceLabel(Vendor v) =>
    'dès {0}{1}'.trf([fcfa(v.priceFrom), v.unit == 'forfait' ? '' : ' / ${v.unit}']);

/// Carte prestataire orientée conversion : photo, puis nom et prix en
/// premier plan, catégorie, et coordonnées directement lisibles.
class VendorCard extends StatelessWidget {
  const VendorCard({super.key, required this.vendor, required this.onTap});

  final Vendor vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = vendor;
    return Pressable(
      onTap: onTap,
      semanticLabel: v.name,
      child: Container(
        decoration: BoxDecoration(
          color: Confetti.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Confetti.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'vendor-${v.id}',
                    child: Image.asset(v.image, fit: BoxFit.cover),
                  ),
                  if (v.sponsor != null)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: SponsorTag(sponsor: v.sponsor!),
                    ),
                  if (!v.available)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: AvailabilityPill(vendor: v),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                v.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (v.verified) ...[
                              const SizedBox(width: 5),
                              Icon(
                                AppIcons.verified,
                                size: 16,
                                color: Confetti.violet,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              v.category.icon,
                              size: 13,
                              color: Confetti.inkMuted,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${v.category.label} · ${v.zone}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodySmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Stars(rating: v.rating, size: 12),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'à partir de'.tr,
                        style: context.text.labelSmall?.copyWith(
                          color: Confetti.inkFaint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        fcfa(v.priceFrom),
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (v.unit != 'forfait')
                        Text(
                          '/ ${v.unit}',
                          style: context.text.labelSmall?.copyWith(
                            color: Confetti.inkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _Contact(icon: AppIcons.phone, text: v.phoneNumber),
                  _Contact(icon: AppIcons.mail, text: v.email),
                  _Contact(icon: AppIcons.globe, text: v.website),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Confetti.inkMuted),
        const SizedBox(width: 5),
        Text(
          text,
          style: context.text.labelSmall?.copyWith(
            color: Confetti.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class SponsorTag extends StatelessWidget {
  const SponsorTag({super.key, required this.sponsor});

  final Sponsor sponsor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        sponsor == Sponsor.recommended ? 'Recommandé'.tr : 'Sponsorisé'.tr,
        style: context.text.labelSmall?.copyWith(
          color: Confetti.ink,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class AvailabilityPill extends StatelessWidget {
  const AvailabilityPill({super.key, required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final ok = vendor.available;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: ok ? Confetti.success : Confetti.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            ok ? 'Disponible'.tr : (vendor.nextAvailable ?? 'Complet'.tr),
            style: context.text.labelSmall?.copyWith(
              color: Confetti.ink,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

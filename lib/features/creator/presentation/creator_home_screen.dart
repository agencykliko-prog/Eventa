import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/ui.dart';
import '../../auth/presentation/session_provider.dart';
import '../../home/presentation/home_screen.dart';
import 'creator_providers.dart';
import 'requests_screen.dart';

/// Accueil Creator : activité commerciale, demandes, prestations, visibilité.
class CreatorHomeScreen extends ConsumerWidget {
  const CreatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final c = profile.creator;
    final requests = ref.watch(requestsProvider);
    final pending = requests
        .where((r) => r.status == RequestStatus.received)
        .toList();
    final confirmed =
        requests.where((r) => r.status == RequestStatus.confirmed).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final revenue = confirmed.fold<int>(0, (s, r) => s + (r.quote ?? 0));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          physics: const BouncingScrollPhysics(),
          children: [
            const HomeHeader(subtitle: 'Espace Creator'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Entrance(
                child: Panel(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chiffre d’affaires confirmé',
                        style: context.text.labelMedium?.copyWith(
                          color: Confetti.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fcfa(revenue),
                        style: context.text.displaySmall?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _Kpi(
                            label: 'Nouvelles demandes',
                            value: '${pending.length}',
                          ),
                          _Kpi(
                            label: 'Confirmées',
                            value: '${confirmed.length}',
                          ),
                          const _Kpi(label: 'Note', value: '4,8'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SectionTitle(
              'Demandes à traiter',
              action: 'Tout voir',
              onAction: () => context.go(Routes.requests),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: pending.isEmpty
                  ? Panel(
                      child: Text(
                        'Aucune demande en attente. Bravo !',
                        style: context.text.bodyMedium,
                      ),
                    )
                  : Column(
                      children: [
                        for (final r in pending.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: RequestTile(request: r),
                          ),
                      ],
                    ),
            ),
            SectionTitle(
              'Prochaines prestations',
              action: 'Agenda',
              onAction: () => context.go(Routes.planning),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Panel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (final (i, r) in confirmed.take(4).indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 64,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    timeOf(r.date),
                                    style: context.text.titleSmall,
                                  ),
                                  Text(
                                    shortDate(r.date),
                                    style: context.text.labelSmall?.copyWith(
                                      color: Confetti.inkFaint,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 3,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Confetti.lagoon,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.eventName,
                                    style: context.text.titleSmall,
                                  ),
                                  Text(
                                    '${r.client} · ${r.guests} invités',
                                    style: context.text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              fcfaCompact(r.quote ?? 0),
                              style: context.text.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (c != null) ...[
              SectionTitle(
                'Mon profil public',
                action: 'Modifier',
                onAction: () => context.push(Routes.editProfile),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Panel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconTile(
                            icon: c.category.icon,
                            hue: Hue.mango,
                            size: 46,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.displayName,
                                  style: context.text.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${c.category.label} · ${c.zone}',
                                  style: context.text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'à partir de',
                                style: context.text.labelSmall?.copyWith(
                                  color: Confetti.inkFaint,
                                ),
                              ),
                              Text(
                                fcfa(c.priceFrom),
                                style: context.text.titleSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        c.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall,
                      ),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _Contact(AppIcons.phone, profile.phone),
                          _Contact(AppIcons.mail, profile.email),
                          if (c.website != null)
                            _Contact(AppIcons.globe, c.website!),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: NightPanel(
                onTap: () => context.push(Routes.business),
                child: Row(
                  children: [
                    const IconTile(
                      icon: AppIcons.megaphone,
                      hue: Hue.gold,
                      size: 42,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gagnez en visibilité',
                            style: context.text.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Publicité Premium et offre Business dès 29 900 FCFA/mois',
                            style: context.text.bodySmall?.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      AppIcons.chevron,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: context.text.labelSmall?.copyWith(
            color: Confetti.inkMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _Contact extends StatelessWidget {
  const _Contact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: Confetti.inkMuted),
      const SizedBox(width: 5),
      Text(
        text,
        style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
    ],
  );
}

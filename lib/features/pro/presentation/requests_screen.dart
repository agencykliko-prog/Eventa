import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/avatars.dart';
import '../../../ui/widgets/ui.dart';
import '../../marketplace/presentation/explore_screen.dart';
import 'creator_providers.dart';

/// Boîte de réception des demandes de devis (Creator).
class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  RequestStatus? _filter = RequestStatus.received;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(requestsProvider);
    final list =
        all.where((r) => _filter == null || r.status == _filter).toList()
          ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          physics: const BouncingScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Demandes'.tr, style: context.text.headlineMedium),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final s in [
                    RequestStatus.received,
                    RequestStatus.quoted,
                    RequestStatus.confirmed,
                    null,
                  ]) ...[
                    Choice(
                      label:
                          '${s?.label ?? 'Toutes'.tr} · ${all.where((r) => s == null || r.status == s).length}',
                      on: _filter == s,
                      onTap: () => setState(() => _filter = s),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: Motion.base,
              child: Column(
                key: ValueKey(_filter),
                children: [
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'Rien ici pour le moment.'.tr,
                        style: context.text.bodyMedium?.copyWith(
                          color: Confetti.inkMuted,
                        ),
                      ),
                    ),
                  for (final r in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RequestTile(request: r),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RequestTile extends ConsumerWidget {
  const RequestTile({super.key, required this.request});

  final ClientRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    final hue = switch (r.status) {
      RequestStatus.received => Hue.coral,
      RequestStatus.quoted => Hue.mango,
      RequestStatus.confirmed => Hue.lagoon,
      RequestStatus.declined => Hue.ink,
    };
    final ago = DateTime.now().difference(r.receivedAt);
    final when = ago.inMinutes < 60
        ? 'il y a {0} min'.trf([ago.inMinutes])
        : ago.inHours < 24
        ? 'il y a {0} h'.trf([ago.inHours])
        : shortDate(r.receivedAt);
    return Panel(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/pro/devis/${r.id}'),
      child: Row(
        children: [
          Avatar(image: r.avatar, initials: r.client[0], size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.client,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall,
                      ),
                    ),
                    Text(
                      when,
                      style: context.text.labelSmall?.copyWith(
                        color: Confetti.inkFaint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '{0} · {1} à {2}'.trf([
                    r.eventName,
                    shortDate(r.date),
                    timeOf(r.date),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Tag(label: r.status.label, hue: hue),
                    const SizedBox(width: 8),
                    Text(
                      '{0} invités'.trf([r.guests]),
                      style: context.text.labelSmall?.copyWith(
                        color: Confetti.inkMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (r.quote != null)
                      Text(fcfa(r.quote!), style: context.text.labelMedium),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

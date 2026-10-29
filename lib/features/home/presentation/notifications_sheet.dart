import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/ui.dart';
import '../../notifications/presentation/notifications_provider.dart';

Future<void> showNotificationsSheet(BuildContext context) =>
    showEventaSheet<void>(context, builder: (_) => const _Notifications());

String _ago(DateTime at) {
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return 'à l’instant'.tr;
  if (d.inMinutes < 60) return 'il y a {0} min'.trf([d.inMinutes]);
  if (d.inHours < 24) return 'il y a {0} h'.trf([d.inHours]);
  if (d.inDays == 1) return 'Hier'.tr;
  return shortDate(at);
}

/// Liste des notifications. Les non lues à l'ouverture restent signalées
/// (point violet) pendant la consultation, puis tout passe en lu.
class _Notifications extends ConsumerStatefulWidget {
  const _Notifications();

  @override
  ConsumerState<_Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends ConsumerState<_Notifications> {
  late final Set<String> _fresh = {
    for (final n in ref.read(noticesProvider))
      if (!n.read) n.id,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(noticesProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(noticesProvider);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Text('Notifications'.tr, style: context.text.headlineSmall),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Rien de nouveau pour le moment.'.tr,
              style: context.text.bodyMedium?.copyWith(
                color: Confetti.inkMuted,
              ),
            ),
          ),
        for (final (i, n) in items.indexed) ...[
          if (i > 0) const Divider(height: 1),
          InkWell(
            key: ValueKey('notice-${n.id}'),
            borderRadius: BorderRadius.circular(12),
            onTap: n.link == null
                ? null
                : () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.push(n.link!);
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  IconTile(icon: n.icon, hue: n.hue, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: context.text.titleSmall),
                        Text(
                          n.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _ago(n.at),
                        style: context.text.labelSmall?.copyWith(
                          color: Confetti.inkFaint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_fresh.contains(n.id)) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Confetti.violet,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

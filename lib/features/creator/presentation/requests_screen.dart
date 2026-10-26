import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatars.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/ui.dart';
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
              child: Text('Demandes', style: context.text.headlineMedium),
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
                          '${s?.label ?? 'Toutes'} · ${all.where((r) => s == null || r.status == s).length}',
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
                        'Rien ici pour le moment.',
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
        ? 'il y a ${ago.inMinutes} min'
        : ago.inHours < 24
        ? 'il y a ${ago.inHours} h'
        : shortDate(r.receivedAt);
    return Panel(
      padding: const EdgeInsets.all(14),
      onTap: () => showEventaSheet<void>(
        context,
        builder: (_) => _RequestSheet(id: r.id),
      ),
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
                  '${r.eventName} · ${shortDate(r.date)} à ${timeOf(r.date)}',
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
                      '${r.guests} invités',
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

class _RequestSheet extends ConsumerStatefulWidget {
  const _RequestSheet({required this.id});

  final String id;

  @override
  ConsumerState<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends ConsumerState<_RequestSheet> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(requestsProvider).firstWhere((x) => x.id == widget.id);
    final n = ref.read(requestsProvider.notifier);
    Widget line(IconData i, String t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(i, size: 16, color: Confetti.inkMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: context.text.bodyMedium)),
        ],
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(image: r.avatar, initials: r.client[0], size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.client, style: context.text.titleLarge),
                    Text(r.eventName, style: context.text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          line(
            AppIcons.calendarCheck,
            '${longDate(r.date)} à ${timeOf(r.date)}',
          ),
          line(AppIcons.guests, '${r.guests} invités'),
          if (r.budget != null)
            line(AppIcons.wallet, 'Budget indicatif : ${fcfa(r.budget!)}'),
          for (final o in r.options) line(AppIcons.check, o),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Confetti.line),
            ),
            child: Text('« ${r.message} »', style: context.text.bodyMedium),
          ),
          const SizedBox(height: 18),
          if (r.status == RequestStatus.received) ...[
            AppField(
              label: 'Montant du devis',
              controller: _amount,
              keyboard: TextInputType.number,
              suffixText: 'FCFA',
              formatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
            ),
            const SizedBox(height: 14),
            PillButton(
              label: 'Envoyer le devis',
              icon: AppIcons.send,
              onPressed: () {
                final v = int.tryParse(_amount.text) ?? 0;
                if (v <= 0) return;
                n.sendQuote(r.id, v);
                Navigator.of(context).pop();
                toast(
                  context,
                  'Devis de ${fcfa(v)} envoyé à ${r.client}',
                  icon: AppIcons.send,
                );
              },
            ),
            const SizedBox(height: 8),
            PillButton(
              label: 'Décliner',
              tone: ButtonTone.ghost,
              onPressed: () {
                n.decline(r.id);
                Navigator.of(context).pop();
              },
            ),
          ] else if (r.status == RequestStatus.quoted)
            PillButton(
              label: 'Marquer comme confirmée',
              icon: AppIcons.checkCircle,
              tone: ButtonTone.dark,
              onPressed: () {
                n.confirm(r.id);
                Navigator.of(context).pop();
                toast(context, 'Prestation ajoutée à votre agenda');
              },
            )
          else
            Tag(
              label: r.status.label,
              hue: r.status == RequestStatus.confirmed ? Hue.lagoon : Hue.ink,
            ),
        ],
      ),
    );
  }
}

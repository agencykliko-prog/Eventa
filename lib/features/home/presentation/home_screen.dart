import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatars.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/ui.dart';
import '../../auth/presentation/session_provider.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/presentation/payment_sheet.dart';
import '../../dashboard/presentation/widgets/budget_overview.dart';
import '../../events/domain/models.dart';
import '../../events/presentation/events_providers.dart';
import '../../events/presentation/widgets/event_card.dart';
import 'notifications_sheet.dart';

/// Accueil Organisateur. Ordre de lecture : l'événement qui arrive, son
/// budget, les prochaines échéances, ce qui demande une action, puis les
/// autres événements.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Confetti.coral,
          onRefresh: () => ref.read(eventsProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: HomeHeader()),
              ...events.when(
                skipLoadingOnRefresh: true,
                loading: () => const [SliverToBoxAdapter(child: _Loading())],
                error: (e, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorState(
                      onRetry: () => ref.invalidate(eventsProvider),
                    ),
                  ),
                ],
                data: (list) => list.isEmpty
                    ? [
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _Empty(),
                        ),
                      ]
                    : _content(context, ref, list),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref, List<Event> list) {
    final sorted = [...list]..sort((a, b) => a.date.compareTo(b.date));
    final next = sorted.firstWhere(
      (e) => daysUntil(e.date) >= 0,
      orElse: () => sorted.first,
    );
    final others = sorted.where((e) => e.id != next.id).toList();

    final deadlines = [
      for (final e in sorted)
        for (final t in e.tasks)
          if (!t.done) (e, t),
    ]..sort((a, b) => a.$2.due.compareTo(b.$2.due));

    final payments = [
      for (final e in sorted)
        if (e.nextPayment != null) (e, e.nextPayment!),
    ]..sort((a, b) => a.$2.due.compareTo(b.$2.due));
    final quotes = ref
        .watch(bookingsProvider)
        .where(
          (b) => b.step == BookingStep.quoted || b.step == BookingStep.reserved,
        )
        .toList();
    final pendingRsvp = next.guests.pending;

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        sliver: SliverToBoxAdapter(
          child: Entrance(
            child: SizedBox(
              height: 300,
              child: EventCard(
                event: next,
                onTap: () => context.push(Routes.event(next.id)),
              ),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SectionTitle(
          'Budget',
          action: next.name,
          onAction: () => context.push(Routes.budget(next.id)),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: Entrance(
            index: 1,
            child: BudgetOverview(
              event: next,
              onTap: () => context.push(Routes.budget(next.id)),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SectionTitle(
          'Prochaines échéances',
          action: 'Agenda',
          onAction: () => context.go(Routes.planning),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (final (i, (e, t)) in deadlines.take(4).indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  _DeadlineRow(
                    event: e,
                    task: t,
                    onToggle: () => ref
                        .read(eventsProvider.notifier)
                        .toggleTask(e.id, t.id),
                    onTap: () => context.push(Routes.event(e.id)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SectionTitle('À faire en priorité')),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.list(
          children: [
            for (final b in quotes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActionRow(
                  icon: AppIcons.file,
                  hue: Hue.mango,
                  title: b.step == BookingStep.quoted
                      ? 'Devis reçu · ${b.vendor.name}'
                      : 'Acompte à régler · ${b.vendor.name}',
                  caption: b.quote == null
                      ? ''
                      : fcfa(
                          b.step == BookingStep.quoted
                              ? b.quote!.total
                              : b.quote!.deposit,
                        ),
                  action: b.step == BookingStep.quoted ? 'Voir' : 'Payer',
                  onTap: () => context.push(Routes.booking(b.id)),
                ),
              ),
            if (payments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActionRow(
                  icon: AppIcons.coins,
                  hue: Hue.lagoon,
                  title: payments.first.$2.label,
                  caption:
                      '${fcfa(payments.first.$2.amount)} · ${relativeDue(payments.first.$2.due).toLowerCase()}',
                  action: 'Payer',
                  onTap: () =>
                      _pay(context, ref, payments.first.$1, payments.first.$2),
                ),
              ),
            if (pendingRsvp > 0)
              _ActionRow(
                icon: AppIcons.guests,
                hue: Hue.coral,
                title: '$pendingRsvp invités sans réponse',
                caption: next.name,
                action: 'Relancer',
                onTap: () => toast(
                  context,
                  'Relance WhatsApp envoyée à $pendingRsvp invités',
                  icon: AppIcons.whatsapp,
                ),
              ),
          ],
        ),
      ),
      if (others.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionTitle(
            'Mes événements',
            action: 'Nouveau',
            onAction: () => context.push(Routes.newEvent),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Panel(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  for (final (i, e) in others.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    _EventRow(event: e),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ];
  }

  void _pay(BuildContext context, WidgetRef ref, Event e, Payment p) {
    showPaymentSheet(
      context,
      title: p.label,
      payee: p.label.replaceFirst('Solde ', ''),
      options: [PayOption('Solde', p.amount)],
      onPay: (amount, m) {
        final r = Receipt(
          ref: receiptRef(),
          label: p.label,
          amount: amount,
          method: m,
          date: DateTime.now(),
          payee: p.label.replaceFirst('Solde ', ''),
        );
        ref
            .read(eventsProvider.notifier)
            .addExpense(
              e.id,
              Expense(
                id: r.ref,
                category: BudgetCategory.music,
                label: p.label,
                amount: amount,
                date: r.date,
                method: m.label,
              ),
            );
        return r;
      },
    );
  }
}

/// En-tête commun aux deux profils : photo, salutation, notifications.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final plan = ref.watch(planProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
      child: Row(
        children: [
          Pressable(
            onTap: () => context.go(Routes.account),
            child: Avatar(
              image: p.photoAsset,
              bytes: p.photoBytes,
              initials: p.initials,
              size: 44,
              ring: Confetti.cream,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle ?? '${greeting()},',
                  style: context.text.bodyMedium?.copyWith(
                    color: Confetti.inkMuted,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.isCreator
                            ? (p.creator?.displayName ?? p.name)
                            : p.firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.headlineSmall,
                      ),
                    ),
                    if (plan != Plan.free) ...[
                      const SizedBox(width: 8),
                      PremiumBadge(label: plan.label),
                    ],
                  ],
                ),
              ],
            ),
          ),
          RoundIconButton(
            icon: AppIcons.bell,
            tooltip: 'Notifications',
            badge: true,
            onTap: () => showNotificationsSheet(context),
          ),
        ],
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({
    required this.event,
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

  final Event event;
  final EventTask task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = task.due.isBefore(DateTime.now());
    return Pressable(
      scale: 0.99,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeOf(task.due),
                    style: context.text.titleSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    relativeDue(task.due),
                    style: context.text.labelSmall?.copyWith(
                      color: overdue ? Confetti.danger : Confetti.inkFaint,
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
                color: event.category.hue.base,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            Pressable(
              scale: 0.85,
              onTap: onToggle,
              semanticLabel: 'Marquer comme terminée',
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC9C2D8),
                    width: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.hue,
    required this.title,
    required this.caption,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final Hue hue;
  final String title;
  final String caption;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          IconTile(icon: icon, hue: hue, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
                if (caption.isNotEmpty)
                  Text(caption, style: context.text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PillButton(
            label: action,
            tone: ButtonTone.dark,
            expand: false,
            height: 36,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.99,
      onTap: () => context.push(Routes.event(event.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                event.cover,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  Text(
                    '${mediumDate(event.date)} · ${timeOf(event.date)}',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              countdownLabel(event.date),
              style: context.text.titleSmall?.copyWith(
                color: event.category.hue.text,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(AppIcons.chevron, size: 14, color: Confetti.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
    child: Column(
      children: [
        Skeleton(height: 300, radius: 28),
        SizedBox(height: 24),
        Skeleton(height: 150, radius: 22),
        SizedBox(height: 24),
        Skeleton(height: 180, radius: 22),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Votre première fête commence ici',
          style: context.text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Créez un événement : on prépare la checklist et le budget selon son type.',
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(color: Confetti.inkMuted),
        ),
        const SizedBox(height: 20),
        PillButton(
          label: 'Créer un événement',
          icon: AppIcons.add,
          expand: false,
          onPressed: () => context.push(Routes.newEvent),
        ),
      ],
    ),
  );
}

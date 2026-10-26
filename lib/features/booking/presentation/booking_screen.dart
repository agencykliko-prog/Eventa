import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/ui.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/presentation/payment_sheet.dart';
import '../../events/presentation/events_providers.dart';
import '../../premium/presentation/paywall.dart';

/// Parcours de réservation en 7 étapes, sur un seul écran : chaque étape
/// affiche son contenu et une seule action principale.
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  bool _accepted = false;
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  BookingsNotifier get _n => ref.read(bookingsProvider.notifier);

  Future<void> _pay(Booking b, {required bool balance}) async {
    final q = b.quote!;
    final options = balance
        ? [PayOption('Solde', b.balance)]
        : [
            PayOption('Acompte 30 %', q.deposit, caption: 'Solde à J-7'),
            PayOption('Montant total', q.total, caption: 'En une fois'),
          ];
    final r = await showPaymentSheet(
      context,
      title: balance
          ? 'Solde ${b.vendor.name}'
          : 'Réservation ${b.vendor.name}',
      payee: b.vendor.name,
      options: options,
      onPay: (amount, m) => _n.pay(b.id, amount, m),
    );
    if (r != null && mounted) {
      toast(context, 'Paiement confirmé · reçu ${r.ref}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = ref.watch(bookingProvider(widget.id));
    if (b == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Réservation introuvable')),
      );
    }
    final event = ref.watch(eventProvider(b.eventId)).value;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  onTap: () => context.pop(),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    b.vendor.image,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.vendor.name,
                        style: context.text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        event?.name ?? '',
                        style: context.text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StepTrack(step: b.step),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: Motion.base,
              switchInCurve: Motion.easeOut,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(b.step),
                child: _stepBody(context, b),
              ),
            ),
            if (b.receipts.isNotEmpty) ...[
              const SizedBox(height: 26),
              Text('Reçus', style: context.text.titleLarge),
              const SizedBox(height: 10),
              for (final r in b.receipts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Panel(
                    padding: const EdgeInsets.all(14),
                    onTap: () => showEventaSheet<void>(
                      context,
                      builder: (ctx) => ReceiptView(
                        receipt: r,
                        onDone: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    child: Row(
                      children: [
                        const IconTile(
                          icon: AppIcons.receipt,
                          hue: Hue.lagoon,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.label, style: context.text.titleSmall),
                              Text(
                                '${r.ref} · ${r.method.label}',
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(fcfa(r.total), style: context.text.titleSmall),
                      ],
                    ),
                  ),
                ),
            ],
            if (b.step.index >= BookingStep.requested.index) ...[
              const SizedBox(height: 26),
              Text('Échanges', style: context.text.titleLarge),
              const SizedBox(height: 10),
              _Thread(messages: b.messages),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      decoration: const InputDecoration(
                        hintText: 'Écrire au prestataire…',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                      ),
                      onSubmitted: (_) => _send(b),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RoundIconButton(
                    icon: AppIcons.send,
                    background: Confetti.ink,
                    foreground: Colors.white,
                    size: 48,
                    tooltip: 'Envoyer',
                    onTap: () => _send(b),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _send(Booking b) {
    final t = _composer.text.trim();
    if (t.isEmpty) return;
    _n.message(b.id, t);
    _composer.clear();
  }

  Widget _stepBody(BuildContext context, Booking b) {
    switch (b.step) {
      case BookingStep.selected:
      case BookingStep.requested:
        return _Waiting(
          vendor: b.vendor.name,
          responseTime: b.vendor.responseTime,
        );
      case BookingStep.quoted:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _QuoteCard(quote: b.quote!),
            const SizedBox(height: 14),
            Pressable(
              onTap: () => setState(() => _accepted = !_accepted),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: Motion.fast,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _accepted ? Confetti.ink : Colors.white,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: _accepted
                            ? Confetti.ink
                            : const Color(0xFFCBC5DA),
                        width: 1.6,
                      ),
                    ),
                    child: _accepted
                        ? const Icon(
                            AppIcons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'J’accepte les conditions du devis et la politique d’annulation.',
                      style: context.text.bodySmall?.copyWith(
                        color: Confetti.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PillButton(
              label: 'Accepter et réserver',
              icon: AppIcons.calendarCheck,
              onPressed: _accepted
                  ? () {
                      _n.accept(b.id);
                      toast(
                        context,
                        'Date bloquée le ${mediumDate(b.request.date)}',
                      );
                    }
                  : null,
            ),
            const SizedBox(height: 10),
            PillButton(
              label: 'Négocier avec l’agent IA',
              icon: AppIcons.sparkle,
              tone: ButtonTone.ghost,
              onPressed: () => requirePremium(
                context,
                ref,
                feature: PremiumFeature.agent,
                eventId: b.eventId,
                onUnlocked: () {
                  final saved = _n.negotiate(b.id);
                  toast(
                    context,
                    'Remise obtenue : ${fcfa(saved)}',
                    icon: AppIcons.sparkle,
                  );
                },
              ),
            ),
          ],
        );
      case BookingStep.reserved:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(
              icon: AppIcons.calendarCheck,
              hue: Hue.violet,
              title: 'Date bloquée',
              text:
                  '${b.vendor.name} réserve le ${longDate(b.request.date)} pour vous. '
                  'Réglez l’acompte pour confirmer définitivement.',
            ),
            const SizedBox(height: 12),
            _QuoteCard(quote: b.quote!, compact: true),
            const SizedBox(height: 14),
            PillButton(
              label: 'Payer en toute sécurité',
              icon: AppIcons.lock,
              onPressed: () => _pay(b, balance: false),
            ),
          ],
        );
      case BookingStep.paid:
      case BookingStep.executing:
        final days = daysUntil(b.request.date);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(
              icon: AppIcons.checkCircle,
              hue: Hue.lagoon,
              title: 'Réservation confirmée',
              text:
                  'Payé ${fcfa(b.paidAmount)} sur ${fcfa(b.quote!.total)}. '
                  '${b.balance > 0 ? 'Reste ${fcfa(b.balance)} à régler avant J-7.' : 'Tout est réglé.'}',
            ),
            const SizedBox(height: 16),
            Text('Suivi', style: context.text.titleLarge),
            const SizedBox(height: 10),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  _FollowRow(
                    icon: AppIcons.reminder,
                    title: 'Rappel solde',
                    caption: days > 7
                        ? 'Dans ${days - 7} jours (J-7)'
                        : 'À régler maintenant',
                    done: b.balance <= 0,
                  ),
                  const Divider(height: 1),
                  _FollowRow(
                    icon: AppIcons.message,
                    title: 'Brief final avec le prestataire',
                    caption: days > 14 ? 'Programmé à J-14' : 'Cette semaine',
                    done: false,
                  ),
                  const Divider(height: 1),
                  _FollowRow(
                    icon: AppIcons.bell,
                    title: 'Notifications',
                    caption: 'Arrivée et installation le jour J',
                    done: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (b.balance > 0)
              PillButton(
                label: 'Payer le solde · ${fcfa(b.balance)}',
                icon: AppIcons.lock,
                onPressed: () => _pay(b, balance: true),
              )
            else
              PillButton(
                label: 'Valider la prestation et clôturer',
                icon: AppIcons.checkCircle,
                tone: ButtonTone.dark,
                onPressed: () {
                  _n.close(b.id);
                  toast(
                    context,
                    'Reversement envoyé à ${b.vendor.name}',
                    icon: AppIcons.bank,
                  );
                },
              ),
          ],
        );
      case BookingStep.closed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(
              icon: AppIcons.bank,
              hue: Hue.lagoon,
              title: 'Prestataire payé',
              text:
                  'Reversement automatique de ${fcfa(b.quote!.subtotal)} effectué à ${b.vendor.name} '
                  'après votre validation.',
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(
                children: [
                  Text(
                    b.rating == null
                        ? 'Comment s’est passée la prestation ?'
                        : 'Merci pour votre avis !',
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Pressable(
                          scale: 0.85,
                          onTap: () => _n.review(b.id, i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              (b.rating ?? 0) >= i
                                  ? AppIcons.star
                                  : AppIcons.starLine,
                              size: 32,
                              color: Confetti.mango,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PillButton(
              label: b.archived ? 'Dossier archivé' : 'Archiver le dossier',
              icon: AppIcons.archive,
              tone: ButtonTone.ghost,
              onPressed: b.archived
                  ? null
                  : () {
                      _n.archive(b.id);
                      toast(
                        context,
                        'Dossier archivé dans le coffre-fort',
                        icon: AppIcons.archive,
                      );
                    },
            ),
          ],
        );
    }
  }
}

class _StepTrack extends StatelessWidget {
  const _StepTrack({required this.step});

  final BookingStep step;

  @override
  Widget build(BuildContext context) {
    final i = step.index;
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Étape ${i + 1} sur 7',
                style: context.text.labelSmall?.copyWith(
                  color: context.eventa.muted,
                ),
              ),
              const Spacer(),
              Text(
                step.status,
                style: context.text.labelMedium?.copyWith(
                  color: Confetti.violetText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var s = 0; s < BookingStep.values.length; s++) ...[
                if (s > 0) const SizedBox(width: 4),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: s <= i ? 1 : 0),
                    duration: Duration(milliseconds: 380 + s * 60),
                    curve: Motion.easeOut,
                    builder: (context, t, _) => Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Confetti.lavender,
                          s == i ? Confetti.violet : Confetti.ink,
                          t,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var s = 0; s < BookingStep.values.length; s++)
                Expanded(
                  child: Text(
                    BookingStep.values[s].label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: context.text.labelSmall?.copyWith(
                      fontSize: 9,
                      color: s <= i ? Confetti.ink : Confetti.inkFaint,
                      fontWeight: s == i ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Waiting extends StatefulWidget {
  const _Waiting({required this.vendor, required this.responseTime});

  final String vendor;
  final String responseTime;

  @override
  State<_Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<_Waiting>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          RotationTransition(
            turns: CurvedAnimation(parent: _c, curve: Motion.easeInOut),
            child: const IconTile(
              icon: AppIcons.hourglass,
              hue: Hue.violet,
              size: 56,
            ),
          ),
          const SizedBox(height: 14),
          Text('Demande envoyée', style: context.text.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${widget.vendor} prépare votre devis. Réponse moyenne en ${widget.responseTime}.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 18),
          const Skeleton(height: 14),
          const SizedBox(height: 8),
          const Skeleton(height: 14, width: 200),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote, this.compact = false});

  final Quote quote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    Widget row(
      String a,
      int b, {
      bool strong = false,
      bool muted = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              a,
              style: strong
                  ? context.text.titleMedium
                  : context.text.bodyMedium?.copyWith(
                      color: muted ? Confetti.inkMuted : null,
                    ),
            ),
          ),
          Text(
            fcfa(b),
            style: (strong ? context.text.titleMedium : context.text.titleSmall)
                ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
    return Panel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(icon: AppIcons.file, hue: Hue.mango, size: 36),
              const SizedBox(width: 10),
              Expanded(child: Text('Devis', style: context.text.titleLarge)),
              Tag(
                label: 'Valable jusqu’au ${shortDate(q.validUntil)}',
                hue: Hue.mango,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!compact) ...[
            for (final l in q.lines)
              row(l.optional ? 'Option · ${l.label}' : l.label, l.amount),
            row('Frais de service', q.fees, muted: true),
            const Divider(height: 18),
          ],
          row('Total', q.total, strong: true),
          row('Acompte (30 %)', q.deposit, muted: true),
          if (!compact) ...[
            const SizedBox(height: 12),
            Text('Conditions', style: context.text.labelMedium),
            const SizedBox(height: 6),
            for (final c in q.conditions)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        AppIcons.check,
                        size: 13,
                        color: Confetti.lagoonText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c, style: context.text.bodySmall)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.hue,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Hue hue;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Panel(
      color: hue.tint,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, hue: hue, size: 40, solid: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.titleMedium?.copyWith(color: hue.deep),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: context.text.bodySmall?.copyWith(color: hue.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowRow extends StatelessWidget {
  const _FollowRow({
    required this.icon,
    required this.title,
    required this.caption,
    required this.done,
  });

  final IconData icon;
  final String title;
  final String caption;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: done ? Confetti.lagoon : Confetti.inkMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(caption, style: context.text.bodySmall),
              ],
            ),
          ),
          if (done)
            const Icon(AppIcons.checkCircle, size: 18, color: Confetti.lagoon),
        ],
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({required this.messages});

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final m in messages)
          Align(
            alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 290),
              decoration: BoxDecoration(
                color: m.fromMe ? Confetti.ink : Colors.white,
                border: m.fromMe ? null : Border.all(color: Confetti.line),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(m.fromMe ? 18 : 4),
                  bottomRight: Radius.circular(m.fromMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.text,
                    style: context.text.bodyMedium?.copyWith(
                      color: m.fromMe ? Colors.white : Confetti.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timeOf(m.at),
                    style: context.text.labelSmall?.copyWith(
                      color: m.fromMe ? Colors.white54 : Confetti.inkFaint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/ui.dart';
import '../../commerce/data/catalog.dart';
import '../../events/data/event_templates.dart';
import '../../events/domain/models.dart';
import '../../events/presentation/events_providers.dart';

/// Agent IA spécialisé par famille d'événements (Premium).
/// Démonstration : les réponses sont calculées à partir des données de
/// l'événement, sans appel à un modèle de langage.
class AgentScreen extends ConsumerStatefulWidget {
  const AgentScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<AgentScreen> createState() => _AgentScreenState();
}

class _Msg {
  const _Msg(this.fromAgent, this.text, {this.bullets = const [], this.action});
  final bool fromAgent;
  final String text;
  final List<String> bullets;
  final (String, VoidCallback)? action;
}

class _AgentScreenState extends ConsumerState<AgentScreen> {
  final _msgs = <_Msg>[];
  final _scroll = ScrollController();
  bool _thinking = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _run(Event e, AgentSkill skill) async {
    setState(() {
      _msgs.add(_Msg(false, skill.label));
      _thinking = true;
    });
    _toEnd();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _msgs.add(_answer(e, skill.action));
    });
    _toEnd();
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: Motion.base,
        curve: Motion.easeOut,
      );
    }
  });

  _Msg _answer(Event e, AgentAction a) {
    final n = ref.read(eventsProvider.notifier);
    final g = e.guests;
    switch (a) {
      case AgentAction.budget:
        final lines = EventTemplates.aiBudget(e);
        return _Msg(
          true,
          'Voici une répartition de ${fcfa(e.targetBudget)} adaptée à ${g.invited} invités, '
          'en conservant vos ${fcfa(e.committed)} déjà engagés.',
          bullets: [
            for (final l in lines.take(6))
              '${l.category.label} : ${fcfa(l.estimated)}',
          ],
          action: (
            'Appliquer au budget',
            () {
              n.replaceBudget(e.id, lines);
              toast(
                context,
                'Budget mis à jour par l’IA',
                icon: AppIcons.sparkle,
              );
            },
          ),
        );
      case AgentAction.negotiate:
        final quoted = e.vendors
            .where((v) => v.status == VendorStatus.quoted)
            .toList();
        return _Msg(
          true,
          quoted.isEmpty
              ? 'Aucun devis en attente. Dès qu’un prestataire répond, je compare son prix au marché et je négocie pour vous.'
              : 'J’ai analysé ${quoted.length} devis en attente. Le prix de ${quoted.first.vendor.name} est 9 % au-dessus de la moyenne observée pour sa catégorie.',
          bullets: [
            if (quoted.isNotEmpty)
              'Proposition : ${fcfa((quoted.first.amount * 0.93).round())} au lieu de ${fcfa(quoted.first.amount)}',
            if (quoted.isNotEmpty)
              'Argument : réservation ferme sous 48 h et acompte immédiat',
          ],
        );
      case AgentAction.savings:
        final drinks = e.line(BudgetCategory.drinks)?.estimated ?? 0;
        final deco = e.line(BudgetCategory.decor)?.estimated ?? 0;
        return _Msg(
          true,
          'Trois pistes d’économies sans toucher à l’essentiel :',
          bullets: [
            if (drinks > 0)
              'Boissons : forfait « softs + jus locaux » chez le traiteur, environ ${fcfa((drinks * 0.18).round())} économisés',
            if (deco > 0)
              'Décoration : réutiliser l’arche de la cérémonie pour la réception, environ ${fcfa((deco * 0.12).round())}',
            'Papeterie : faire-part digital + 30 cartons imprimés pour les aînés, environ 120 000 FCFA',
          ],
        );
      case AgentAction.planning:
        final open = e.tasks.where((t) => !t.done).toList()
          ..sort((a, b) => a.due.compareTo(b.due));
        return _Msg(
          true,
          'Planning des 3 prochaines semaines, jalons critiques en premier :',
          bullets: [
            for (final t in open.take(5)) '${shortDate(t.due)} · ${t.title}',
          ],
        );
      case AgentAction.seating:
        final tables = (g.confirmed / 10).ceil();
        return _Msg(
          true,
          'Pour ${g.confirmed} invités confirmés : $tables tables rondes de 10, plus une table d’honneur.',
          bullets: const [
            'Table d’honneur : mariés, témoins, parents',
            'Tables 1 à 4 : aînés des deux familles, près de la scène',
            'Collègues et amis regroupés, enfants près des parents',
            'À séparer : 2 contraintes signalées par la famille',
          ],
        );
      case AgentAction.invitations:
        return _Msg(
          true,
          'Proposition de faire-part :',
          bullets: [
            '« Les familles ont la joie de vous convier à ${e.name}, le ${longDate(e.date)}, à ${e.venue}. »',
            'Version WhatsApp courte avec lien RSVP et plan d’accès',
            'Version imprimée pour les aînés',
          ],
        );
      case AgentAction.guestMessage:
        return _Msg(
          true,
          'Message prêt pour les ${g.pending} invités qui n’ont pas répondu :',
          bullets: [
            'Bonjour, nous serions ravis de vous compter parmi nous le ${shortDate(e.date)} pour ${e.name}. '
                'Merci de confirmer votre présence avant le ${shortDate(e.date.subtract(const Duration(days: 21)))}.',
          ],
          action: (
            'Envoyer sur WhatsApp',
            () => toast(
              context,
              'Relance envoyée à ${g.pending} invités',
              icon: AppIcons.whatsapp,
            ),
          ),
        );
      case AgentAction.remaining:
        return _Msg(
          true,
          'Où en est l’argent :',
          bullets: [
            'Payé : ${fcfa(e.paid)}',
            'Reste à payer aux prestataires : ${fcfa(e.remainingToPay)}',
            'Reste à dépenser sur le budget cible : ${fcfa(e.remainingToSpend)}',
            'Disponible non engagé : ${fcfa(e.available)}',
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = ref.watch(eventProvider(widget.eventId)).value;
    if (e == null) return const Scaffold(body: SizedBox());
    final agent = Catalog.agent(e.category);
    final hue = e.category.hue;
    return Scaffold(
      backgroundColor: Confetti.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: AppIcons.back,
                    tooltip: 'Retour',
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(agent.name, style: context.text.titleMedium),
                        Text(
                          e.name,
                          style: context.text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const PremiumBadge(compact: true),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  NightPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: hue.base,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                AppIcons.sparkle,
                                color: hue.onBase,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                agent.name,
                                style: context.text.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          agent.pitch,
                          style: context.text.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Je connais votre budget, vos tâches, vos invités et vos devis.',
                          style: context.text.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final (i, m) in _msgs.indexed)
                    Entrance(
                      key: ValueKey(i),
                      child: _Bubble(msg: m, hue: hue),
                    ),
                  if (_thinking) const _Typing(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Confetti.line)),
              ),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: agent.skills.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final s = agent.skills[i];
                    return Pressable(
                      onTap: _thinking ? null : () => _run(e, s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Confetti.cream,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: Confetti.line),
                        ),
                        child: Row(
                          children: [
                            Icon(s.icon, size: 16, color: hue.text),
                            const SizedBox(width: 6),
                            Text(s.label, style: context.text.labelMedium),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, required this.hue});

  final _Msg msg;
  final Hue hue;

  @override
  Widget build(BuildContext context) {
    if (!msg.fromAgent) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Confetti.ink,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            msg.text,
            style: context.text.bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12, right: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Confetti.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.sparkle, size: 14, color: hue.text),
              const SizedBox(width: 6),
              Text(
                'Agent IA',
                style: context.text.labelSmall?.copyWith(color: hue.text),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(msg.text, style: context.text.bodyMedium),
          if (msg.bullets.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final b in msg.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 7),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: hue.base,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: context.text.bodyMedium?.copyWith(
                          color: Confetti.ink.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (msg.action != null) ...[
            const SizedBox(height: 8),
            PillButton(
              label: msg.action!.$1,
              tone: ButtonTone.dark,
              height: 42,
              expand: false,
              onPressed: msg.action!.$2,
            ),
          ],
        ],
      ),
    );
  }
}

class _Typing extends StatefulWidget {
  const _Typing();

  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Confetti.line),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Opacity(
                  opacity: 0.3 + 0.7 * (((_c.value * 3 - i) % 3) < 1 ? 1 : 0),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Confetti.inkMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

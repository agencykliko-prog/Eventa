import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/donut.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/ui.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../dashboard/presentation/widgets/budget_overview.dart';
import '../../events/data/event_templates.dart';
import '../../events/domain/models.dart';
import '../../events/presentation/events_providers.dart';
import '../../export/export_sheet.dart';
import '../../premium/presentation/paywall.dart';

/// Palette de répartition : couleurs de la marque, du plus foncé au plus clair.
const chartColors = [
  Confetti.violet,
  Confetti.lagoon,
  Confetti.coral,
  Confetti.mango,
  Confetti.candy,
  Confetti.violetDeep,
  Confetti.lagoonDeep,
  Color(0xFF8E7CF0),
  Color(0xFF52C4B5),
  Color(0xFFF08A8D),
  Color(0xFFF0C46A),
  Color(0xFFE88BC1),
  Confetti.inkMuted,
  Confetti.inkFaint,
  Confetti.night,
];

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  int? _highlight;
  bool _byPaid = false;
  bool _generating = false;

  EventsNotifier get _n => ref.read(eventsProvider.notifier);

  Future<void> _generate(Event e) async {
    setState(() => _generating = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    _n.replaceBudget(e.id, EventTemplates.aiBudget(e));
    setState(() => _generating = false);
    toast(
      context,
      'Budget optimisé par l’IA pour ${e.guests.invited} invités',
      icon: AppIcons.sparkle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eventProvider(widget.id));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Confetti.coral),
          ),
          error: (e, _) =>
              ErrorState(onRetry: () => ref.invalidate(eventsProvider)),
          data: (e) => e == null ? const SizedBox() : _body(e),
        ),
      ),
      floatingActionButton: async.value == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Confetti.ink,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: const StadiumBorder(),
              onPressed: () => _expenseSheet(async.value!),
              icon: const Icon(AppIcons.add, size: 20),
              label: const Text(
                'Dépense',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _body(Event e) {
    final lines = [...e.budget]
      ..sort((a, b) => b.estimated.compareTo(a.estimated));
    final values = [
      for (final l in lines) (_byPaid ? l.paid : l.estimated).toDouble(),
    ];
    final total = values.fold<double>(0, (s, v) => s + v);
    return ListView(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budget', style: context.text.titleLarge),
                  Text(e.name, style: context.text.bodySmall),
                ],
              ),
            ),
            RoundIconButton(
              icon: AppIcons.download,
              tooltip: 'Exporter',
              onTap: () => showExportSheet(context, e.id),
            ),
          ],
        ),
        const SizedBox(height: 18),
        BudgetOverview(event: e, onEditTarget: () => _targetSheet(e)),
        const SizedBox(height: 12),
        // Création par l'IA (Premium) ou manuelle.
        NightPanel(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Confetti.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  AppIcons.sparkle,
                  color: Confetti.gold,
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Budget par l’IA',
                          style: context.text.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const PremiumBadge(compact: true, onDark: true),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Répartition optimisée selon le type, la ville et le nombre d’invités.',
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              PillButton(
                label: 'Générer',
                tone: ButtonTone.gold,
                expand: false,
                height: 40,
                loading: _generating,
                onPressed: () => requirePremium(
                  context,
                  ref,
                  feature: PremiumFeature.aiBudget,
                  eventId: e.id,
                  onUnlocked: () => _generate(e),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text('Répartition', style: context.text.titleLarge),
            ),
            _Toggle(
              left: 'Prévu',
              right: 'Payé',
              rightOn: _byPaid,
              onChanged: (v) => setState(() {
                _byPaid = v;
                _highlight = null;
              }),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Panel(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Donut(
                key: ValueKey(_byPaid),
                size: 170,
                thickness: 20,
                highlight: _highlight,
                slices: [
                  for (var i = 0; i < lines.length; i++)
                    DonutSlice(values[i], chartColors[i % chartColors.length]),
                ],
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _highlight == null
                          ? (_byPaid ? 'Payé' : 'Prévu')
                          : lines[_highlight!].category.label,
                      style: context.text.labelSmall?.copyWith(
                        color: context.eventa.muted,
                      ),
                    ),
                    Text(
                      fcfaCompact(
                        _highlight == null ? total : values[_highlight!],
                      ),
                      style: context.text.headlineSmall,
                    ),
                    if (_highlight != null && total > 0)
                      Text(
                        '${(values[_highlight!] / total * 100).round()} %',
                        style: context.text.labelMedium?.copyWith(
                          color: context.eventa.muted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < lines.length; i++)
                    Pressable(
                      onTap: () => setState(
                        () => _highlight = _highlight == i ? null : i,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: chartColors[i % chartColors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            lines[i].category.label,
                            style: context.text.labelSmall?.copyWith(
                              color: _highlight == null || _highlight == i
                                  ? Confetti.ink
                                  : Confetti.inkFaint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Text('Postes', style: context.text.titleLarge)),
            Pressable(
              onTap: () => _lineSheet(e, null),
              child: Row(
                children: [
                  const Icon(AppIcons.add, size: 16, color: Confetti.coralDeep),
                  const SizedBox(width: 4),
                  Text(
                    'Ajouter un poste',
                    style: context.text.labelMedium?.copyWith(
                      color: Confetti.coralDeep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Entrance(
              index: i.clamp(0, 8),
              child: _LineTile(
                line: lines[i],
                color: chartColors[i % chartColors.length],
                onTap: () => _lineSheet(e, lines[i]),
              ),
            ),
          ),
        if (e.expenses.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Dépenses réglées', style: context.text.titleLarge),
          const SizedBox(height: 12),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (final (i, x) in e.expenses.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        IconTile(
                          icon: x.category.icon,
                          hue: Hue.lagoon,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(x.label, style: context.text.titleSmall),
                              Text(
                                '${shortDate(x.date)} · ${x.method}',
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '− ${fcfa(x.amount)}',
                          style: context.text.titleSmall?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Feuilles ────────────────────────────────────────────────────────

  void _targetSheet(Event e) {
    final c = TextEditingController(text: '${e.targetBudget}');
    showEventaSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget total', style: ctx.text.headlineSmall),
            Text(
              'Saisissez le montant maximal que vous souhaitez dépenser.',
              style: ctx.text.bodySmall,
            ),
            const SizedBox(height: 14),
            _AmountField(controller: c, autofocus: true),
            const SizedBox(height: 16),
            PillButton(
              label: 'Enregistrer',
              tone: ButtonTone.dark,
              onPressed: () {
                _n.setTarget(e.id, int.tryParse(c.text) ?? e.targetBudget);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _lineSheet(Event e, BudgetLine? line) {
    final used = {for (final l in e.budget) l.category};
    var category =
        line?.category ??
        BudgetCategory.values.firstWhere(
          (c) => !used.contains(c),
          orElse: () => BudgetCategory.contingency,
        );
    final est = TextEditingController(text: '${line?.estimated ?? 0}');
    final com = TextEditingController(text: '${line?.committed ?? 0}');
    final note = TextEditingController(text: line?.note ?? '');
    showEventaSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line == null ? 'Nouveau poste' : line.category.label,
                style: ctx.text.headlineSmall,
              ),
              if (line != null)
                Text(
                  'Payé : ${fcfa(line.paid)} (mis à jour par les dépenses)',
                  style: ctx.text.bodySmall,
                ),
              const SizedBox(height: 14),
              if (line == null) ...[
                Text('Catégorie', style: ctx.text.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in BudgetCategory.values.where(
                      (c) => !used.contains(c),
                    ))
                      Pressable(
                        onTap: () => set(() => category = c),
                        child: AnimatedContainer(
                          duration: Motion.fast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: category == c ? Confetti.ink : Colors.white,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: category == c
                                  ? Confetti.ink
                                  : Confetti.line,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                c.icon,
                                size: 14,
                                color: category == c
                                    ? Colors.white
                                    : Confetti.inkMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                c.label,
                                style: ctx.text.labelMedium?.copyWith(
                                  color: category == c
                                      ? Colors.white
                                      : Confetti.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              Text('Montant prévu', style: ctx.text.labelMedium),
              const SizedBox(height: 8),
              _AmountField(controller: est),
              const SizedBox(height: 12),
              Text(
                'Montant engagé (devis accepté)',
                style: ctx.text.labelMedium,
              ),
              const SizedBox(height: 8),
              _AmountField(controller: com),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                  hintText: 'Note (facultatif)',
                ),
              ),
              const SizedBox(height: 16),
              PillButton(
                label: line == null ? 'Ajouter le poste' : 'Enregistrer',
                tone: ButtonTone.dark,
                onPressed: () {
                  _n.upsertLine(
                    e.id,
                    BudgetLine(
                      category: category,
                      estimated: int.tryParse(est.text) ?? 0,
                      committed: int.tryParse(com.text) ?? 0,
                      paid: line?.paid ?? 0,
                      note: note.text.trim().isEmpty ? null : note.text.trim(),
                    ),
                  );
                  Navigator.of(ctx).pop();
                },
              ),
              if (line != null && line.paid == 0) ...[
                const SizedBox(height: 8),
                PillButton(
                  label: 'Supprimer le poste',
                  icon: AppIcons.trash,
                  tone: ButtonTone.ghost,
                  onPressed: () {
                    _n.removeLine(e.id, line.category);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _expenseSheet(Event e) {
    var category = e.budget.isEmpty
        ? BudgetCategory.contingency
        : e.budget.first.category;
    var method = PayMethod.wave;
    final label = TextEditingController();
    final amount = TextEditingController();
    showEventaSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouvelle dépense', style: ctx.text.headlineSmall),
              Text(
                'Hors plateforme : espèces, virement, achat direct…',
                style: ctx.text.bodySmall,
              ),
              const SizedBox(height: 14),
              _AmountField(controller: amount, autofocus: true),
              const SizedBox(height: 12),
              TextField(
                controller: label,
                decoration: const InputDecoration(
                  hintText: 'Libellé (ex. Achat tissu)',
                ),
              ),
              const SizedBox(height: 14),
              Text('Poste', style: ctx.text.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final l in e.budget)
                    Pressable(
                      onTap: () => set(() => category = l.category),
                      child: AnimatedContainer(
                        duration: Motion.fast,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: category == l.category
                              ? Confetti.ink
                              : Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: category == l.category
                                ? Confetti.ink
                                : Confetti.line,
                          ),
                        ),
                        child: Text(
                          l.category.label,
                          style: ctx.text.labelMedium?.copyWith(
                            color: category == l.category
                                ? Colors.white
                                : Confetti.ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              AppSelect<PayMethod>(
                label: 'Payé avec',
                value: method,
                options: PayMethod.values,
                labelOf: (m) =>
                    m.mobileMoney ? 'Mobile Money · ${m.label}' : m.label,
                iconOf: (m) => m.icon,
                onChanged: (m) => set(() => method = m),
              ),
              const SizedBox(height: 18),
              PillButton(
                label: 'Enregistrer la dépense',
                tone: ButtonTone.dark,
                onPressed: () {
                  final v = int.tryParse(amount.text) ?? 0;
                  if (v <= 0) return;
                  _n.addExpense(
                    e.id,
                    Expense(
                      id: 'x-${DateTime.now().microsecondsSinceEpoch}',
                      category: category,
                      label: label.text.trim().isEmpty
                          ? category.label
                          : label.text.trim(),
                      amount: v,
                      date: DateTime.now(),
                      method: method.label,
                    ),
                  );
                  Navigator.of(ctx).pop();
                  toast(context, '${fcfa(v)} ajoutés aux dépenses');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, this.autofocus = false});

  final TextEditingController controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: context.text.titleLarge?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: const InputDecoration(hintText: '0', suffixText: 'FCFA'),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.left,
    required this.right,
    required this.rightOn,
    required this.onChanged,
  });

  final String left;
  final String right;
  final bool rightOn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String l, bool on, bool v) => Pressable(
      onTap: () => onChanged(v),
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          l,
          style: context.text.labelMedium?.copyWith(
            color: on ? Confetti.ink : Confetti.inkMuted,
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Confetti.lavender,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [seg(left, !rightOn, false), seg(right, rightOn, true)],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.color,
    required this.onTap,
  });

  final BudgetLine line;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = line.estimated == 0 ? 1 : line.estimated;
    final status = line.committed == 0
        ? ('À réserver', Hue.ink)
        : line.isOver
        ? ('Dépassement', Hue.coral)
        : line.paid >= line.committed
        ? ('Soldé', Hue.lagoon)
        : ('Acompte versé', Hue.violet);
    return Panel(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(line.category.icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.category.label, style: context.text.titleSmall),
                    Text(
                      line.note ??
                          'Reste à dépenser ${fcfa(line.estimated - line.paid)}',
                      style: context.text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Tag(label: status.$1, hue: status.$2),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Motion.easeOut,
            builder: (context, t, _) => LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                double fr(int v) => (v / base).clamp(0.0, 1.0) * w * t;
                return Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Confetti.lavender,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: fr(line.committed),
                        decoration: BoxDecoration(
                          color: line.isOver
                              ? Confetti.danger
                              : color.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: fr(line.paid),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Payé ${fcfaCompact(line.paid)}',
                style: context.text.labelSmall,
              ),
              const SizedBox(width: 10),
              Text(
                'Engagé ${fcfaCompact(line.committed)}',
                style: context.text.labelSmall?.copyWith(
                  color: context.eventa.muted,
                ),
              ),
              const Spacer(),
              Text(
                'Prévu ${fcfaCompact(line.estimated)}',
                style: context.text.labelSmall?.copyWith(
                  color: context.eventa.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

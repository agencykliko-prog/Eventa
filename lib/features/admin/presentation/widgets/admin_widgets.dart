import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/eventa_colors.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/ui.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';

/// Vérifie la permission avant une action ; sinon explique pourquoi.
bool guard(BuildContext context, WidgetRef ref, AdminPermission p) {
  if (ref.read(adminCanProvider(p))) return true;
  toast(
    context,
    'Action non autorisée pour votre rôle : ${p.label.toLowerCase()}',
    icon: AppIcons.lock,
  );
  return false;
}

/// En-tête de module : titre, description, actions.
class AdminHeader extends StatelessWidget {
  const AdminHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 720;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.headlineMedium),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: context.text.bodyMedium?.copyWith(color: Confetti.inkMuted),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: narrow || actions.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: text),
                const SizedBox(width: 16),
                Wrap(spacing: 8, children: actions),
              ],
            ),
    );
  }
}

/// Indicateur clé : valeur, légende, tendance et mini-courbe.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.icon,
    required this.hue,
    required this.label,
    required this.value,
    required this.caption,
    this.trend,
    this.spark,
    this.live = false,
    this.onTap,
  });

  final IconData icon;
  final Hue hue;
  final String label;
  final String value;
  final String caption;

  /// Variation en % sur la période (positive = hausse).
  final double? trend;
  final List<double>? spark;
  final bool live;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: icon, hue: hue, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
              ),
              if (live) const LiveDot(),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: Motion.fast,
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
            child: FittedBox(
              key: ValueKey(value),
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: context.text.headlineSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (trend != null) ...[
                Text(
                  '${trend! >= 0 ? '+' : ''}${trend!.toStringAsFixed(1).replaceAll('.', ',')} %',
                  style: context.text.labelSmall?.copyWith(
                    color: trend! >= 0 ? Confetti.success : Confetti.danger,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ),
            ],
          ),
          if (spark != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: CustomPaint(
                size: Size.infinite,
                painter: _SparkPainter(spark!, hue.base),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Point qui pulse : donnée en temps réel.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.label = 'Direct'});

  final String label;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 12,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) =>
                CustomPaint(painter: _PulsePainter(_c.value, Confetti.success)),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          widget.label,
          style: context.text.labelSmall?.copyWith(color: Confetti.success),
        ),
      ],
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      3 + t * 3,
      Paint()..color = color.withValues(alpha: (1 - t) * 0.4),
    );
    canvas.drawCircle(c, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce(math.min), hi = values.reduce(math.max);
    final span = hi - lo == 0 ? 1 : hi - lo;
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(
          size.width * i / (values.length - 1),
          size.height - (values[i] - lo) / span * (size.height - 4) - 2,
        ),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values;
}

/// Histogramme simple avec étiquettes.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    this.height = 180,
    this.format,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    final hi = values.reduce(math.max);
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Motion.easeOut,
        builder: (context, t, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: Tooltip(
                  message:
                      '${labels[i]} · ${format?.call(values[i]) ?? values[i].toStringAsFixed(0)}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: (height - 22) * values[i] / hi * t,
                        decoration: BoxDecoration(
                          color: i == values.length - 1
                              ? color
                              : color.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        maxLines: 1,
                        style: context.text.labelSmall?.copyWith(
                          color: Confetti.inkFaint,
                          fontSize: 10,
                        ),
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

/// Pastille d'état.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, this.hue, {super.key});

  final String label;
  final Hue hue;

  @override
  Widget build(BuildContext context) => Tag(label: label, hue: hue);
}

/// Colonne d'un tableau d'administration.
class AdminColumn {
  const AdminColumn(this.label, {this.flex = 2, this.numeric = false});
  final String label;
  final int flex;
  final bool numeric;
}

/// Tableau adaptatif : lignes sur grand écran, fiches empilées sur mobile.
class AdminTable extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onTap,
    this.empty = 'Aucun élément',
  });

  final List<AdminColumn> columns;
  final List<List<Widget>> rows;
  final void Function(int)? onTap;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 680;
        if (rows.isEmpty) {
          return Panel(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(empty, style: context.text.bodyMedium)),
            ),
          );
        }
        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Panel(
                    padding: const EdgeInsets.all(14),
                    onTap: onTap == null ? null : () => onTap!(i),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        rows[i].first,
                        const SizedBox(height: 8),
                        for (var c = 1; c < columns.length; c++)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    columns[c].label,
                                    style: context.text.labelSmall?.copyWith(
                                      color: Confetti.inkFaint,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: rows[i][c],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }
        return Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    for (final c in columns)
                      Expanded(
                        flex: c.flex,
                        child: Text(
                          c.label.toUpperCase(),
                          textAlign: c.numeric ? TextAlign.right : null,
                          style: context.text.labelSmall?.copyWith(
                            color: Confetti.inkFaint,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                Pressable(
                  scale: 0.995,
                  onTap: onTap == null ? null : () => onTap!(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        for (var c = 0; c < columns.length; c++)
                          Expanded(
                            flex: columns[c].flex,
                            child: Align(
                              alignment: columns[c].numeric
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: rows[i][c],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Texte principal + secondaire, pour la première colonne des tableaux.
class TwoLines extends StatelessWidget {
  const TwoLines(this.title, this.caption, {super.key});
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.titleSmall,
      ),
      Text(
        caption,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.bodySmall,
      ),
    ],
  );
}

/// Champ de recherche compact.
class AdminSearch extends StatelessWidget {
  const AdminSearch({super.key, required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: TextField(
      onChanged: onChanged,
      style: context.text.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(AppIcons.search, size: 18, color: Confetti.inkMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    ),
  );
}

/// Rangée de filtres à pastilles.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.counts,
  });

  final List<T?> values;
  final T? selected;
  final String Function(T?) labelOf;
  final ValueChanged<T?> onChanged;
  final int Function(T?)? counts;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final v in values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Pressable(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: Motion.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: v == selected ? Confetti.ink : Confetti.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: v == selected ? Confetti.ink : Confetti.line,
                    ),
                  ),
                  child: Text(
                    counts == null
                        ? labelOf(v)
                        : '${labelOf(v)} · ${counts!(v)}',
                    style: context.text.labelMedium?.copyWith(
                      color: v == selected ? Confetti.onInk : Confetti.ink,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bouton compact des barres d'actions admin.
class AdminButton extends StatelessWidget {
  const AdminButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = ButtonTone.dark,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonTone tone;

  @override
  Widget build(BuildContext context) => PillButton(
    label: label,
    icon: icon,
    tone: tone,
    expand: false,
    height: 40,
    onPressed: onPressed,
  );
}

/// Grille responsive (1 à [max] colonnes selon la largeur).
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTile = 220,
    this.max = 4,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double minTile;
  final int max;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final n = (box.maxWidth / minTile).floor().clamp(1, max);
      final w = (box.maxWidth - spacing * (n - 1)) / n;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    },
  );
}

/// Titre de bloc à l'intérieur d'un module.
class BlockTitle extends StatelessWidget {
  const BlockTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(title, style: context.text.titleLarge),
        ?trailing,
      ],
    ),
  );
}

/// Couleur associée à chaque statut, pour garder un code constant.
Hue hueOf(Object status) => switch (status) {
  AccountStatus.active ||
  VerifyStatus.approved ||
  ListingStatus.published ||
  OrderStatus.completed ||
  OrderStatus.confirmed ||
  TxStatus.success ||
  TicketStatus.resolved ||
  DocStatus.valid ||
  CampaignStatus.running => Hue.lagoon,
  AccountStatus.pending ||
  VerifyStatus.pending ||
  ListingStatus.review ||
  OrderStatus.changed ||
  TxStatus.pending ||
  TicketStatus.waiting ||
  DocStatus.submitted ||
  CampaignStatus.scheduled => Hue.mango,
  AccountStatus.suspended ||
  VerifyStatus.rejected ||
  OrderStatus.dispute ||
  TxStatus.failed ||
  DocStatus.invalid ||
  DocStatus.missing ||
  TicketPriority.urgent => Hue.coral,
  VerifyStatus.info ||
  TicketStatus.progress ||
  TicketPriority.high => Hue.violet,
  _ => Hue.ink,
};

/// « il y a 12 min », « il y a 3 h », « il y a 2 j ».
String since(DateTime d) {
  final m = DateTime.now().difference(d).inMinutes;
  if (m < 1) return 'à l’instant';
  if (m < 60) return 'il y a $m min';
  if (m < 60 * 24) return 'il y a ${m ~/ 60} h';
  return 'il y a ${m ~/ (60 * 24)} j';
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/i18n/tr.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/eventa_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/avatars.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/models.dart';

Hue moduleHue(Module m) => switch (m) {
  Module.budget => Hue.lagoon,
  Module.tasks => Hue.violet,
  Module.vendors => Hue.mango,
  Module.team => Hue.candy,
  Module.guests => Hue.coral,
};

String moduleLabel(Module m) => switch (m) {
  Module.budget => 'Budget'.tr,
  Module.tasks => 'Tâche'.tr,
  Module.vendors => 'Prestataire'.tr,
  Module.team => 'Équipe'.tr,
  Module.guests => 'Invités'.tr,
};

/// Une entrée du rétroplanning, tâche + événement d'origine.
class TimelineEntry {
  const TimelineEntry({required this.task, required this.event});
  final EventTask task;
  final Event event;
}

/// Rétroplanning vertical façon agenda : capsule colorée dont la hauteur
/// suit la durée, reliées par un fil pointillé.
class TaskTimeline extends StatelessWidget {
  const TaskTimeline({
    super.key,
    required this.entries,
    required this.onToggle,
    this.colorByEvent = false,
    this.showDate = true,
  });

  final List<TimelineEntry> entries;
  final void Function(TimelineEntry entry) onToggle;
  final bool colorByEvent;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineRow(
            key: ValueKey(entries[i].task.id),
            entry: entries[i],
            first: i == 0,
            last: i == entries.length - 1,
            hue: colorByEvent
                ? entries[i].event.category.hue
                : moduleHue(entries[i].task.module),
            showDate: showDate,
            onToggle: () => onToggle(entries[i]),
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    super.key,
    required this.entry,
    required this.first,
    required this.last,
    required this.hue,
    required this.showDate,
    required this.onToggle,
  });

  final TimelineEntry entry;
  final bool first;
  final bool last;
  final Hue hue;
  final bool showDate;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = entry.task;
    final end = t.due.add(Duration(minutes: t.durationMin));
    final capsuleH = (t.durationMin * 0.55).clamp(46.0, 92.0);
    final member = entry.event.member(t.assigneeId);
    final overdue = !t.done && t.due.isBefore(DateTime.now());

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeOf(t.due),
                    style: context.text.labelMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (showDate)
                    Text(
                      shortDate(t.due),
                      style: context.text.labelSmall?.copyWith(
                        color: context.eventa.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: Motion.base,
                  curve: Motion.easeOut,
                  width: 44,
                  height: capsuleH,
                  decoration: BoxDecoration(
                    color: t.done ? hue.tint : hue.base,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    t.icon,
                    size: 20,
                    color: t.done ? hue.text : _onBase(hue),
                  ),
                ),
                if (!last)
                  const Expanded(
                    child: CustomPaint(
                      painter: _DashPainter(),
                      size: Size(2, double.infinity),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3, bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${timeOf(t.due)} – ${timeOf(end)}${overdue ? ' · en retard'.tr : ''}',
                    style: context.text.labelSmall?.copyWith(
                      color: overdue ? Confetti.danger : context.eventa.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: Motion.fast,
                    style: context.text.titleMedium!.copyWith(
                      color: t.done ? context.eventa.muted : Confetti.ink,
                      decoration: t.done ? TextDecoration.lineThrough : null,
                      decorationColor: context.eventa.muted,
                    ),
                    child: Text(t.title),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (member != null) ...[
                        Avatar(
                          image: member.avatar,
                          size: 20,
                          ring: Confetti.cream,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          member.firstName,
                          style: context.text.labelSmall?.copyWith(
                            color: context.eventa.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          colorEventLabel(entry),
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelSmall?.copyWith(
                            color: hue.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _Check(done: t.done, hue: hue, onTap: onToggle),
          ),
        ],
      ),
    );
  }

  String colorEventLabel(TimelineEntry e) =>
      '${moduleLabel(e.task.module)} · ${e.event.category.short}';

  Color _onBase(Hue h) => h.base == Confetti.mango || h.base == Confetti.lagoon
      ? h.deep
      : Colors.white;
}

class _Check extends StatelessWidget {
  const _Check({required this.done, required this.hue, required this.onTap});

  final bool done;
  final Hue hue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.88,
      semanticLabel: done ? 'Marquer à faire'.tr : 'Marquer comme terminée'.tr,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.easeOut,
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? hue.text : Colors.transparent,
          border: Border.all(
            color: done ? hue.text : Confetti.border,
            width: 2,
          ),
        ),
        child: AnimatedScale(
          duration: Motion.fast,
          curve: Motion.easeOut,
          scale: done ? 1 : 0.5,
          child: AnimatedOpacity(
            duration: Motion.fast,
            opacity: done ? 1 : 0,
            child: const Icon(AppIcons.check, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Confetti.border
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    var y = 6.0;
    while (y < size.height - 4) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 3), p);
      y += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

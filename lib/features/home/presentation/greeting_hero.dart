import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/sound/sounds.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/mascot.dart';

/// En-tête d'accueil : lumière chaude, confettis qui flottent, grande
/// salutation et la mascotte du profil, en pied, qui suit le pointeur et
/// saute quand on la touche.
class GreetingHero extends ConsumerStatefulWidget {
  const GreetingHero({
    super.key,
    required this.header,
    this.question,
    this.mascot = MascotColor.organizer,
    this.action,
  });

  /// Barre du haut (photo, notifications).
  final Widget header;

  /// Petite ligne sous la salutation.
  final String? question;

  /// Mascotte du profil : rouge (organisateur) ou verte (créateur).
  final MascotColor mascot;

  /// Action principale facultative (ex. créer un événement).
  final Widget? action;

  @override
  ConsumerState<GreetingHero> createState() => _GreetingHeroState();
}

class _GreetingHeroState extends ConsumerState<GreetingHero>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _t = Duration.zero;
  Offset? _pointer;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((t) => setState(() => _t = t))..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduced && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Offset? _lookFrom(Offset mascot) {
    final p = _pointer;
    if (p == null) return null;
    final d = p - mascot;
    final len = math.max(d.distance, 1);
    return Offset(d.dx / len, d.dy / len) * math.min(1, len / 140);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 400;
    final h = compact ? 300.0 : 320.0;
    final dark = Confetti.dark;
    final mascotSize = compact ? 132.0 : 168.0;
    final creator = widget.mascot == MascotColor.creator;
    final warm = creator
        ? const [Color(0xFFD5F6EE), Color(0xFFEAF8F2)]
        : const [Color(0xFFFFDCCB), Color(0xFFFFF0DA)];

    return MouseRegion(
      onHover: (e) => setState(() => _pointer = e.localPosition),
      onExit: (_) => setState(() => _pointer = null),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final mascotCenter = Offset(
            w - 16 - mascotSize / 2,
            h - 12 - mascotSize / 2,
          );
          return SizedBox(
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Lumière chaude qui se fond dans le fond de page.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: dark
                            ? const [Color(0xFF34195A), Color(0x00110722)]
                            : [warm[0], warm[1], Confetti.cream],
                        stops: dark ? const [0, 1] : const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ConfettiPainter(
                      t: _t.inMicroseconds / 1e6,
                      dark: dark,
                    ),
                  ),
                ),
                Positioned(left: 0, right: 0, top: 0, child: widget.header),
                // Salutation à gauche, mascotte à droite.
                Positioned(
                  left: 20,
                  right: mascotSize * 0.7,
                  bottom: 26,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Rise(
                        delay: 0,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${greeting()} !',
                            style: TextStyle(
                              fontFamily: AppTheme.font,
                              fontSize: compact ? 44 : 54,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: Confetti.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _Rise(
                        delay: 120,
                        child: Text(
                          // Espace insécable : le « ? » ne part jamais seul.
                          (widget.question ??
                                  'Qu’est-ce qu’on célèbre aujourd’hui ?'.tr)
                              .replaceAll(' ?', ' ?'),
                          style: TextStyle(
                            fontFamily: AppTheme.font,
                            fontSize: compact ? 15.5 : 17,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            color: Confetti.inkMuted,
                          ),
                        ),
                      ),
                      if (widget.action != null) ...[
                        const SizedBox(height: 14),
                        _Rise(delay: 240, child: widget.action!),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 6,
                  child: _Rise(
                    delay: 180,
                    distance: 60,
                    child: Mascot(
                      size: mascotSize,
                      color: widget.mascot,
                      mood: MascotMood.happy,
                      look: _lookFrom(mascotCenter),
                      onTap: () => ref.read(soundProvider).play(Sfx.success),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Apparition en montée douce, décalée de [delay] millisecondes.
class _Rise extends StatelessWidget {
  const _Rise({required this.child, this.delay = 0, this.distance = 18});

  final Widget child;
  final int delay;
  final double distance;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 620 + delay),
      curve: Interval(delay / (620 + delay), 1, curve: Curves.easeOutBack),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * distance),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Confettis qui flottent lentement : rubans, pastilles et petites étoiles.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t, required this.dark});

  final double t;
  final bool dark;

  static const _colors = [
    Color(0xFFE5484D),
    Color(0xFF6246EA),
    Color(0xFFE5A21A),
    Color(0xFF0E9F8E),
    Color(0xFFDB4F9E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var i = 0; i < 18; i++) {
      final x0 = rnd.nextDouble(), y0 = rnd.nextDouble();
      final speed = 0.012 + rnd.nextDouble() * 0.02;
      final phase = rnd.nextDouble() * math.pi * 2;
      final kind = i % 3;
      final y = ((y0 + t * speed) % 1.1 - 0.05) * size.height;
      final x = x0 * size.width + math.sin(t * 0.8 + phase) * 10;
      final a = (dark ? 0.35 : 0.5) * (0.6 + 0.4 * math.sin(t + phase));
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: a);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * (0.6 + rnd.nextDouble()) + phase);
      switch (kind) {
        case 0:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-6, -2, 12, 4),
              const Radius.circular(2),
            ),
            paint,
          );
        case 1:
          canvas.drawCircle(Offset.zero, 3.2, paint);
        default:
          final p = Path();
          for (var k = 0; k < 8; k++) {
            final r = k.isEven ? 5.0 : 2.0;
            final ang = k * math.pi / 4;
            final pt = Offset(math.cos(ang) * r, math.sin(ang) * r);
            k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
          }
          canvas.drawPath(p..close(), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t || old.dark != dark;
}

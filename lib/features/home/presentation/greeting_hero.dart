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

/// En-tête d'accueil : une carte encre et violet où la mascotte du profil
/// entre par la gauche en saluant, avec une bulle « Bonjour ! », un halo qui
/// respire et des confettis. Elle suit le pointeur et saute au toucher.
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

  /// Mascotte du profil : bleue (organisateur) ou orange (créateur).
  final MascotColor mascot;

  /// Action principale facultative (ex. créer un événement).
  final Widget? action;

  @override
  ConsumerState<GreetingHero> createState() => _GreetingHeroState();
}

class _GreetingHeroState extends ConsumerState<GreetingHero>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);
  Offset? _pointer;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((t) => _time.value = t.inMicroseconds / 1e6)
      ..start();
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
    _time.dispose();
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
    final cardH = compact ? 286.0 : 300.0;
    final mascotSize = compact ? 220.0 : 260.0;
    final dark = Confetti.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.header,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: MouseRegion(
            onHover: (e) => setState(() => _pointer = e.localPosition),
            onExit: (_) => setState(() => _pointer = null),
            child: LayoutBuilder(
              builder: (context, box) {
                // La mascotte dépasse du bord gauche, comme si elle entrait
                // dans la carte pour dire bonjour.
                final mLeft = -mascotSize * 0.36;
                final mCenter = Offset(
                  mLeft + mascotSize / 2,
                  cardH - mascotSize * 0.45,
                );
                final textLeft = mascotSize * 0.52;
                return Container(
                  height: cardH,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A1366), Color(0xFF1A0637)],
                    ),
                    boxShadow: dark
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF1A0637)
                                  .withValues(alpha: 0.22),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Halo lumineux derrière la mascotte.
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _GlowPainter(
                              time: _time,
                              center: mCenter,
                              color: widget.mascot == MascotColor.creator
                                  ? const Color(0xFFFF9A3C)
                                  : const Color(0xFF6E6BFF),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _ConfettiPainter(time: _time, dark: true),
                          ),
                        ),
                      ),
                      Positioned(
                        left: mLeft,
                        bottom: -mascotSize * 0.10,
                        child: Transform.rotate(
                          angle: 0.10,
                          alignment: Alignment.bottomCenter,
                          child: Mascot(
                            size: mascotSize,
                            color: widget.mascot,
                            waving: true,
                            look: _lookFrom(mCenter),
                            onTap: () =>
                                ref.read(soundProvider).play(Sfx.success),
                          ),
                        ),
                      ),
                      // Bulle de dialogue : la salutation stylisée.
                      Positioned(
                        left: textLeft,
                        // Sur grand écran, la bulle garde une largeur de
                        // bulle au lieu de traverser toute la carte.
                        right: math.max(16, box.maxWidth - textLeft - 340),
                        top: 20,
                        child: _Rise(
                          delay: 260,
                          child: _SpeechBubble(
                            text: '${greeting()} !',
                            compact: compact,
                          ),
                        ),
                      ),
                      Positioned(
                        left: textLeft,
                        right: 16,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Rise(
                              delay: 380,
                              child: Text(
                                // Espace insécable : le « ? » ne part jamais
                                // seul en fin de ligne.
                                (widget.question ??
                                        'Qu’est-ce qu’on célèbre aujourd’hui ?'
                                            .tr)
                                    .replaceAll(' ?', ' ?'),
                                style: TextStyle(
                                  fontFamily: AppTheme.font,
                                  fontSize: compact ? 15 : 16.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                            ),
                            if (widget.action != null) ...[
                              const SizedBox(height: 12),
                              _Rise(
                                delay: 480,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: widget.action!,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Bulle de dialogue crème, queue tournée vers la mascotte.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              fontFamily: AppTheme.font,
              fontSize: compact ? 34 : 40,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              color: const Color(0xFF1A0637),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final tail = Path()
      ..moveTo(18, size.height * 0.62)
      ..quadraticBezierTo(-6, size.height + 10, -14, size.height + 14)
      ..quadraticBezierTo(14, size.height * 0.98, 40, size.height * 0.86)
      ..close();
    final paint = Paint()..color = const Color(0xFFF7F2E8);
    canvas.drawRRect(r, paint);
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}

/// Halo circulaire qui respire derrière la mascotte.
class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.time, required this.center, required this.color})
    : super(repaint: time);

  final ValueNotifier<double> time;
  final Offset center;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = 1 + math.sin(time.value * 1.3) * 0.04;
    final r = size.height * 0.62 * pulse;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    canvas.drawCircle(
      center,
      r * 0.78,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..color = color.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.center != center || old.color != color;
}

/// Apparition en montée douce, décalée de [delay] millisecondes.
class _Rise extends StatelessWidget {
  const _Rise({required this.child, this.delay = 0});

  final Widget child;
  final int delay;
  static const distance = 18.0;

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
  _ConfettiPainter({required this.time, required this.dark})
    : super(repaint: time);

  final ValueNotifier<double> time;
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
    final t = time.value;
    final rnd = math.Random(7);
    // Confettis qui tombent en voletant, derrière la salutation.
    for (var i = 0; i < 34; i++) {
      final x0 = rnd.nextDouble(), y0 = rnd.nextDouble();
      final speed = 0.04 + rnd.nextDouble() * 0.05;
      final s = 0.9 + rnd.nextDouble() * 0.8;
      final phase = rnd.nextDouble() * math.pi * 2;
      final kind = i % 3;
      final y = ((y0 + t * speed) % 1.1 - 0.05) * size.height;
      final x = x0 * size.width + math.sin(t * 1.4 + phase) * 16;
      final a = dark ? 0.55 : 0.85;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: a);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * (1.2 + rnd.nextDouble() * 1.6) + phase);
      canvas.scale(s, s * (0.35 + 0.65 * math.cos(t * 3 + phase).abs()));
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
  bool shouldRepaint(_ConfettiPainter old) =>
      old.time != time || old.dark != dark;
}

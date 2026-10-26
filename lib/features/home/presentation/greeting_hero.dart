import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/sound/sounds.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/mascot.dart';

/// En-tête d'accueil : ciel doux, grande salutation et trois mascottes qui
/// dépassent du bas de l'écran. Le regard des mascottes suit le pointeur.
class GreetingHero extends ConsumerStatefulWidget {
  const GreetingHero({
    super.key,
    required this.header,
    this.question,
    this.colors = const (
      MascotColor.lagoon,
      MascotColor.orange,
      MascotColor.candy,
    ),
  });

  /// Barre du haut (photo, notifications).
  final Widget header;

  /// Petite ligne sous la salutation (en capitales).
  final String? question;

  /// Mascottes gauche, centre (principale) et droite.
  final (MascotColor, MascotColor, MascotColor) colors;

  @override
  ConsumerState<GreetingHero> createState() => _GreetingHeroState();
}

class _GreetingHeroState extends ConsumerState<GreetingHero> {
  Offset? _pointer;

  Offset? _lookFrom(Offset mascot) {
    final p = _pointer;
    if (p == null) return null;
    final d = p - mascot;
    final len = math.max(d.distance, 1);
    return Offset(d.dx / len, d.dy / len) * math.min(1, len / 120);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final h = width < 720 ? 372.0 : 400.0;
    final dark = Confetti.dark;
    final (left, middle, right) = widget.colors;
    final side = width < 720 ? 132.0 : 150.0;
    final main = width < 720 ? 168.0 : 190.0;

    return MouseRegion(
      onHover: (e) => setState(() => _pointer = e.localPosition),
      onExit: (_) => setState(() => _pointer = null),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          return SizedBox(
            height: h,
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Ciel : halo lavande en haut, rayons très légers.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: dark
                              ? const [Color(0xFF2B1A5C), Color(0x00110722)]
                              : const [Color(0xFFDCD5FF), Color(0x00F7F5F2)],
                          stops: const [0, 0.62],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(painter: _RaysPainter(dark: dark)),
                  ),
                  Positioned(left: 0, right: 0, top: 0, child: widget.header),
                  // Salutation.
                  Positioned(
                    left: 20,
                    right: 20,
                    top: h * 0.33,
                    child: Column(
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (r) => LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Confetti.ink,
                              Confetti.ink.withValues(alpha: 0.82),
                              Confetti.inkFaint,
                            ],
                          ).createShader(r),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              greeting(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: width < 380 ? 52 : 60,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -2.4,
                                color: Confetti.ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          (widget.question ??
                                  'Qu’est-ce qu’on célèbre aujourd’hui ?'.tr)
                              .toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                            color: Confetti.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mascottes qui dépassent du bas, floutées sur les côtés.
                  Positioned(
                    left: -side * 0.42,
                    bottom: -side * 0.38,
                    child: _Peek(
                      color: left,
                      size: side,
                      blur: 1.4,
                      angle: 0.32,
                      look: _lookFrom(Offset(side * 0.2, h - side * 0.3)),
                      onTap: () =>
                          ref.read(soundProvider).play(Sfx.notification),
                    ),
                  ),
                  Positioned(
                    right: -side * 0.42,
                    bottom: -side * 0.2,
                    child: _Peek(
                      color: right,
                      size: side,
                      blur: 1.4,
                      angle: -0.36,
                      mood: MascotMood.wink,
                      look: _lookFrom(Offset(w - side * 0.2, h - side * 0.4)),
                      onTap: () =>
                          ref.read(soundProvider).play(Sfx.notification),
                    ),
                  ),
                  Positioned(
                    left: (w - main * 100 / 128) / 2,
                    bottom: -main * 0.42,
                    child: _Peek(
                      color: middle,
                      size: main,
                      look: _lookFrom(Offset(w / 2, h - main * 0.3)),
                      onTap: () => ref.read(soundProvider).play(Sfx.success),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Peek extends StatelessWidget {
  const _Peek({
    required this.color,
    required this.size,
    this.blur = 0,
    this.angle = 0,
    this.mood = MascotMood.happy,
    this.look,
    this.onTap,
  });

  final MascotColor color;
  final double size;
  final double blur;
  final double angle;
  final MascotMood mood;
  final Offset? look;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget m = Mascot(
      size: size,
      color: color,
      mood: mood,
      look: look,
      arms: false,
      legs: false,
      onTap: onTap,
    );
    if (blur > 0) {
      m = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: m,
      );
    }
    return Transform.rotate(angle: angle, child: m);
  }
}

/// Rayons de lumière partant du haut, à peine visibles.
class _RaysPainter extends CustomPainter {
  _RaysPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, -size.height * 0.15);
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        origin,
        Offset(size.width / 2, size.height * 0.55),
        [
          Colors.white.withValues(alpha: dark ? 0.06 : 0.45),
          Colors.white.withValues(alpha: 0),
        ],
      );
    for (var i = -4; i <= 4; i++) {
      final a = math.pi / 2 + i * 0.16;
      final spread = 0.035;
      final r = size.height * 1.2;
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx, origin.dy)
          ..lineTo(
            origin.dx + math.cos(a - spread) * r,
            origin.dy + math.sin(a - spread) * r,
          )
          ..lineTo(
            origin.dx + math.cos(a + spread) * r,
            origin.dy + math.sin(a + spread) * r,
          )
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.dark != dark;
}

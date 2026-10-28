import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/mascot.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/ui.dart';

/// Bienvenue : fond encre Eventa, halos de couleur qui dérivent et trame de
/// points façon « tech », les deux mascottes au centre d'une orbite où
/// tournent les promesses de l'app. Tous les textes sont centrés.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1A0637);
    return Scaffold(
      backgroundColor: ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _AuroraPainter(_c)),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final orbit = (c.maxHeight * 0.42).clamp(240.0, 380.0);
                return CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                            child: Column(
                              children: [
                                const Entrance(
                                  child: EventaWordmark(
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Entrance(index: 1, child: _Badge()),
                                SizedBox(
                                  height: orbit,
                                  child: _Orbit(controller: _c, size: orbit),
                                ),
                                Entrance(
                                  index: 4,
                                  offset: 16,
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Le budget parfait\npour '.tr,
                                        ),
                                        TextSpan(
                                          text: 'célébrer'.tr,
                                          style: const TextStyle(
                                            color: Color(0xFFFFC233),
                                          ),
                                        ),
                                        const TextSpan(text: '.'),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    style: context.text.displaySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 38,
                                      height: 1.04,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Entrance(
                                  index: 5,
                                  child: Text(
                                    'Budget en FCFA, prestataires vérifiés, invités et équipe : tout votre événement au même endroit.'
                                        .tr,
                                    textAlign: TextAlign.center,
                                    style: context.text.bodyLarge?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const SizedBox(height: 24),
                                Entrance(
                                  index: 6,
                                  child: PillButton(
                                    label: 'Créer un compte'.tr,
                                    onPressed: () =>
                                        context.push(Routes.signUp),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Entrance(
                                  index: 7,
                                  child: _GlassButton(
                                    label: 'Se connecter'.tr,
                                    onTap: () => context.push(Routes.signIn),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille d'ancrage local, en verre.
class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in const [
            Color(0xFFF77F00),
            Colors.white,
            Color(0xFF009E60),
          ])
            Container(width: 5, height: 12, color: c),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Côte d’Ivoire · FCFA · Mobile Money'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Les deux mascottes au centre, des pastilles qui tournent en orbite.
class _Orbit extends StatelessWidget {
  const _Orbit({required this.controller, required this.size});

  final Animation<double> controller;
  final double size;

  static const _chips = [
    (AppIcons.coins, 'FCFA', Color(0xFFFFC233)),
    (AppIcons.verified, 'Prestataires vérifiés', Color(0xFF2FD4B0)),
    (AppIcons.mobile, 'Mobile Money', Color(0xFFFF7A82)),
    (AppIcons.guests, 'RSVP WhatsApp', Color(0xFFB9A8FF)),
  ];

  @override
  Widget build(BuildContext context) {
    final r = size * 0.42;
    final mascot = size * 0.34;
    return LayoutBuilder(
      builder: (context, box) {
        final cx = box.maxWidth / 2, cy = size / 2;
        // Rayon horizontal limité : les pastilles restent dans l'écran.
        final rx = math.min(r * 1.08, cx - 82);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Anneaux de l'orbite.
            Positioned.fill(child: CustomPaint(painter: _RingsPainter(r, rx))),
            Positioned(
              left: cx - mascot * 1.02,
              top: cy - mascot * 0.52,
              child: Mascot(size: mascot, mood: MascotMood.cheer),
            ),
            Positioned(
              left: cx + mascot * 0.02,
              top: cy - mascot * 0.48,
              child: Mascot(
                size: mascot,
                color: MascotColor.creator,
                mood: MascotMood.happy,
              ),
            ),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (i, (icon, label, color)) in _chips.indexed)
                    _orbitChip(
                      context,
                      angle: controller.value * math.pi * 2 + i * math.pi / 2,
                      cx: cx,
                      cy: cy,
                      r: r,
                      rx: rx,
                      icon: icon,
                      label: label.tr,
                      color: color,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _orbitChip(
    BuildContext context, {
    required double angle,
    required double cx,
    required double cy,
    required double r,
    required double rx,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    // Orbite elliptique, légèrement aplatie pour l'effet de profondeur.
    final x = cx + math.cos(angle) * rx;
    final y = cy + math.sin(angle) * r * 0.62;
    final depth = (math.sin(angle) + 1) / 2;
    // Cadre fixe centré sur le point de l'orbite : la pastille s'y réduit
    // au besoin plutôt que de déborder.
    return Positioned(
      left: x - 95,
      top: y - 18,
      width: 190,
      height: 36,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Transform.scale(
          scale: 0.82 + depth * 0.22,
          child: Opacity(
            opacity: 0.6 + depth * 0.4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: context.text.labelMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.r, this.rx);

  final double r, rx;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final (k, a) in [(1.08, 0.16), (0.82, 0.10)]) {
      p.color = Colors.white.withValues(alpha: a);
      canvas.drawOval(
        Rect.fromCenter(
          center: c,
          width: rx * 2 / 1.08 * k,
          height: r * 1.24 * k,
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.r != r || old.rx != rx;
}

/// Halos corail, violet, mangue et lagon qui dérivent, sur une trame de
/// points discrète.
class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.anim) : super(repaint: anim);

  final Animation<double> anim;

  static const _blobs = [
    (Color(0xFFE5484D), 0.15, 0.18, 0.55),
    (Color(0xFF6246EA), 0.85, 0.22, 0.65),
    (Color(0xFFE5A21A), 0.20, 0.82, 0.5),
    (Color(0xFF0E9F8E), 0.85, 0.78, 0.55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value * math.pi * 2;
    for (final (i, (color, x, y, r)) in _blobs.indexed) {
      final c = Offset(
        size.width * (x + math.sin(t + i) * 0.06),
        size.height * (y + math.cos(t * 0.8 + i) * 0.05),
      );
      final radius = size.shortestSide * r;
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.42), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: radius)),
      );
    }
    // Trame de points : le côté « tech ».
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.07);
    const step = 22.0;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.anim != anim;
}

/// Bouton secondaire en verre, lisible sur le fond sombre.
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(54),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: context.text.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

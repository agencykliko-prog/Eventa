import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/widgets/avatars.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/ui.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final collageH = (c.maxHeight * 0.5).clamp(280.0, 460.0);
            // Défile seulement si l'écran est trop court ; sinon les
            // boutons restent calés en bas.
            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: EventaWordmark(size: 20),
                        ),
                      ),
                      SizedBox(height: collageH, child: const _Collage()),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Entrance(
                                index: 6,
                                child: Text(
                                  'Le budget parfait\npour célébrer.',
                                  style: context.text.displaySmall,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Entrance(
                                index: 7,
                                child: Text(
                                  'Budget en FCFA, tâches, prestataires et équipe : '
                                  'tout votre événement au même endroit.',
                                  style: context.text.bodyLarge?.copyWith(
                                    color: context.eventa.muted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Spacer(),
                              Entrance(
                                index: 8,
                                child: PillButton(
                                  label: 'Créer un compte',
                                  onPressed: () => context.push(Routes.signUp),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Entrance(
                                index: 9,
                                child: PillButton(
                                  label: 'Se connecter',
                                  tone: ButtonTone.ghost,
                                  onPressed: () => context.push(Routes.signIn),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Collage de couvertures façon billets posés sur la table, avec les
/// indicateurs de l'app qui flottent par-dessus.
class _Collage extends StatefulWidget {
  const _Collage();

  @override
  State<_Collage> createState() => _CollageState();
}

class _CollageState extends State<_Collage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _intro.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final card = math.min(w * 0.5, h * 0.62);

        Widget piece({
          required int order,
          required double x,
          required double y,
          required double angle,
          required double phase,
          required Widget child,
        }) {
          return AnimatedBuilder(
            animation: Listenable.merge([_intro, _float]),
            child: child,
            builder: (context, child) {
              final start = (order * 0.12).clamp(0.0, 0.6);
              final t = reduce
                  ? 1.0
                  : Motion.easeOut.transform(
                      ((_intro.value - start) / (1 - start)).clamp(0.0, 1.0),
                    );
              final bob = reduce
                  ? 0.0
                  : math.sin((_float.value + phase) * 2 * math.pi) * 3.5;
              return Positioned(
                left: x,
                top: y + (1 - t) * 60 + bob,
                child: Opacity(
                  opacity: t,
                  child: Transform.rotate(
                    angle: angle * (0.4 + 0.6 * t),
                    child: child,
                  ),
                ),
              );
            },
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            piece(
              order: 0,
              x: w * 0.05,
              y: h * 0.12,
              angle: -0.14,
              phase: 0,
              child: _Cover(
                image: 'assets/images/onboarding_wedding.jpg',
                width: card,
                label: 'Mariage',
                hue: Hue.coral,
              ),
            ),
            piece(
              order: 1,
              x: w * 0.47,
              y: h * 0.02,
              angle: 0.1,
              phase: 0.33,
              child: _Cover(
                image: 'assets/images/cover_birthday.jpg',
                width: card * 0.9,
                label: 'Anniversaire',
                hue: Hue.violet,
              ),
            ),
            piece(
              order: 2,
              x: w * 0.36,
              y: h * 0.4,
              angle: -0.03,
              phase: 0.66,
              child: _Cover(
                image: 'assets/images/cover_babyshower.jpg',
                width: card * 0.92,
                label: 'Baby shower',
                hue: Hue.lagoon,
              ),
            ),
            piece(
              order: 3,
              x: w * 0.06,
              y: h * 0.7,
              angle: -0.04,
              phase: 0.2,
              child: const _Chip(
                hue: Hue.lagoon,
                icon: AppIcons.wallet,
                label: 'Budget',
                value: '68 %',
              ),
            ),
            piece(
              order: 4,
              x: w * 0.6,
              y: h * 0.3,
              angle: 0.05,
              phase: 0.5,
              child: const _Countdown(),
            ),
            piece(
              order: 5,
              x: w * 0.58,
              y: h * 0.86,
              angle: 0.03,
              phase: 0.8,
              child: const _TeamChip(),
            ),
          ],
        );
      },
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.image,
    required this.width,
    required this.label,
    required this.hue,
  });

  final String image;
  final double width;
  final String label;
  final Hue hue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.18,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Confetti.ink.withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(image, fit: BoxFit.cover),
            Positioned(
              left: 10,
              top: 10,
              child: Tag(label: label, hue: hue, solid: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.hue,
    required this.icon,
    required this.label,
    required this.value,
  });

  final Hue hue;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
      decoration: BoxDecoration(
        color: hue.tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Confetti.ink.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: hue.text),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: hue.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  color: hue.deep,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Confetti.coral,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Confetti.coral.withValues(alpha: 0.4),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'J-42',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'avant la fête',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  const _TeamChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: Confetti.ink.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarStack(
            images: [
              'assets/images/avatar_2.jpg',
              'assets/images/avatar_3.jpg',
              'assets/images/avatar_5.jpg',
            ],
            size: 26,
          ),
          SizedBox(width: 8),
          Text(
            '6 en ligne',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Confetti.candyText,
            ),
          ),
        ],
      ),
    );
  }
}

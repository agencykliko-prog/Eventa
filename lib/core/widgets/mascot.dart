import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../i18n/tr.dart';

/// Les deux mascottes d'Eventa : la bleue accompagne les organisateurs,
/// l'orange les créateurs (prestataires et agences).
enum MascotColor {
  organizer('red'),
  creator('green');

  const MascotColor(this._file);
  final String _file;
}

/// Humeur affichée : chaque humeur correspond à une pose illustrée.
enum MascotMood { happy, wow, wink, sleepy, cheer }

/// Poses disponibles pour chaque mascotte.
enum _Shot { jump, thumbs, peace, extra }

String _asset(MascotColor c, _Shot s) {
  final name = switch (s) {
    _Shot.extra => c == MascotColor.organizer ? 'cheeks' : 'wave',
    _ => s.name,
  };
  return 'assets/images/mascots/${c._file}_$name.webp';
}

_Shot _shotFor(MascotMood mood) => switch (mood) {
  MascotMood.happy || MascotMood.wink => _Shot.thumbs,
  MascotMood.cheer => _Shot.jump,
  MascotMood.wow => _Shot.extra,
  MascotMood.sleepy => _Shot.peace,
};

/// Charge les poses à l'avance pour que les changements soient instantanés.
void precacheMascots(BuildContext context) {
  for (final c in MascotColor.values) {
    for (final s in _Shot.values) {
      precacheImage(AssetImage(_asset(c, s)), context);
    }
  }
}

/// Mascotte statique : une pose illustrée, sans mouvement. [cover] lui fait
/// cacher les yeux (champ de mot de passe) ; [waving] affiche la pose qui
/// salue.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.size = 120,
    this.color = MascotColor.organizer,
    this.mood = MascotMood.happy,
    this.look,
    this.cover = false,
    this.waving = false,
    this.arms = true,
    this.legs = true,
    this.idle = true,
    this.onTap,
  });

  /// Côté du widget (carré).
  final double size;
  final MascotColor color;
  final MascotMood mood;
  final bool cover;
  final bool waving;

  /// Conservés pour compatibilité : la mascotte ne bouge plus.
  final Offset? look;
  final bool arms;
  final bool legs;
  final bool idle;

  final VoidCallback? onTap;

  @override
  State<Mascot> createState() => MascotState();
}

class MascotState extends State<Mascot> {
  /// Conservé pour compatibilité : la mascotte reste immobile.
  void jump() {}

  _Shot get _shot {
    if (widget.cover) return _Shot.peace;
    if (widget.waving) {
      return widget.color == MascotColor.creator ? _Shot.extra : _Shot.jump;
    }
    return _shotFor(widget.mood);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final img = Image.asset(
      _asset(widget.color, _shot),
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
    if (widget.onTap == null) return ExcludeSemantics(child: img);
    return Semantics(
      button: true,
      label: 'Mascotte Eventa'.tr,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: img,
        ),
      ),
    );
  }
}

/// Mascotte immobile, entourée de confettis qui volent, pendant les temps
/// d'attente. Les messages défilent sous elle.
class MascotLoader extends StatefulWidget {
  const MascotLoader({
    super.key,
    this.size = 96,
    this.messages = const [],
    this.color = MascotColor.organizer,
  });

  /// Chargement standard, avec des messages de fête qui défilent.
  const MascotLoader.party({super.key, this.color = MascotColor.organizer})
    : size = 96,
      messages = _party;

  static const _party = [
    'On prépare la fête…',
    'On gonfle les ballons…',
    'On compte les FCFA…',
    'On range les confettis…',
  ];

  final double size;
  final List<String> messages;
  final MascotColor color;

  @override
  State<MascotLoader> createState() => _MascotLoaderState();
}

class _MascotLoaderState extends State<MascotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();
  int _msg = 0;

  static const _confetti = [
    Color(0xFFF0585D),
    Color(0xFF7C63FF),
    Color(0xFF16B4A1),
    Color(0xFFF2B530),
    Color(0xFFE863AD),
  ];

  @override
  void initState() {
    super.initState();
    _c.addListener(_cycle);
  }

  double _last = 0;
  int _beats = 0;

  void _cycle() {
    if (_c.value < _last) {
      _beats++;
      if (_beats % 2 == 0 && widget.messages.length > 1) {
        setState(() => _msg = (_msg + 1) % widget.messages.length);
      }
    }
    _last = _c.value;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.size;
    final w = h * 1.4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: w,
          height: h * 1.55,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final u = _c.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Confettis jonglés en arc au-dessus de la tête.
                  for (var i = 0; i < 3; i++) _piece(i, u, w, h),
                  // La mascotte reste immobile ; seuls les confettis volent.
                  Positioned(
                    left: (w - h) / 2,
                    bottom: 0,
                    child: Image.asset(
                      _asset(widget.color, _Shot.thumbs),
                      width: h,
                      height: h,
                      gaplessPlayback: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (widget.messages.isNotEmpty) ...[
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: Text(
              widget.messages[_msg % widget.messages.length].tr,
              key: ValueKey(_msg),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ],
    );
  }

  Widget _piece(int i, double u, double w, double h) {
    // Chaque confetti suit une parabole décalée d'un tiers de cycle.
    final p = (u + i / 3) % 1;
    final x = w / 2 + math.cos(p * math.pi) * w * 0.34;
    final y = h * 0.42 - math.sin(p * math.pi) * h * 0.38;
    return Positioned(
      left: x - 5,
      top: y,
      child: Transform.rotate(
        angle: p * math.pi * 3 + i,
        child: Container(
          width: 10,
          height: i == 1 ? 10 : 6,
          decoration: BoxDecoration(
            color: _confetti[i % _confetti.length],
            borderRadius: BorderRadius.circular(i == 1 ? 5 : 2),
          ),
        ),
      ),
    );
  }
}
